# Crear DynamoDB Table
resource "aws_dynamodb_table" "equipos" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "equipo"

  attribute {
    name = "equipo"
    type = "S"
  }

  tags = {
    Name = "equipos"
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda-dynamodb-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_policy" "dynamodb_policy" {
  name        = "lambda-dynamodb-policy"
  description = "Policy that allows Lambda to access DynamoDB"
  policy      = data.aws_iam_policy_document.dynamodb_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

resource "aws_lambda_function" "seed_lambda" {
  filename         = "../lambda_python/lambda_seed.zip"
  function_name    = "SeedDataFunction"
  role             = aws_iam_role.lambda_role.arn
  handler          = "seed_lambda.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("../lambda_python/lambda_seed.zip")
}

resource "aws_lambda_function" "read_lambda" {
  filename         = "../lambda_python/lambda_read.zip"
  function_name    = "ReadDataFunction"
  role             = aws_iam_role.lambda_role.arn
  handler          = "read_lambda.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("../lambda_python/lambda_read.zip")
}

resource "aws_api_gateway_rest_api" "api" {
  name        = "DynamoDBApi"
  description = "API for interacting with DynamoDB"
}

resource "aws_api_gateway_resource" "read_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "equipos"
}

resource "aws_api_gateway_method" "read_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.read_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "read_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.read_resource.id
  http_method             = aws_api_gateway_method.read_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.read_lambda.arn}/invocations"
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.read_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

# IAM Policy Documents
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "dynamodb_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem"
    ]
    resources = [aws_dynamodb_table.equipos.arn]
  }
}

# Add deployment stage for API Gateway
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  depends_on  = [aws_api_gateway_integration.read_integration]
}

resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id  = aws_api_gateway_rest_api.api.id
  stage_name   = "prod"
}

# Null resource to trigger seed lambda once
resource "null_resource" "seed_trigger" {
  triggers = {
    lambda_version = aws_lambda_function.seed_lambda.version
  }

  provisioner "local-exec" {
    command = "aws lambda invoke --function-name ${aws_lambda_function.seed_lambda.function_name} --region ${var.aws_region} /dev/null"
  }

  depends_on = [aws_lambda_function.seed_lambda]
}