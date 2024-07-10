resource "aws_s3_bucket" "file_processing_datalake_bucket" {
  bucket = "file-processing-datalake"
}

resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  bucket = "${aws_s3_bucket.file_processing_datalake_bucket.id}"
  lambda_function {
    lambda_function_arn = "${aws_lambda_function.glue_trigger.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "parquets"
    filter_suffix       = ".parquet"
  }
}
resource "aws_lambda_permission" "permission" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.glue_trigger.function_name}"
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.file_processing_datalake_bucket.id}"
}