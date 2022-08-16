import json
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

import boto3

client = boto3.client("glue")

glueJobName = "ans_crawler_info_cons_ben"


def lambda_handler(event, context):
    logger.info("## INITIATED BY EVENT: ")
    logger.info(event["detail"])
    response = client.start_job_run(JobName=glueJobName)
    logger.info("## STARTED GLUE JOB: " + glueJobName)
    logger.info("## GLUE JOB RUN ID: " + response["JobRunId"])
    return response
