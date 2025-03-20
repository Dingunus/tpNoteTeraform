
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

//région aws
provider "aws" {
  region = "eu-west-3"
}

//ajout et création du role
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

//configuration de lambda
resource "aws_iam_role" "iam_for_lambda" {
  name               = "g4-a5-ap-hc"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

//données inserees dans la fonction lambda
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "index.mjs"
  output_path = "index.zip"
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "index.zip"
  function_name = "g4-getParisHours"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "nodejs18.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

// Création de l'API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = "g4-paris-time-api"
  description = "API for retrieving current time in Paris"
}

// Création de la ressource (endpoint) /time
resource "aws_api_gateway_resource" "resource_time" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "time"
}

//configuration de l'api
resource "aws_api_gateway_method" "get_time" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource_time.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource_time.id
  http_method             = aws_api_gateway_method.get_time.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.test_lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
