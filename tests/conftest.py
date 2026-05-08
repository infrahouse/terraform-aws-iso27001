import logging

import pytest
from infrahouse_core.logging import setup_logging

DEFAULT_PROGRESS_INTERVAL = 10
TERRAFORM_ROOT_DIR = "test_data"


LOG = logging.getLogger(__name__)


setup_logging(LOG, debug=True)


@pytest.fixture()
def ssm_client(boto3_session, aws_region):
    return boto3_session.client("ssm", region_name=aws_region)


@pytest.fixture()
def vanta_external_id(ssm_client):
    param_name = "/vanta/external_id"
    value = "test-external-id"
    ssm_client.put_parameter(
        Name=param_name,
        Value=value,
        Type="SecureString",
        Overwrite=True,
    )
    try:
        yield value
    finally:
        ssm_client.delete_parameter(Name=param_name)
