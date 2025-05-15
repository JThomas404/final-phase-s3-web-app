data "aws_iam_policy_document" "ctdc-assume-role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ctdc-iam-for-lambda" {
  name               = "ctdc-iam-for-lambda"
  assume_role_policy = data.aws_iam_policy_document.ctdc-assume-role.json

  tags = {
    Name = var.project_tag
  }
}

data "archive_file" "ctdc-lambda" {
  type        = "zip"
  source_file = "${path.module}/../backend/app.py"
  output_path = "${path.module}/build/lambda_function_payload.zip"
}

resource "aws_lambda_function" "ctdc-lambda" {
  function_name    = "ctdc-lambda"
  role             = aws_iam_role.ctdc-iam-for-lambda.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.ctdc-lambda.output_path
  source_code_hash = data.archive_file.ctdc-lambda.output_base64sha256

  tags = {
    Name = var.project_tag
  }
}

resource "aws_iam_role_policy_attachment" "ctdc-lambda-basic-execution" {
  role       = aws_iam_role.ctdc-iam-for-lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "ctdc-lambda-admin-access" {
  role       = aws_iam_role.ctdc-iam-for-lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_lambda_permission" "ctdc-api-gateway-permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ctdc-lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.ctdc-api.execution_arn}/*/*"
}

resource "aws_iam_role_policy_attachment" "ctdc-lambda-dynamodb-access" {
  role       = aws_iam_role.ctdc-iam-for-lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}
