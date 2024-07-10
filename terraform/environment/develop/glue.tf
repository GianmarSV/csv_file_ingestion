resource "aws_s3_object" "file_upload" {
    bucket = aws_s3_bucket.file_processing_datalake_bucket.bucket
    key    = "glue/csv_process.py"
    source = "../../../glue/csv_process/csv_process.py"
    etag   = filemd5("../../../glue/csv_process/csv_process.py")
}

resource "aws_iam_role" "glue_role" {
  name = "glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "glue_policy" {
  name       = "glue-policy"
  roles      = [aws_iam_role.glue_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}


resource "aws_iam_policy" "glue_s3_bucket_policy" {
  name   = "glue_s3_bucket_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::file-processing-datalake",  # Bucket ARN
          "arn:aws:s3:::file-processing-datalake/*" # Objects in bucket
        ]
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "glue_s3_bucket_policy_attachment" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_s3_bucket_policy.arn
}


resource "aws_glue_job" "csv_processor" {
  name     = "csv_processor"
  role_arn = aws_iam_role.glue_role.arn
  glue_version = "3.0"
  
  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.file_processing_datalake_bucket.bucket}/glue/csv_process.py"
    python_version  = "3"
  }

  max_capacity = 2
  timeout      = 10
}