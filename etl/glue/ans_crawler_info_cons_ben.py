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

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)
s3 = boto3.resource("s3")
s3C = boto3.client("s3")

client = boto3.client("sts")

account_id = client.get_caller_identity().get("Account")
S3_BUCKET_NAME = f"ans-data-pipeline-raw-zone-{account_id}"
S3_BUCKET = f"s3a://{S3_BUCKET_NAME}"

SERVER_PATH = "http://ftp.dadosabertos.ans.gov.br/FTP"
PARQUET_PATH = "/".join(["INFO_CONS_BEN"])
TEMP_PATH = "/".join([".glue_temp_dir", "INFO_CONS_BEN"])


def s3_object_exists(key):
    results = s3C.list_objects(Bucket=S3_BUCKET_NAME, Prefix=key)
    return "Contents" in results


def download_file(web_path, local_path):
    try:
        start_time = time.time()
        with closing(request.urlopen("/".join([SERVER_PATH, web_path]))) as r:
            with open(local_path, "wb") as f:
                shutil.copyfileobj(r, f)
        print(f"Downloaded file from {web_path} in {time.time() - start_time} seconds")
    except:
        print(f"Cannot download file:{'/'.join([SERVER_PATH,web_path])}")


def download_and_unzip(ftp_path, local_path):
    if os.path.exists(local_path + ".zip"):
        os.remove(local_path + ".zip")

    download_file(ftp_path, local_path + ".zip")

    with zipfile.ZipFile(local_path + ".zip", "r") as zip_ref:
        zip_ref.extractall(local_path)


def download_ans_info_cons_ben(year, month, uf, out_dir):
    if os.path.exists(out_dir):
        shutil.rmtree(out_dir)

    download_and_unzip(
        f"PDA/informacoes_consolidadas_de_beneficiarios/{year}{month:02}/ben{year}{month:02}_{uf}.zip",
        out_dir,
    )


def delete_s3_folder(folder_path):

    if s3_object_exists(folder_path):
        bucket = s3.Bucket(S3_BUCKET_NAME)
        bucket.objects.filter(Prefix=folder_path).delete()


def ans_info_cons_ben_ftp2df(year, month, uf, s3_temp_folder):
    donwload_foler = f"extracted_zip_{year}_{month}_{uf}"
    download_ans_info_cons_ben(year, month, uf, donwload_foler)

    start_time = time.time()

    delete_s3_folder(s3_temp_folder)

    for root, _, files in os.walk(donwload_foler):
        for file in files:
            s3C.upload_file(
                os.path.join(root, file),
                S3_BUCKET_NAME,
                "".join([s3_temp_folder, file]),
            )

    shutil.rmtree(donwload_foler)

    print(f"Moved files to S3 in {time.time() - start_time} seconds")

    start_time = time.time()
    df = spark.read.options(
        delimiter=";", header=True, inferSchema="False", encoding="latin1"
    ).csv(f"{S3_BUCKET}/{s3_temp_folder}/*.csv")
    print(f"Loaded csv in {time.time() - start_time} seconds")

    return df


def ans_info_cons_ben_ftp2parquet(year, month, uf):

    s3_temp_folder = "/".join([TEMP_PATH, f"extracted_zip_{year}_{month}_{uf}/"])
    df = ans_info_cons_ben_ftp2df(year, month, uf, s3_temp_folder)

    start_time = time.time()

    df.withColumnRenamed("#ID_CMPT_MOVEL", "ID_CMPT_MOVEL").write.mode(
        "append"
    ).partitionBy(["ID_CMPT_MOVEL", "SG_UF"]).parquet(
        "/".join([S3_BUCKET, PARQUET_PATH])
    )

    print(
        f"Wrote data  from year {year}, month {month} and UF {uf} in {time.time() - start_time} seconds"
    )

    df.unpersist()
    delete_s3_folder(s3_temp_folder)


def all_ans_info_cons_ben_2parquet(years, months, ufs):
    for year in years:
        for month in months:
            for uf in ufs:
                if s3_object_exists(
                    "/".join(
                        [PARQUET_PATH, f"ID_CMPT_MOVEL={year}{month:02}", f"SG_UF={uf}"]
                    )
                ):
                    print(
                        f"Skiping year {year}, month {month}, UF {uf}: Data already exists"
                    )
                else:
                    try:
                        start_time = time.time()
                        ans_info_cons_ben_ftp2parquet(year, month, uf)
                        print(
                            f"Processed data from year {year}, month {month}, UF {uf} in {time.time() - start_time} seconds"
                        )
                        print(
                            "--------------------------------------------------------------------------------------------"
                        )
                    except Exception as e:
                        print(
                            f"Unable to process data from year {year}, month {month}, UF {uf}"
                        )
                        print(e)


all_ans_info_cons_ben_2parquet(
    range(2014, 2015),
    range(1, 13),
    ["MG"],
)
