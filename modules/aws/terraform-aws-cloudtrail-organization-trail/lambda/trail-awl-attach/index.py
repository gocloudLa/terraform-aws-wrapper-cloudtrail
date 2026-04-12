"""Invoked from the delegated (security) account to call cloudtrail:UpdateTrail for org trail + CWL in this account."""

import boto3


def lambda_handler(event, context):
    client = boto3.client("cloudtrail")
    client.update_trail(
        Name=event["TrailArn"],
        CloudWatchLogsLogGroupArn=event["LogGroupArn"],
        CloudWatchLogsRoleArn=event["CloudWatchLogsRoleArn"],
    )
    return {"ok": True}
