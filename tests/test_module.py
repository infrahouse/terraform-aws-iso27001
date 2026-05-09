import json
from os import path as osp, remove
from shutil import rmtree
from textwrap import dedent

import pytest
from pytest_infrahouse import terraform_apply

from tests.conftest import (
    LOG,
    TERRAFORM_ROOT_DIR,
)

GOVERNANCE_LOGS_ACTIONS = {
    "logs:DescribeLogGroups",
    "logs:ListTagsForResource",
    "logs:PutRetentionPolicy",
    "logs:TagResource",
    "logs:UntagResource",
}
GOVERNANCE_LAMBDA_ACTIONS = {
    "lambda:ListFunctions",
    "lambda:ListTags",
    "lambda:TagResource",
}
GOVERNANCE_S3_ACTIONS = {
    "s3:GetBucketTagging",
    "s3:ListAllMyBuckets",
}


@pytest.mark.parametrize("aws_provider_version", ["~> 6.0"], ids=["aws-6"])
def test_module(
    test_role_arn,
    keep_after,
    aws_region,
    aws_provider_version,
    iam_client,
    vanta_external_id,
):
    terraform_module_dir = osp.join(TERRAFORM_ROOT_DIR, "iso27001")
    state_files = [
        osp.join(terraform_module_dir, ".terraform"),
        osp.join(terraform_module_dir, ".terraform.lock.hcl"),
    ]

    for state_file in state_files:
        try:
            if osp.isdir(state_file):
                rmtree(state_file)
            elif osp.isfile(state_file):
                remove(state_file)
        except FileNotFoundError:
            pass

    with open(osp.join(terraform_module_dir, "terraform.tfvars"), "w") as fp:
        fp.write(dedent(f"""
                    region              = "{aws_region}"
                    regions             = ["{aws_region}"]
                    """))
        if test_role_arn:
            fp.write(dedent(f"""
                    role_arn        = "{test_role_arn}"
                    """))

    with open(osp.join(terraform_module_dir, "terraform.tf"), "w") as fp:
        fp.write(dedent(f"""
                terraform {{
                  required_version = "~> 1.5"
                  //noinspection HILUnresolvedReference
                  required_providers {{
                    aws = {{
                      source  = "hashicorp/aws"
                      version = "{aws_provider_version}"
                    }}
                  }}
                }}
                """))

    with terraform_apply(
        terraform_module_dir,
        destroy_after=not keep_after,
        json_output=True,
    ) as tf_output:
        LOG.info("%s", json.dumps(tf_output, indent=4))

        governance_role_name = tf_output["governance_role_name"]["value"]
        log_retention_role_name = tf_output["log_retention_role_name"]["value"]
        vanta_role_name = tf_output["vanta_auditor_role_name"]["value"]
        assert governance_role_name == "InfraHouseGovernance"
        assert log_retention_role_name == "InfraHouseLogRetention"
        assert vanta_role_name == "vanta-auditor"

        _assert_role_trusts_master_account(iam_client, governance_role_name)
        _assert_role_trusts_master_account(iam_client, log_retention_role_name)

        governance_actions = _collect_inline_policy_actions(
            iam_client, governance_role_name, governance_role_name
        )
        assert GOVERNANCE_LOGS_ACTIONS.issubset(governance_actions)
        assert GOVERNANCE_LAMBDA_ACTIONS.issubset(governance_actions)
        assert GOVERNANCE_S3_ACTIONS.issubset(governance_actions)

        log_retention_actions = _collect_inline_policy_actions(
            iam_client, log_retention_role_name, log_retention_role_name
        )
        assert GOVERNANCE_LOGS_ACTIONS.issubset(log_retention_actions)
        assert log_retention_actions.isdisjoint(GOVERNANCE_LAMBDA_ACTIONS)


def _assert_role_trusts_master_account(iam_client, role_name):
    role = iam_client.get_role(RoleName=role_name)["Role"]
    statements = role["AssumeRolePolicyDocument"]["Statement"]
    principals = []
    for statement in statements:
        if statement.get("Effect", "Allow") != "Allow":
            continue
        if "sts:AssumeRole" not in _as_list(statement.get("Action", [])):
            continue
        principals.extend(_as_list(statement.get("Principal", {}).get("AWS", [])))
    assert any(
        p.endswith(":root") for p in principals
    ), f"{role_name} trust policy does not allow an account root principal: {principals}"


def _collect_inline_policy_actions(iam_client, role_name, policy_name):
    policy = iam_client.get_role_policy(RoleName=role_name, PolicyName=policy_name)
    actions = set()
    for statement in policy["PolicyDocument"]["Statement"]:
        if statement.get("Effect", "Allow") != "Allow":
            continue
        actions.update(_as_list(statement.get("Action", [])))
    return actions


def _as_list(value):
    if isinstance(value, list):
        return value
    return [value]
