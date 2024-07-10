resource "aws_api_gateway_rest_api" "csv_api" {
  name = "CSV API"
}

resource "aws_api_gateway_resource" "csv_resource" {
  rest_api_id = aws_api_gateway_rest_api.csv_api.id
  parent_id   = aws_api_gateway_rest_api.csv_api.root_resource_id
  path_part   = "csv"
}

resource "aws_api_gateway_method" "csv_method" {
  rest_api_id   = aws_api_gateway_rest_api.csv_api.id
  resource_id   = aws_api_gateway_resource.csv_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.csv_api.id
  resource_id             = aws_api_gateway_resource.csv_resource.id
  http_method             = aws_api_gateway_method.csv_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.csv_ingest.invoke_arn
}

resource "aws_api_gateway_deployment" "lambda_deployment" {
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.csv_api.id
  stage_name  = "prod"
}

resource "aws_api_gateway_stage" "lambda_stage_dev" {
  rest_api_id   = aws_api_gateway_rest_api.csv_api.id
  deployment_id = aws_api_gateway_deployment.lambda_deployment.id
  stage_name    = "dev"
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.csv_ingest.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.csv_api.execution_arn}/*/*"
}