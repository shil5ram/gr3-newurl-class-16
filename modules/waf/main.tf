resource "aws_wafv2_ip_set" "allowed_ips" {
  name               = "${var.group_number}-allowed-ips"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = [var.my_ip_cidr]
}

resource "aws_wafv2_web_acl" "api_gw_waf" {
  name        = "${var.group_number}-api-waf"
  scope       = "REGIONAL"
  default_action {
    block {}
  }

  rule {
    name     = "AllowMyIP"
    priority = 1
    action {
      allow {}
    }
    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allowed_ips.arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowMyIPMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "GlobalWafMetric"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-${var.group_number}-api"
  retention_in_days = 14
}

resource "aws_wafv2_web_acl_logging_configuration" "waf_log_config" {
  resource_arn            = aws_wafv2_web_acl.api_gw_waf.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]

  logging_filter {
    default_behavior = "DROP"
    filter {
      behavior    = "KEEP"
      requirement = "MEETS_ANY"
      condition {
        action_condition {
          action = "BLOCK"
        }
      }
    }
  }
}
