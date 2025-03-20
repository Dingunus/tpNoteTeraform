
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
# Ressource de méthode GET sur API Gateway
resource "aws_api_gateway_method" "get_time" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource_time.id
  http_method   = "GET"
  authorization = "NONE"
}

# Intégration de la Lambda avec API Gateway
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource_time.id
  http_method             = aws_api_gateway_method.get_time.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.test_lambda.invoke_arn
}

# Autorisation Lambda pour API Gateway
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Déploiement de l'API Gateway sans le `stage_name`
resource "aws_api_gateway_deployment" "api" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_method.get_time
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
}

# Création du stage "prod"
resource "aws_api_gateway_stage" "prod" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api.id
}

# Récupération de l'URL de l'API Gateway déployée
output "api_gateway_url" {
  value       = aws_api_gateway_stage.prod.invoke_url
  description = "L'URL de l'API Gateway déployée"
}
