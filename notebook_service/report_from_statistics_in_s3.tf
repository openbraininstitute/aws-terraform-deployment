# AWS Glue table: some virtual table which contains the data that is spread across
# small files in the S3 bucket. It uses the metadata like year, month and day to
# limit the number of files that it has to check within the bucket.
# The AWS Glue table contains the raw events, still in the json format as used by
# the notebook service.
# An AWS Athena workgroup defines where Athena can store (temporary) reports.
# In this case, it's in the 'reports' subdir of the obi-notebook-service-statistics-{prod/staging}
# bucket.
# A first named/saved query creates a view with a cleaner/flattened schema, which
# also converts the 'time' field which is still a string into a timestamp as
# 'event_timestamp'.
# The other named queries use that view to generate some test reports:
# * List the number of 'run on EKS' events per user this month.
# * List the opened notebooks (github repo/branch/file) ordered by number of times
#   that the notebook got opened.

resource "aws_glue_catalog_database" "notebook_service_statistics" {
  name = "notebook_service_statistics"
}

resource "aws_glue_catalog_table" "notebook_service_statistics_raw_events" {
  name          = "notebook_service_statistics_raw_events"
  database_name = aws_glue_catalog_database.notebook_service_statistics.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    classification    = "json"
    "compressionType" = "gzip"
    "EXTERNAL"        = "TRUE"
    # Partition projection
    "projection.enabled"        = "true"
    "projection.year.type"      = "integer"
    "projection.year.range"     = "2025,2035"
    "projection.month.type"     = "integer"
    "projection.month.range"    = "1,12"
    "projection.month.digits"   = "2"
    "projection.day.type"       = "integer"
    "projection.day.range"      = "1,31"
    "projection.day.digits"     = "2"
    "storage.location.template" = "s3://${aws_s3_bucket.statistics.bucket}/year=$${year}/month=$${month}/day=$${day}/"
  }

  partition_keys {
    name = "year"
    type = "int"
  }
  partition_keys {
    name = "month"
    type = "int"
  }
  partition_keys {
    name = "day"
    type = "int"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.statistics.bucket}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "json"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "time"
      type = "string"
    }
    columns {
      name = "level"
      type = "string"
    }
    columns {
      name = "message"
      type = "string"
    }
    columns {
      name = "exception"
      type = "string"
    }
    columns {
      name = "extra"
      type = trimspace(replace(replace(<<-EXTRA
        struct<extra:struct<
        type:string,
        notebook_name:string,
        notebook_scale:string,
        github_path:string,
        github_user:string,
        github_repo:string,
        github_branch:string,
        vlab_id:string,
        project_id:string,
        user_id:string,
        username:string,
        started_on:double,
        namedserver_name:string,
        seconds:double,
        accounting_jobid:string,
        analysis_notebook_template_id:string,
        analysis_notebook_template_filename:string
        >>
        EXTRA
      , "/\n/", ""), "/ /", "")) # Removes all spaces and newlines, becomes 1 string without any spaces
    }
  }
}

resource "aws_athena_workgroup" "reports" {
  name = "notebook-service-reports"

  configuration {
    enforce_workgroup_configuration = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.statistics.bucket}/reports/"
    }
  }
}

resource "aws_athena_named_query" "create_notebook_events_view" {
  name        = "notebook_events_view"
  description = "Creates or replaces the flattened view of the notebook events"
  database    = aws_glue_catalog_database.notebook_service_statistics.name
  workgroup   = aws_athena_workgroup.reports.name
  query       = <<-SQL
    CREATE OR REPLACE VIEW notebook_service_statistics.notebook_events_view AS
    SELECT
    cast((from_iso8601_timestamp(time) AT TIME ZONE 'UTC') as timestamp) AS event_timestamp,
    date(date_trunc('second', (from_iso8601_timestamp(time) AT TIME ZONE 'UTC'))) AS event_date,
    time                        AS raw_time,
    extra.extra.notebook_name   AS notebook_name,
    extra.extra.notebook_scale  AS notebook_scale,
    extra.extra.github_path     AS github_path,
    extra.extra.github_user     AS github_user,
    extra.extra.github_repo     AS github_repo,
    extra.extra.github_branch   AS github_branch,
    extra.extra.vlab_id         AS vlab_id,
    extra.extra.project_id      AS project_id,
    extra.extra.user_id         AS user_id,
    extra.extra.username        AS username,
    year, month, day
    FROM  "AwsDataCatalog"."notebook_service_statistics"."notebook_service_statistics_raw_events"
  SQL
}

resource "aws_athena_named_query" "most_active_users_of_current_month" {
  name        = "notebook_service_most_active_users_of_current_month"
  database    = aws_glue_catalog_database.notebook_service_statistics.name
  workgroup   = aws_athena_workgroup.reports.name
  description = "Number of notebook runs per user this month"

  query = <<SQL
SELECT username, count(*) AS "Number of notebook runs" FROM notebook_service_statistics.notebook_events_view
where year = year(current_date) AND month = month(current_date) group by username;
SQL
}

resource "aws_athena_named_query" "notebooks_by_popularity_this_month" {
  name        = "notebook_service_notebooks_by_popularity_of_current_month"
  database    = aws_glue_catalog_database.notebook_service_statistics.name
  workgroup   = aws_athena_workgroup.reports.name
  description = "Most opened notebooks this month"

  query = <<SQL
SELECT github_user, github_repo, github_branch, github_path, count(*) AS "Number of notebook runs" FROM notebook_service_statistics.notebook_events_view
where year = year(current_date) AND month = month(current_date) group by github_user, github_repo, github_branch, github_path order by "Number of notebook runs" DESC;
SQL
}
