data aws_lambda_function "sportbuzz-users-statistics-python-lambda"{
  function_name = "sportbuzz-users-statistics-python-lambda"
}

resource "aws_api_gateway_rest_api" "sportbuzz-api-gateway" {
  name          = "sportbuzz-api-gateway"
  description   = "SportBUZZ API Gateway"
}

resource "aws_api_gateway_resource" "sportbuzz" {
  depends_on = [aws_api_gateway_rest_api.sportbuzz-api-gateway]

  rest_api_id = aws_api_gateway_rest_api.sportbuzz-api-gateway.id
  parent_id   = aws_api_gateway_rest_api.sportbuzz-api-gateway.root_resource_id
  path_part   = "sportbuzz"
}

resource "aws_api_gateway_resource" "users" {
  depends_on = [aws_api_gateway_rest_api.sportbuzz-api-gateway, aws_api_gateway_resource.sportbuzz]

  rest_api_id = aws_api_gateway_rest_api.sportbuzz-api-gateway.id
  parent_id   = aws_api_gateway_resource.sportbuzz.id
  path_part   = "users"
}

resource "aws_api_gateway_resource" "statistics" {
  depends_on = [aws_api_gateway_rest_api.sportbuzz-api-gateway, aws_api_gateway_resource.users]

  rest_api_id = aws_api_gateway_rest_api.sportbuzz-api-gateway.id
  parent_id   = aws_api_gateway_resource.users.id
  path_part   = "statistics"
}

resource "aws_api_gateway_method" "users-statistics" {
  depends_on = [aws_api_gateway_resource.statistics]

  rest_api_id           = aws_api_gateway_rest_api.sportbuzz-api-gateway.id
  resource_id           = aws_api_gateway_resource.statistics.id
  http_method           = "ANY"
  authorization         = "NONE"

  request_parameters = {
    "method.request.querystring.uid" = true
  }
}

resource "aws_api_gateway_integration" "users-statistics" {
  depends_on = [aws_api_gateway_method.users-statistics]

  rest_api_id             = aws_api_gateway_rest_api.sportbuzz-api-gateway.id
  resource_id             = aws_api_gateway_resource.statistics.id
  http_method             = aws_api_gateway_method.users-statistics.http_method
  uri                     = data.aws_lambda_function.sportbuzz-users-statistics-python-lambda.invoke_arn
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
}


resource "aws_lambda_permission" "sportbuzz-users-statistics-api-gateway-lambda-permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.sportbuzz-users-statistics-python-lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.sportbuzz-api-gateway.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "sportbuzz-api-gateway" {
  rest_api_id = aws_api_gateway_rest_api.sportbuzz-api-gateway.id
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.sportbuzz-api-gateway.body))
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [aws_api_gateway_method.users-statistics, aws_api_gateway_integration.users-statistics]
}
resource "aws_api_gateway_stage" "sportbuzz-api-gateway" {
  deployment_id = aws_api_gateway_deployment.sportbuzz-api-gateway.id
  rest_api_id   = aws_api_gateway_rest_api.sportbuzz-api-gateway.id
  stage_name    = "dev"
}
