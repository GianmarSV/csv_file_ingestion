resource "null_resource" "clean_lambda" {
  provisioner "local-exec" {
    command = <<EOT
      rm -f "../../../lambda/csv_file_persistence/lambda_function.zip"
      rm -f "../../../lambda/glue_trigger/lambda_function.zip"
    EOT
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "null_resource" "create_layers" {
  provisioner "local-exec" {
    command = <<EOT
      docker build -t csv-api-lambda-layer -f "../../../lambda_layers/csv_api/Dockerfile" "../../../lambda_layers/csv_api"
      docker run --name csv-api-container -d csv-api-lambda-layer
      docker cp csv-api-container:/opt/layer.zip "../../../lambda_layers/csv_api/layer.zip"
      docker stop csv-api-container
      docker rm csv-api-container


      docker build -t polars-lambda-layer -f "../../../lambda_layers/polars/Dockerfile" "../../../lambda_layers/polars"
      docker run --name polars-container -d polars-lambda-layer
      docker cp polars-container:/opt/layer.zip "../../../lambda_layers/polars/layer.zip"
      docker stop polars-container
      docker rm polars-container
    EOT
  }


  #triggers = {
  #  always_run = "${timestamp()}"
  #}
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../../../lambda/csv_file_persistence"
  output_path = "../../../lambda/csv_file_persistence/lambda_function.zip"
  depends_on  = [null_resource.clean_lambda]
}


resource "aws_s3_object" "lambda_layer_api_zip" {
  bucket = aws_s3_bucket.file_processing_datalake_bucket.bucket
  key    = "lambda_layer_api.zip"
  source = "../../../lambda_layers/csv_api/layer.zip"
  depends_on = [null_resource.create_layers]
}
resource "aws_s3_object" "lambda_layer_polars_zip" {
  bucket = aws_s3_bucket.file_processing_datalake_bucket.bucket
  key    = "lambda_layer_polars.zip"
  source = "../../../lambda_layers/polars/layer.zip"
  depends_on = [null_resource.create_layers]
}


resource "aws_lambda_layer_version" "csv_api_layer" {
  s3_bucket = aws_s3_bucket.file_processing_datalake_bucket.bucket
  s3_key    = aws_s3_object.lambda_layer_api_zip.key
  layer_name = "csv_api_layer"
  compatible_runtimes = ["python3.8"]
}
resource "aws_lambda_layer_version" "polars_layer" {
  s3_bucket = aws_s3_bucket.file_processing_datalake_bucket.bucket
  s3_key    = aws_s3_object.lambda_layer_polars_zip.key
  layer_name = "polars_layer"
  compatible_runtimes = ["python3.8"]
}


resource "aws_lambda_function" "csv_ingest" {
  function_name    = "csv_ingest"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.8"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  layers = [
    aws_lambda_layer_version.csv_api_layer.arn,
    aws_lambda_layer_version.polars_layer.arn
  ]

  timeout = 10
}






# GLUE TRIGGER
data "archive_file" "lambda_glue_trigger_zip" {
  type        = "zip"
  source_dir  = "../../../lambda/glue_trigger"
  output_path = "../../../lambda/glue_trigger/lambda_function.zip"
  depends_on  = [null_resource.clean_lambda]
}
resource "aws_lambda_function" "glue_trigger" {
  function_name    = "glue_trigger"
  role             = aws_iam_role.lambda_glue_trigger_role.arn
  handler          = "main.handler"
  runtime          = "python3.8"

  filename         = data.archive_file.lambda_glue_trigger_zip.output_path
  source_code_hash = data.archive_file.lambda_glue_trigger_zip.output_base64sha256

  environment {
    variables = {
      GLUE_JOB_NAME = aws_glue_job.csv_processor.name
    }
  }
}