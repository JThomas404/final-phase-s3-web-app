resource "aws_api_gateway_rest_api" "ctdc-api" {
  name        = "ctdc-api"
  description = "API Gateway for Connecting The Dots Lambda"

  tags = {
    Name = var.project_tag
  }
}

resource "aws_api_gateway_resource" "ctdc-contact-resource" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  parent_id   = aws_api_gateway_rest_api.ctdc-api.root_resource_id
  path_part   = "contact"
}

resource "aws_api_gateway_method" "ctdc-post-method" {
  rest_api_id   = aws_api_gateway_rest_api.ctdc-api.id
  resource_id   = aws_api_gateway_resource.ctdc-contact-resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "ctdc-options-method" {
  rest_api_id   = aws_api_gateway_rest_api.ctdc-api.id
  resource_id   = aws_api_gateway_resource.ctdc-contact-resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "ctdc-lambda-integration" {
  rest_api_id             = aws_api_gateway_rest_api.ctdc-api.id
  resource_id             = aws_api_gateway_resource.ctdc-contact-resource.id
  http_method             = aws_api_gateway_method.ctdc-post-method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.ctdc-lambda.invoke_arn
}

resource "aws_api_gateway_integration" "ctdc-options-integration" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  resource_id = aws_api_gateway_resource.ctdc-contact-resource.id
  http_method = aws_api_gateway_method.ctdc-options-method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "ctdc-options-response" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  resource_id = aws_api_gateway_resource.ctdc-contact-resource.id
  http_method = aws_api_gateway_method.ctdc-options-method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "ctdc-options-integration-response" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  resource_id = aws_api_gateway_resource.ctdc-contact-resource.id
  http_method = aws_api_gateway_method.ctdc-options-method.http_method
  status_code = aws_api_gateway_method_response.ctdc-options-response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_method_response" "ctdc-post-response" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  resource_id = aws_api_gateway_resource.ctdc-contact-resource.id
  http_method = aws_api_gateway_method.ctdc-post-method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "ctdc-integration-response" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  resource_id = aws_api_gateway_resource.ctdc-contact-resource.id
  http_method = aws_api_gateway_method.ctdc-post-method.http_method
  status_code = aws_api_gateway_method_response.ctdc-post-response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.ctdc-lambda-integration]
}

resource "aws_api_gateway_deployment" "ctdc-api-deployment" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id

  lifecycle {
    create_before_destroy = true
  }

  triggers = {
    redeploy = timestamp()
  }

  depends_on = [
    aws_api_gateway_integration.ctdc-lambda-integration,
    aws_api_gateway_method_response.ctdc-post-response,
    aws_api_gateway_integration_response.ctdc-integration-response,
    aws_api_gateway_method.ctdc-options-method,
    aws_api_gateway_integration_response.ctdc-options-integration-response
  ]
}

resource "aws_api_gateway_stage" "ctdc-api-stage" {
  rest_api_id   = aws_api_gateway_rest_api.ctdc-api.id
  deployment_id = aws_api_gateway_deployment.ctdc-api-deployment.id
  stage_name    = "prod"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId",
      ip             = "$context.identity.sourceIp",
      caller         = "$context.identity.caller",
      user           = "$context.identity.user",
      requestTime    = "$context.requestTime",
      httpMethod     = "$context.httpMethod",
      resourcePath   = "$context.resourcePath",
      status         = "$context.status",
      protocol       = "$context.protocol",
      responseLength = "$context.responseLength"
    })
  }

  xray_tracing_enabled = true

  tags = {
    Name = var.project_tag
  }
}

resource "aws_lambda_permission" "ctdc-api-gateway-permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ctdc-lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.ctdc-api.execution_arn}/*/*"
}

resource "aws_iam_role" "apigw_cloudwatch_role" {
  name = "APIGatewayCloudWatchLogsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apigw_cloudwatch_role_attach" {
  role       = aws_iam_role.apigw_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_cloudwatch_log_group" "api_gw_logs" {
  name              = "/aws/api-gateway/ctdc-api"
  retention_in_days = 14
}

resource "aws_api_gateway_account" "ctdc-account" {
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch_role.arn
}

resource "aws_api_gateway_resource" "ctdc-userdata-resource" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  parent_id   = aws_api_gateway_rest_api.ctdc-api.root_resource_id
  path_part   = "userdata"
}

resource "aws_api_gateway_method" "ctdc-userdata-get-method" {
  rest_api_id   = aws_api_gateway_rest_api.ctdc-api.id
  resource_id   = aws_api_gateway_resource.ctdc-userdata-resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "ctdc-userdata-integration" {
  rest_api_id             = aws_api_gateway_rest_api.ctdc-api.id
  resource_id             = aws_api_gateway_resource.ctdc-userdata-resource.id
  http_method             = aws_api_gateway_method.ctdc-userdata-get-method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.ctdc-lambda.invoke_arn
}

resource "aws_api_gateway_method_response" "ctdc-userdata-get-response" {
  rest_api_id = aws_api_gateway_rest_api.ctdc-api.id
  resource_id = aws_api_gateway_resource.ctdc-userdata-resource.id
  http_method = aws_api_gateway_method.ctdc-userdata-get-method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}
