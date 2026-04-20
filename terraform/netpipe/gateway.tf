resource "aws_apigatewayv2_api" "gateway_http_api" {
  name          = "netpipe-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_authorizer" "gateway_authorizer" {
  api_id                            = aws_apigatewayv2_api.gateway_http_api.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = module.lambda_authorizer.lambda_data.invoke_arn
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "lambda-authorizer"
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.gateway_http_api.id
  name        = "netpipe"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda_auth_integration" {
  api_id                 = aws_apigatewayv2_api.gateway_http_api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "ANY"
  integration_uri        = module.lambda_core.lambda_data.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "protected" {
  api_id             = aws_apigatewayv2_api.gateway_http_api.id
  route_key          = "$default"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.gateway_authorizer.id
  target             = "integrations/${aws_apigatewayv2_integration.lambda_auth_integration.id}"
}
