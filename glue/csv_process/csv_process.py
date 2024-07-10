import sys
import re
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import concat_ws, md5, col
from pyspark.sql.types import StructType, StructField, IntegerType, StringType, TimestampType


SCHEMAS = {
    'hired_employees': StructType([
        StructField("id", IntegerType(), True),
        StructField("name", StringType(), True),
        StructField("datetime", TimestampType(), True),
        StructField("department_id", IntegerType(), True),
        StructField("job_id", IntegerType(), True),
        StructField("ingestion_datetime", TimestampType(), True),
        #StructField("md5", StringType(), True)
    ]),
    'departments': StructType([
        StructField("id", IntegerType(), True),
        StructField("department", StringType(), True),
        StructField("ingestion_datetime", TimestampType(), True),
        #StructField("md5", StringType(), True)
    ]),
    'jobs': StructType([
        StructField("id", IntegerType(), True),
        StructField("job", StringType(), True),
        StructField("ingestion_datetime", TimestampType(), True),
        #StructField("md5", StringType(), True)
    ])
}


sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

args = getResolvedOptions(sys.argv, ['JOB_NAME', 's3_prefix'])

job = Job(glueContext)
job.init(args['JOB_NAME'], args)

s3_bucket = "file-processing-datalake"
s3_prefix = args['s3_prefix']

# Extract the path structure
results = re.search(r"(\w+)\/(\w+)\/(\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2})_(\w+)\.csv\.parquet", s3_prefix)
path, table, file_datetime, filename = results.groups()

# Set the dataframes to calculet the delta files
current_dataframe = spark.read.schema(SCHEMAS[table]).parquet(f"s3://{s3_bucket}/{s3_prefix}")
columns = [col_name for col_name in current_dataframe.columns if col_name != 'ingestion_datetime']
current_dataframe = current_dataframe.withColumn('md5', md5(concat_ws('|', *[col(c) for c in columns])))

try:
    data_frame = spark.read.parquet(f"s3://{s3_bucket}/source_of_truth/{table}/")
except Exception as e:
    data_frame = spark.createDataFrame(spark.sparkContext.emptyRDD(), current_dataframe.schema)

print('data frame count', data_frame.count())


result_dataframe = current_dataframe.join(
    data_frame, 'md5', how='leftanti'
)#.dropDuplicates('md5')

# Show the updated DataFrame
#result_dataframe.show()
print("Result data frame count: ", result_dataframe.count())


output_path = f"s3://{s3_bucket}/source_of_truth/{table}/"
result_dataframe.coalesce(1).write.mode("overwrite").parquet(output_path)

print(111111111111111111, result_dataframe.show())
result_dataframe = result_dataframe.drop("md5")
print(222222222222222222, result_dataframe.show())
result_dataframe = result_dataframe.drop("ingestion_datetime")
print(333333333333333333, result_dataframe.show())


# Write to RDS
jdbc_url = "jdbc:postgresql://terraform-20240708163001225100000001.cjowkqo6scv0.us-east-1.rds.amazonaws.com:5432/postgres"
result_dataframe.write \
    .format("jdbc") \
    .option("url", jdbc_url) \
    .option("dbtable", table) \
    .option("user", "engineer") \
    .option("password", "password_tech") \
    .mode("append") \
    .save()

job.commit()
