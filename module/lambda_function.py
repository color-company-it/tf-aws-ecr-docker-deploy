"""
Handler to trigger Codebuild Job from S3 put event.
"""

import boto3
import os

SESSION = boto3.Session(
    region_name=os.getenv("REGION_NAME")
)

CODEBUILD = SESSION.client("codebuild")
CODEBUILD_PROJECT_NAME = os.getenv("CODEBUILD_PROJECT_NAME")


def lambda_handler(event, context):
    """
    Lambda Handler.
    """
    try:
        CODEBUILD.start_build(
            projectName=CODEBUILD_PROJECT_NAME
        )
        return f"Successfully started Codebuild Project: {CODEBUILD_PROJECT_NAME}."
    except Exception as error:
        return f"Unable to start Codebuild Project: {CODEBUILD_PROJECT_NAME}. " \
               f"With error: {error}."
