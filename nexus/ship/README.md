## Ship Lambda

In order to run the lambda:
1. In the AWS Console, navigate to the Lambda page, and find the `nexus_launch_ship_task` lambda.
2. Head to the "Test" tab. There you can trigger events for the lambda.

Here is a sample of the event 

```json
{
  "EXPORT_FILE_PATH": "export_file.json",
  "POSTGRES_DATABASE": "nexus-db-name",
  "POSTGRES_HOST": "db.hostname.here.com",
  "POSTGRES_USERNAME": "nexus-db-name",
  "TARGET_BASE_URI": "https://openbluebrain.com/api/delta/v1",
  "TARGET_BUCKET": "nexus-test-bucket-name",
  "OFFSET": "123456"
}
```