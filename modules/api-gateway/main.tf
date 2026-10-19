data "aws_route53_zone" "sandbox" {
  name         = "sctp-sandbox.com"
  private_zone = false
}

data "aws_acm_certificate" "cert" {
  domain   = "*.sctp-sandbox.com"
  statuses = ["ISSUED"]
}

resource "aws_api_gateway_rest_api" "api" { name = "${var.group_number}-api" }

# POST /newurl
resource "aws_api_gateway_resource" "newurl" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "newurl"
}
resource "aws_api_gateway_method" "post" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.newurl.id
  http_method = "POST"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "post_int" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.newurl.id
  http_method = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.create_invoke_arn
}

# GET /{short_id}
resource "aws_api_gateway_resource" "geturl" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{short_id}"
}
resource "aws_api_gateway_method" "get" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.geturl.id
  http_method = "GET"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "get_int" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.geturl.id
  http_method = "GET"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.retrieve_invoke_arn
}

resource "aws_api_gateway_deployment" "deploy" {
  depends_on  = [aws_api_gateway_integration.post_int, aws_api_gateway_integration.get_int]
  rest_api_id = aws_api_gateway_rest_api.api.id
  lifecycle   { create_before_destroy = true }
}

resource "aws_cloudwatch_log_group" "apigw_log" { 
  name              = "api-gateway/${aws_api_gateway_rest_api.api.name}-execution"
  retention_in_days = 7
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id      = aws_api_gateway_deployment.deploy.id
  rest_api_id        = aws_api_gateway_rest_api.api.id
  stage_name         = "prod"
  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_log.arn
    format          = "{ \"requestId\":\"$context.requestId\", \"ip\":\"$context.identity.sourceIp\", \"status\":\"$context.status\" }"
  }
}

resource "aws_wafv2_web_acl_association" "waf_assoc" {
  resource_arn = aws_api_gateway_stage.prod.arn
  web_acl_arn  = var.web_acl_arn
}

resource "aws_lambda_permission" "apigw_create" {
  action = "lambda:InvokeFunction"
  function_name = var.create_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_retrieve" {
  action = "lambda:InvokeFunction"
  function_name = var.retrieve_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_api_gateway_domain_name" "custom" {
  domain_name              = var.domain_name
  regional_certificate_arn = data.aws_acm_certificate.cert.arn
  endpoint_configuration   { types = ["REGIONAL"] }
}

resource "aws_api_gateway_base_path_mapping" "map" {
  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  domain_name = aws_api_gateway_domain_name.custom.domain_name
}

resource "aws_route53_record" "dns" {
  zone_id = data.aws_route53_zone.sandbox.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_api_gateway_domain_name.custom.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.custom.regional_zone_id
    evaluate_target_health = true
  }
}
