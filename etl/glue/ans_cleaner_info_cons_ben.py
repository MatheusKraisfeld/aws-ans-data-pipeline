import datetime
import sys
import time

from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

glueContext = GlueContext(SparkContext.getOrCreate())
spark = glueContext.spark_session

import logging
import os
import shutil
import urllib.request as request
import zipfile
from contextlib import closing

import boto3
import botocore
import botocore.vendored.requests.packages.urllib3 as urllib3
import pyspark.sql.functions as F
from pyspark.sql.column import Column
from pyspark.sql.dataframe import DataFrame
from pyspark.sql.types import (
    ArrayType,
    DateType,
    FloatType,
    IntegerType,
    StringType,
    TimestampType,
)
from unidecode import unidecode

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)
s3 = boto3.resource("s3")
s3C = boto3.client("s3")
client = boto3.client("sts")

account_id = client.get_caller_identity().get("Account")
S3_BUCKET_RAW = f"s3a://ans-data-pipeline-raw-zone-{account_id}"
S3_BUCKET_CLEANED = f"s3a://ans-data-pipeline-cleaned-zone-{account_id}"

PARQUET_PATH = "/".join(["INFO_CONS_BEN"])

### FUNCTIONS ###


@F.udf(returnType=StringType())
def unidecode_udf(string) -> Column:
    """
    Normalizes a string column in a Spark DataFrame by removing special characters, such as accents.

    Parameters
    ----------
    string : pyspark.sql.column.Column
        Column of a Spark DataFrame whose type is string.

    Returns
    -------
    pyspark.sql.column.Column:
        returns the resulting column
    """
    if string is None:
        return None
    else:
        return unidecode(string)


def clean_types(dtype, cols) -> DataFrame:
    """
    Performs a transformation in the columns passed in `cols` based on its data type.

    Parameters
    ----------
    dtype : str
        Data type of the columns. Available data types are:
        * date
        * str
        * int

    cols: List[str]
        List of columns to be transformed

    Returns
    -------
    pyspark.sql.dataframe.DataFrame:
        returns the resulting DataFrame
    """

    def _(df):
        nonlocal cols
        cols = [cols] if type(cols) is not list else cols
        if dtype == "int":
            for c in cols:
                df = df.withColumn(c, F.col(c).cast("int"))
        elif dtype == "str":
            for c in cols:
                df = df.withColumn(c, F.initcap(F.trim(unidecode_udf(F.col(c)))))
        elif dtype == "date":
            for c in cols:
                df = df.withColumn(c, F.to_date(F.col(c), "dd-MM-yyyy"))
        elif dtype == "double":
            for c in cols:
                df = df.withColumn(c, F.col(c).cast("double"))
        else:
            raise Exception("Data type not supported.")
        return df

    return _


def cleaner() -> None:
    ### READ DATA ###

    df_info_cons_ben = spark.read.parquet(f"{S3_BUCKET_RAW}/{PARQUET_PATH}")

    ### CLEAN DATA ###

    int_cols = [
        col
        for col in df_info_cons_ben.columns
        if "QT_" in col or "CD_" in col or col == "ID_CMPT_MOVEL"
    ]
    str_cols = [
        col for col in df_info_cons_ben.columns if col not in int_cols + ["DT_CARGA"]
    ]
    date_cols = ["DT_CARGA"]

    df_info_cons_ben = (
        df_info_cons_ben.withColumn("DT_CARGA", F.regexp_replace("DT_CARGA", "/", "-"))
        .transform(clean_types("int", int_cols))
        .transform(clean_types("date", date_cols))
        .transform(clean_types("str", str_cols))
    )

    ### WRITE DATA ###

    df_info_cons_ben.write.mode("overwrite").partitionBy(
        ["ID_CMPT_MOVEL", "SG_UF"]
    ).parquet(f"{S3_BUCKET_CLEANED}/{PARQUET_PATH}")


# cleaner()
logger.info("Job done!")

### END ###
