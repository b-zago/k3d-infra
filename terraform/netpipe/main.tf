data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_assume_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_assume_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda/lambda_function.zip"
}

resource "aws_lambda_function" "lambda_authorizer" {
  filename      = data.archive_file.lambda_function.output_path
  function_name = "lambda_authorizer"
  role          = aws_iam_role.iam_assume_role.arn
  handler       = "lambda_function.lambda_handler"
  code_sha256   = data.archive_file.lambda_function.output_base64sha256

  runtime = "python3.14"
}

resource "aws_apigatewayv2_api" "gateway_http_api" {
  name          = "netpipe-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_authorizer" "lambda_authorizer" {
  api_id                            = aws_apigatewayv2_api.gateway_http_api.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.lambda_authorizer.invoke_arn
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "lambda-authorizer"
  authorizer_payload_format_version = "2.0"
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_authorizer.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.gateway_http_api.execution_arn}/*"
}

resource "aws_apigatewayv2_stage" "example" {
  api_id      = aws_apigatewayv2_api.gateway_http_api.id
  name        = "netpipe-stage"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.gateway_http_api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "ANY"
  integration_uri        = aws_lambda_function.lambda_authorizer.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "protected" {
  api_id             = aws_apigatewayv2_api.gateway_http_api.id
  route_key          = "$default"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}


output "api_endpoint" {
  value = "http://${aws_apigatewayv2_api.gateway_http_api.id}.execute-api.localhost.localstack.cloud:4566/${aws_apigatewayv2_stage.example.name}/test"
}
