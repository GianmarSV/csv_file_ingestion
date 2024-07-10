import json
import base64
import boto3
import polars as pl
from io import BytesIO
from datetime import datetime
from multipart import MultipartParser
from multipart.multipart import parse_options_header

from file_classifier import FileClassifier

class FileHandler(object):
    def __init__(self):
        self.file_content = b''
        self.filename = None

    def on_part_data(self, data, start, end):
        # Decode the headers from the data to check for filename
        part_headers_end = data.find(b"\r\n\r\n") + 4
        part_headers = data[:part_headers_end].decode('utf-8')
        
        # Check for Content-Disposition header
        if 'Content-Disposition' in part_headers:
            headers = part_headers.split("\r\n")
            for header in headers:
                if header.startswith("Content-Disposition"):
                    disposition = header
                    if 'filename' in disposition:
                        self.filename = disposition.split('filename=')[1].strip('"')

        self.file_content += data[start:end]


s3_client = boto3.client('s3')


def lambda_handler(event, context):

    content_type_header = event["headers"].get("content-type") or event["headers"].get("Content-Type")

    if not content_type_header:
        return {
            "statusCode": 400,
            "body": "Missing Content-Type header"
        }

    content_type, params = parse_options_header(content_type_header)
    boundary = params.get(b'boundary')
    if not boundary:
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "Boundary not found in content-type header"})
        }


    # Multipart Parser Logic
    file_handler = FileHandler()
    callbacks = {
        'on_part_data': file_handler.on_part_data,
    }
    parser = MultipartParser(boundary, callbacks)


    body = event["body"]
    is_base64_encoded = event["isBase64Encoded"]
    if is_base64_encoded:
        body = base64.b64decode(body)
    else:
        body = body.encode("utf-8")

    size = len(body)
    start = 0
    while start < size:
        # Read in chunks of up to 1 MB
        chunk_size = min(size - start, 1024 * 1024)
        parser.write(body[start:start + chunk_size])
        start += chunk_size

    if not file_handler.file_content:
        return {
            "statusCode": 400,
            "body": "No file content found in multipart data"
        }

    try:
        classifier = FileClassifier(file_handler.filename)
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        s3_key = f"uploads/{classifier.path}/{timestamp}_{file_handler.filename}"
        
        s3_client.put_object(
            Body=file_handler.file_content,
            Bucket='file-processing-datalake',
            Key=s3_key,
            ContentType=content_type_header
        )


        # Convert to Parquet format and save
        df = pl.read_csv(BytesIO(file_handler.file_content), has_header=False, schema=classifier.schema)
        current_datetime = datetime.now()
        df = df.with_columns(pl.lit(current_datetime).alias('ingestion_datetime'))
        parquet_buffer = BytesIO()
        df.write_parquet(parquet_buffer, compression='snappy')
        parquet_key = f"parquets/{classifier.path}/{timestamp}_{file_handler.filename}.parquet"
        
        s3_client.put_object(
            Body=parquet_buffer.getvalue(),
            Bucket='file-processing-datalake',
            Key=parquet_key,
            ContentType='application/x-parquet'
        )

    except Exception as e:
        return {
            "statusCode": 500,
            "body": f"Error uploading file to S3: {str(e)}"
        }


    return {
        "statusCode": 200,
        "body": json.dumps({"message": "File processed and uploaded to S3 successfully"})
    }

