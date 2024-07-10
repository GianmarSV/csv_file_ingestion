output "vpc_id" {
  value = aws_vpc.main.id
}

output "lambda_arn" {
  value = aws_lambda_function.csv_ingest.arn
}

output "api_url" {
  value = aws_api_gateway_stage.lambda_stage_dev.invoke_url
}

output "glue_job_name" {
  value = aws_glue_job.csv_processor.name
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}