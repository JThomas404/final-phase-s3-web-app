resource "aws_api_gateway_rest_api" "ctdc-api" {
  name        = "ctdc-api"
  description = "API Gateway for Connecting The Dots Lambda"
  endpoint_configuration {
    types = ["EDGE"]
  }

  tags = {
    Name = "connecting-the-dots"
  }
}

resource "aws_api_gateway_resource" "ctdc-contact-resource" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  parent_id   = aws_api_gateway_rest_api.ctdc-api.root_resource_id
  path_part   = "contact"
}

resource "aws_api_gateway_resource" "ctdc-userdata-resource" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  parent_id   = aws_api_gateway_rest_api.ctdc-api.root_resource_id
  path_part   = "userdata"
}

# /contact POST Method
resource "aws_api_gateway_method" "ctdc-contact-post" {
  rest_api_id   = aws_api_gateway_rest_api.ctdc-api.id
  resource_id   = aws_api_gateway_resource.ctdc-contact-resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# /contact OPTIONS Method (CORS Preflight)
resource "aws_api_gateway_method" "ctdc-contact-options" {
  rest_api_id   = aws_api_gateway_rest_api.ctdc-api.id
  resource_id   = aws_api_gateway_resource.ctdc-contact-resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# /userdata GET Method
resource "aws_api_gateway_method" "ctdc-userdata-get" {
  rest_api_id   = aws_api_gateway_rest_api.ctdc-api.id
  resource_id   = aws_api_gateway_resource.ctdc-userdata-resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# /userdata OPTIONS Method (CORS Preflight)
resource "aws_api_gateway_method" "ctdc-userdata-options" {
  rest_api_id   = aws_api_gateway_rest_api.ctdc-api.id
  resource_id   = aws_api_gateway_resource.ctdc-userdata-resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Lambda Integrations
resource "aws_api_gateway_integration" "ctdc-contact-post-integration" {
  rest_api_id             = aws_api_gateway_rest_api.ctdc-api.id
  resource_id             = aws_api_gateway_resource.ctdc-contact-resource.id
  http_method             = aws_api_gateway_method.ctdc-contact-post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.ctdc-lambda.invoke_arn
}

resource "aws_api_gateway_integration" "ctdc-userdata-get-integration" {
  rest_api_id             = aws_api_gateway_rest_api.ctdc-api.id
  resource_id             = aws_api_gateway_resource.ctdc-userdata-resource.id
  http_method             = aws_api_gateway_method.ctdc-userdata-get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.ctdc-lambda.invoke_arn
}

# OPTIONS Integrations (CORS Preflight MOCKs)
resource "aws_api_gateway_integration" "ctdc-contact-options-integration" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  resource_id = aws_api_gateway_resource.ctdc-contact-resource.id
  http_method = aws_api_gateway_method.ctdc-contact-options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration" "ctdc-userdata-options-integration" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  resource_id = aws_api_gateway_resource.ctdc-userdata-resource.id
  http_method = aws_api_gateway_method.ctdc-userdata-options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Method Responses for CORS
resource "aws_api_gateway_method_response" "ctdc-contact-options-response" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  resource_id = aws_api_gateway_resource.ctdc-contact-resource.id
  http_method = aws_api_gateway_method.ctdc-contact-options.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_method_response" "ctdc-userdata-options-response" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  resource_id = aws_api_gateway_resource.ctdc-userdata-resource.id
  http_method = aws_api_gateway_method.ctdc-userdata-options.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

# POST /contact response for Lambda Proxy
resource "aws_api_gateway_method_response" "ctdc-contact-post-response" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  resource_id = aws_api_gateway_resource.ctdc-contact-resource.id
  http_method = aws_api_gateway_method.ctdc-contact-post.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

# GET /userdata response for Lambda Proxy
resource "aws_api_gateway_method_response" "ctdc-userdata-get-response" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  resource_id = aws_api_gateway_resource.ctdc-userdata-resource.id
  http_method = aws_api_gateway_method.ctdc-userdata-get.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# Integration Responses for OPTIONS (CORS headers)
resource "aws_api_gateway_integration_response" "ctdc-contact-options-integration-response" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  resource_id = aws_api_gateway_resource.ctdc-contact-resource.id
  http_method = aws_api_gateway_method.ctdc-contact-options.http_method
  status_code = aws_api_gateway_method_response.ctdc-contact-options-response.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
  }
}

resource "aws_api_gateway_integration_response" "ctdc-userdata-options-integration-response" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  resource_id = aws_api_gateway_resource.ctdc-userdata-resource.id
  http_method = aws_api_gateway_method.ctdc-userdata-options.http_method
  status_code = aws_api_gateway_method_response.ctdc-userdata-options-response.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
  }
}

# Integration Response for POST /contact
resource "aws_api_gateway_integration_response" "ctdc-contact-post-integration-response" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  resource_id = aws_api_gateway_resource.ctdc-contact-resource.id
  http_method = aws_api_gateway_method.ctdc-contact-post.http_method
  status_code = aws_api_gateway_method_response.ctdc-contact-post-response.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
  }
}

# Deployment & Stage
resource "aws_api_gateway_deployment" "ctdc-api-deployment" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  triggers = {
    redeploy = timestamp()
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "api_gw_logs" {
  name              = "/aws/api-gateway/ctdc-api"
  retention_in_days = 14
}

resource "aws_api_gateway_stage" "ctdc-api-stage" {
  rest_api_id    = aws_api_gateway_rest_api.ctdc-api.id
  stage_name     = "prod"
  deployment_id  = aws_api_gateway_deployment.ctdc-api-deployment.id
  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_logs.arn
    format = jsonencode({
      requestId  = "$context.requestId"
      status     = "$context.status"
      protocol   = "$context.protocol"
      ip         = "$context.identity.sourceIp"
      user       = "$context.identity.user"
      requestTime = "$context.requestTime"
      resourcePath = "$context.resourcePath"
    })
  }

  tags = {
    Name = "connecting-the-dots"
  }
}