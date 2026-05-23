# CloudWatch Dashboard for Vanta CAP-7 (ISO 27001:2022 A.8.6 — Capacity management)
#
# "The use of resources shall be monitored and adjusted in line with current
# and expected capacity requirements."
#
# This dashboard provides a single-pane view of capacity metrics across all
# monitored resource types in the account.  It uses CloudWatch SEARCH()
# expressions so that newly created resources appear automatically.
#
# The widget layout mirrors the 11 Vanta automated tests under CAP-7:
#   - Server CPU monitored                       → EC2/ASG CPU + headroom
#   - LB unhealthy host count / latency / 5xx    → ALB section
#   - SQL DB CPU / memory / storage / IO          → RDS section
#   - Serverless function error rate              → Lambda section
#   - Messaging queue message age                 → SQS section

resource "aws_cloudwatch_dashboard" "capacity" {
  for_each = var.capacity_dashboard_enabled ? toset(var.regions) : toset([])

  dashboard_name = "${var.capacity_dashboard_name_prefix}-${each.key}"
  region         = each.key

  dashboard_body = jsonencode({
    widgets = [

      # ── Header ────────────────────────────────────────────────
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = join("", [
            "# Capacity Monitoring — ${each.key}\n",
            "ISO 27001:2022 A.8.6 · Vanta CAP-7 · Auto-discovered resources\n\n",
            "All graphs use CloudWatch `SEARCH()` — newly created resources ",
            "appear automatically without configuration changes.",
          ])
        }
      },

      # ── EC2 / ASG ────────────────────────────────────────────
      {
        type   = "text"
        x      = 0
        y      = 2
        width  = 24
        height = 3
        properties = {
          markdown = join("", [
            "## EC2 / Auto Scaling Groups\n",
            "**CPU Utilization** — average CPU across all instances in each ASG. ",
            "Sustained high CPU (>80%) means the workload is approaching the ",
            "compute ceiling; the ASG should scale out or instance types need ",
            "upgrading.\n\n",
            "**In-Service vs Desired** — how many instances are running compared ",
            "to how many the ASG wants. When desired exceeds in-service, the ",
            "ASG is actively scaling out. A persistent gap means instances are ",
            "failing to launch (check launch template, capacity, or health ",
            "checks).",
          ])
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 5
        width  = 12
        height = 6
        properties = {
          title   = "ASG — CPU Utilization (%)"
          region  = each.key
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            [
              {
                expression = "SEARCH('{AWS/EC2,AutoScalingGroupName} MetricName=\"CPUUtilization\"', 'Average', 300)"
                id         = "cpu"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 5
        width  = 12
        height = 6
        properties = {
          title   = "ASG — In-Service vs Desired"
          region  = each.key
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            [
              {
                expression = "SEARCH('{AWS/AutoScaling,AutoScalingGroupName} MetricName=\"GroupInServiceInstances\"', 'Average', 300)"
                id         = "inservice"
              }
            ],
            [
              {
                expression = "SEARCH('{AWS/AutoScaling,AutoScalingGroupName} MetricName=\"GroupDesiredCapacity\"', 'Average', 300)"
                id         = "desired"
              }
            ]
          ]
        }
      },

      # ── ALB ───────────────────────────────────────────────────
      {
        type   = "text"
        x      = 0
        y      = 11
        width  = 24
        height = 3
        properties = {
          markdown = join("", [
            "## Application Load Balancers\n",
            "**Unhealthy Host Count** — targets that failed health checks. ",
            "Any non-zero value means traffic is being routed away from failing ",
            "instances; investigate the target group health check logs.\n\n",
            "**Target Response Time** — average time for the backend to respond. ",
            "Rising latency with stable traffic usually indicates resource ",
            "saturation (CPU, memory, or database).\n\n",
            "**Requests per Second** — request rate (QPS) for each load balancer. ",
            "Correlate with latency and unhealthy hosts to distinguish ",
            "load-driven saturation from failures.",
          ])
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 14
        width  = 8
        height = 6
        properties = {
          title   = "ALB — Unhealthy Host Count"
          region  = each.key
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            [
              {
                expression = "SEARCH('{AWS/ApplicationELB,TargetGroup,LoadBalancer} MetricName=\"UnHealthyHostCount\"', 'Average', 300)"
                id         = "unhealthy"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 14
        width  = 8
        height = 6
        properties = {
          title   = "ALB — Target Response Time (s)"
          region  = each.key
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            [
              {
                expression = "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"TargetResponseTime\"', 'Average', 300)"
                id         = "latency"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 14
        width  = 8
        height = 6
        properties = {
          title   = "ALB — Requests per Second"
          region  = each.key
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            [
              {
                expression = "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"RequestCount\"', 'Sum', 300)"
                id         = "requests"
                visible    = false
              }
            ],
            [
              {
                expression = "requests / 300"
                id         = "qps"
              }
            ]
          ]
        }
      },

      # ── RDS ───────────────────────────────────────────────────
      {
        type   = "text"
        x      = 0
        y      = 20
        width  = 24
        height = 4
        properties = {
          markdown = join("", [
            "## RDS Databases\n",
            "**QPS (IOPS)** — combined read + write I/O operations per second. ",
            "Hitting the provisioned IOPS ceiling causes queuing; correlate ",
            "with CPU and latency to confirm an I/O bottleneck.\n\n",
            "**CPU Utilization** — sustained >80% means the instance class is ",
            "undersized for the query load. Consider read replicas or upgrading ",
            "the instance type.\n\n",
            "**Freeable Memory** — RAM available to the database engine after OS ",
            "and buffer pool usage. Dropping toward zero triggers swap and ",
            "severe latency. Trend this over days, not minutes.\n\n",
            "**Free Storage Space** — disk space remaining on the EBS volume. ",
            "RDS instances stop accepting writes when storage is full. Enable ",
            "storage autoscaling or provision ahead of the trend.\n\n",
            "**Disk IOPS** — read and write I/O operations per second on the ",
            "underlying EBS volume. Hitting the provisioned IOPS ceiling causes ",
            "queuing; correlate with CPU and latency to confirm an I/O ",
            "bottleneck.\n\n",
            "**Network Throughput** — bytes received and transmitted per second. ",
            "Useful for spotting replication traffic, large result sets, or ",
            "data transfer bottlenecks.",
          ])
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 24
        width  = 12
        height = 6
        properties = {
          title   = "RDS — QPS (Read + Write IOPS)"
          region  = each.key
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            [
              {
                expression = "SEARCH('{AWS/RDS,DBInstanceIdentifier} MetricName=\"ReadIOPS\"', 'Average', 300)"
                id         = "rds_riops"
              }
            ],
            [
              {
                expression = "SEARCH('{AWS/RDS,DBInstanceIdentifier} MetricName=\"WriteIOPS\"', 'Average', 300)"
                id         = "rds_wiops"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 30
        width  = 12
        height = 6
        properties = {
          title   = "RDS — CPU Utilization (%)"
          region  = each.key
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            [
              {
                expression = "SEARCH('{AWS/RDS,DBInstanceIdentifier} MetricName=\"CPUUtilization\"', 'Average', 300)"
                id         = "rds_cpu"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 30
        width  = 12
        height = 6
        properties = {
          title   = "RDS — Freeable Memory (bytes)"
          region  = each.key
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            [
              {
                expression = "SEARCH('{AWS/RDS,DBInstanceIdentifier} MetricName=\"FreeableMemory\"', 'Average', 300)"
                id         = "rds_mem"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 24
        width  = 12
        height = 6
        properties = {
          title   = "RDS — Free Storage Space (bytes)"
          region  = each.key
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            [
              {
                expression = "SEARCH('{AWS/RDS,DBInstanceIdentifier} MetricName=\"FreeStorageSpace\"', 'Average', 300)"
                id         = "rds_disk"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 36
        width  = 12
        height = 6
        properties = {
          title   = "RDS — Disk IOPS"
          region  = each.key
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            [
              {
                expression = "SEARCH('{AWS/RDS,DBInstanceIdentifier} MetricName=\"ReadIOPS\"', 'Average', 300)"
                id         = "rds_disk_riops"
              }
            ],
            [
              {
                expression = "SEARCH('{AWS/RDS,DBInstanceIdentifier} MetricName=\"WriteIOPS\"', 'Average', 300)"
                id         = "rds_disk_wiops"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 36
        width  = 12
        height = 6
        properties = {
          title   = "RDS — Network Throughput (bytes/s)"
          region  = each.key
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            [
              {
                expression = "SEARCH('{AWS/RDS,DBInstanceIdentifier} MetricName=\"NetworkReceiveThroughput\"', 'Average', 300)"
                id         = "rds_net_rx"
              }
            ],
            [
              {
                expression = "SEARCH('{AWS/RDS,DBInstanceIdentifier} MetricName=\"NetworkTransmitThroughput\"', 'Average', 300)"
                id         = "rds_net_tx"
              }
            ]
          ]
        }
      },

      # ── Lambda ────────────────────────────────────────────────
      {
        type   = "text"
        x      = 0
        y      = 48
        width  = 24
        height = 3
        properties = {
          markdown = join("", [
            "## Lambda Functions\n",
            "**Error Count** — total failed invocations across all functions. ",
            "Spikes often follow deployments or dependency outages. Drill into ",
            "individual functions via the Lambda console.\n\n",
            "**Concurrent Executions** — how many function instances are running ",
            "simultaneously. Approaching the account/function concurrency limit ",
            "causes throttling — watch for flat-tops on this graph.",
          ])
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 51
        width  = 12
        height = 6
        properties = {
          title   = "Lambda — Error Count"
          region  = each.key
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            [
              {
                expression = "SEARCH('{AWS/Lambda,FunctionName} MetricName=\"Errors\"', 'Sum', 300)"
                id         = "lambda_err"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 51
        width  = 12
        height = 6
        properties = {
          title   = "Lambda — Concurrent Executions"
          region  = each.key
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            [
              {
                expression = "SEARCH('{AWS/Lambda,FunctionName} MetricName=\"ConcurrentExecutions\"', 'Average', 300)"
                id         = "lambda_conc"
              }
            ]
          ]
        }
      },

      # ── SQS ──────────────────────────────────────────────────
      {
        type   = "text"
        x      = 0
        y      = 57
        width  = 24
        height = 3
        properties = {
          markdown = join("", [
            "## SQS Queues\n",
            "**Oldest Message Age** — how long the oldest visible message has ",
            "been waiting for a consumer. Growing age means consumers cannot ",
            "keep up with the production rate; scale out workers or investigate ",
            "processing failures.\n\n",
            "**Messages Visible** — number of messages waiting to be picked up. ",
            "A sustained rise is a backlog building up. Compare with Oldest ",
            "Message Age to distinguish a traffic spike from stuck consumers.",
          ])
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 60
        width  = 12
        height = 6
        properties = {
          title   = "SQS — Oldest Message Age (s)"
          region  = each.key
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            [
              {
                expression = "SEARCH('{AWS/SQS,QueueName} MetricName=\"ApproximateAgeOfOldestMessage\"', 'Maximum', 300)"
                id         = "sqs_age"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 60
        width  = 12
        height = 6
        properties = {
          title   = "SQS — Messages Visible"
          region  = each.key
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            [
              {
                expression = "SEARCH('{AWS/SQS,QueueName} MetricName=\"ApproximateNumberOfMessagesVisible\"', 'Average', 300)"
                id         = "sqs_visible"
              }
            ]
          ]
        }
      },
    ]
  })
}
