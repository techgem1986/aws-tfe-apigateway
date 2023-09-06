data aws_lambda_function "sportbuzz-users-statistics-python-lambda"{
  function_name = "sportbuzz-users-statistics-python-lambda"
}

resource "aws_apigatewayv2_api" "sportbuzz-api-gateway" {
  name          = "sportbuzz-api-gateway"
  protocol_type = "HTTP"
}

resource "aws_cloudwatch_log_group" "sportbuzz-api-gateway-log" {
  name = "/aws/api-gateway/${aws_apigatewayv2_api.sportbuzz-api-gateway.name}"
  retention_in_days = 30
}

resource "aws_apigatewayv2_stage" "sportbuzz-api-gateway_stage" {
  api_id = aws_apigatewayv2_api.sportbuzz-api-gateway.id
  name        = "sportbuzz"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.sportbuzz-api-gateway-log.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    }
    )
  }
}

resource "aws_apigatewayv2_integration" "sportbuzz-users-statistics-api-gateway-integration" {
  api_id = aws_apigatewayv2_api.sportbuzz-api-gateway.id

  integration_uri    = data.aws_lambda_function.sportbuzz-users-statistics-python-lambda.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "sportbuzz-users-statistics-api-gateway-route" {
  api_id = aws_apigatewayv2_api.sportbuzz-api-gateway.id
  route_key = "GET /getUser"
  target    = "integrations/${aws_apigatewayv2_integration.sportbuzz-users-statistics-api-gateway-integration.id}"
}

resource "aws_lambda_permission" "sportbuzz-users-statistics-api-gateway-lambda-permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.sportbuzz-users-statistics-python-lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.sportbuzz-api-gateway.execution_arn}/*/*"
}
