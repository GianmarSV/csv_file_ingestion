import os
import boto3

def handler(event, context):
    for record in event['Records']:
        bucket_name = record['s3']['bucket']['name']
        object_key = record['s3']['object']['key']
        print(f"Bucket: {bucket_name}, Key: {object_key}")

    glue = boto3.client('glue')
    glue_job_name = 'csv_processor'
    response = glue.start_job_run(
        JobName=glue_job_name,
        Arguments={
            '--s3_prefix': object_key
        })
    return response