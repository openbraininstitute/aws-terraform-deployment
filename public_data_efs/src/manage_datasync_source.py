#!/usr/bin/env python

from botocore.exceptions import ClientError
import boto3
import os


BUCKET_NAME = os.environ["BUCKET_NAME"]
TAGS = {"SBO_Billing": "entitycore", "dataset": "opendata"}


def datasync_client():
    return boto3.client("datasync")


def list_locations(ds_client):
    try:
        filters = [
            {"Name": "LocationType", "Values": ["S3"], "Operator": "Equals"},
            {
                "Name": "LocationUri",
                "Values": [f"s3://{BUCKET_NAME}"],
                "Operator": "BeginsWith",
            },
        ]

        locations = []
        paginator = ds_client.get_paginator("list_locations")

        for page in paginator.paginate(Filters=filters):
            locations.extend(page.get("Locations", []))

        print(f"Locations: {locations}")
        return locations

    except ClientError as e:
        print(f"Error listing DataSync locations: {str(e)}")
        return []


def get_entitycore_location_list():
    # TODO: actually talk to entitycore
    locations = []
    return [
        f"s3://{BUCKET_NAME}{'' if location.startswith('/') else '/'}{location}{'' if location.endswith('/') else '/'}"
        for location in locations
    ]


def remove_location(ds_client, location):
    """
    Remove both the location and any job referencing it
    """
    try:
        location_arn = location["LocationArn"]
        tasks_to_delete = []
        paginator = ds_client.get_paginator("list_tasks")

        for page in paginator.paginate():
            for task in page.get("Tasks", []):
                task_arn = task["TaskArn"]
                task_info = ds_client.describe_task(TaskArn=task_arn)

                if (
                    task_info["SourceLocationArn"] == location_arn
                    or task_info["DestinationLocationArn"] == location_arn
                ):
                    tasks_to_delete.append(task_arn)

        for task_arn in tasks_to_delete:
            print(f"Deleting task: {task_arn}")
            ds_client.delete_task(TaskArn=task_arn)

        print(f"Deleting location: {location_arn}")
        ds_client.delete_location(LocationArn=location_arn)

    except ClientError as e:
        print(f"Error removing location {location}: {str(e)}")
        raise


def create_location(ds_client, location: str):
    """
    Create a DataSync S3 location with the given bucket and path.
    Also sets up a task to sync from this location to os.environ["DESTINATION_LOCATION_ARN"]

    @param location: the path within the S3 bucket to sync
    """

    try:
        bucket_arn = f"arn:aws:s3:::{BUCKET_NAME}"
        bucket_role_arn = os.environ["S3_BUCKET_ROLE_ARN"]

        print(f"Create location with subdirectory: {location}")
        response = ds_client.create_location_s3(
            Subdirectory=location,
            S3BucketArn=bucket_arn,
            S3StorageClass="STANDARD",
            S3Config={"BucketAccessRoleArn": bucket_role_arn},
            Tags=[{"Key": key, "Value": value} for key, value in TAGS.items()],
        )

        source_location_arn = response["LocationArn"]
        destination_location_arn = os.environ["DESTINATION_LOCATION_ARN"]

        task_response = ds_client.create_task(
            SourceLocationArn=source_location_arn,
            DestinationLocationArn=destination_location_arn,
            Name=f"sync-{BUCKET_NAME}-{source_location_arn.split('/')[-1]}",
            Options={
                "VerifyMode": "ONLY_FILES_TRANSFERRED",
                "Atime": "BEST_EFFORT",
                "Mtime": "PRESERVE",
                "TaskQueueing": "ENABLED",
            },
            Schedule={"ScheduleExpression": "cron(0 0 ? * * *)", "Status": "ENABLED"},
            Tags=[{"Key": key, "Value": value} for key, value in TAGS.items()],
        )

        print(f"Created location: {source_location_arn}")
        print(f"Created task: {task_response['TaskArn']}")

    except ClientError as e:
        print(f"Error creating location {location}: {str(e)}")
        raise


def main():
    ds_client = datasync_client()
    existing_locations = list_locations(ds_client)
    entitycore_location_paths = get_entitycore_location_list()
    print(f"Existing locations: {existing_locations}")
    print(f"Entitycore location paths: {entitycore_location_paths}")

    locations_to_remove = [
        location
        for location in existing_locations
        if location["LocationUri"] not in entitycore_location_paths
    ]

    locations_to_create = [
        location.split("/", 3)[3]
        for location in entitycore_location_paths
        if location not in [loc["LocationUri"] for loc in existing_locations]
    ]

    print("Locations to remove (exist in DataSync but not in entitycore):")
    for location in locations_to_remove:
        print(f"  - {location['LocationUri']} (ARN: {location['LocationArn']})")
        remove_location(ds_client, location)

    print("\nLocations to create (exist in entitycore but not in DataSync):")
    for location in locations_to_create:
        print(f"  - {location}")
        create_location(ds_client, location)

    return locations_to_remove, locations_to_create


def lambda_handler(event, context):
    removed, created = main()
    return {"removed": removed, "created": created}


if __name__ == "__main__":
    main()
