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

resource "aws_athena_named_query" "create_github_notebook_start_events_view" {
  name        = "github_notebook_start_events_view"
  description = "Creates or replaces the flattened view of the start events of github based notebooks"
  database    = aws_glue_catalog_database.notebook_service_statistics.name
  workgroup   = aws_athena_workgroup.reports.name
  query       = <<-SQL
    CREATE OR REPLACE VIEW AwsDataCatalog.notebook_service_statistics.github_notebook_start_events_view AS
    SELECT
    cast((from_iso8601_timestamp(time) AT TIME ZONE 'UTC') as timestamp) AS event_timestamp,
    date(date_trunc('second', (from_iso8601_timestamp(time) AT TIME ZONE 'UTC'))) AS event_date,
    time                                            AS raw_time,
    extra.extra.notebook_name                       AS notebook_name,
    extra.extra.notebook_scale                      AS notebook_scale,
    extra.extra.github_path                         AS github_path,
    extra.extra.github_user                         AS github_user,
    extra.extra.github_repo                         AS github_repo,
    extra.extra.github_branch                       AS github_branch,
    extra.extra.vlab_id                             AS vlab_id,
    extra.extra.project_id                          AS project_id,
    extra.extra.user_id                             AS user_id,
    extra.extra.username                            AS username,
    from_unixtime(round(extra.extra.started_on, 3)) AS started_on_timestamp,
    extra.extra.started_on                          AS started_on_float,
    extra.extra.namedserver_name                    AS namedserver_name,
    extra.extra.accounting_jobid                    AS accounting_jobid,
    year, month, day
    FROM  "AwsDataCatalog"."notebook_service_statistics"."notebook_service_statistics_raw_events"
    WHERE extra.extra.analysis_notebook_template_id is null
    AND message like '% was created %'
  SQL
}

resource "aws_athena_named_query" "create_analysis_notebook_template_start_events_view" {
  name        = "analysis_notebook_template_start_events_view"
  description = "Creates or replaces the flattened view of the start events of entitycore based notebooks"
  database    = aws_glue_catalog_database.notebook_service_statistics.name
  workgroup   = aws_athena_workgroup.reports.name
  query       = <<-SQL
    CREATE OR REPLACE VIEW AwsDataCatalog.notebook_service_statistics.analysis_notebook_template_start_events_view AS
    SELECT
    cast((from_iso8601_timestamp(time) AT TIME ZONE 'UTC') as timestamp) AS event_timestamp,
    date(date_trunc('second', (from_iso8601_timestamp(time) AT TIME ZONE 'UTC'))) AS event_date,
    time                                            AS raw_time,
    extra.extra.notebook_name                       AS notebook_name,
    extra.extra.notebook_scale                      AS notebook_scale,
    extra.extra.analysis_notebook_template_id       AS analysis_notebook_template_id,
    extra.extra.analysis_notebook_template_filename AS analysis_notebook_template_filename,
    extra.extra.vlab_id                             AS vlab_id,
    extra.extra.project_id                          AS project_id,
    extra.extra.user_id                             AS user_id,
    extra.extra.username                            AS username,
    from_unixtime(round(extra.extra.started_on, 3)) AS started_on_timestamp,
    extra.extra.started_on                          AS started_on_float,
    extra.extra.namedserver_name                    AS namedserver_name,
    extra.extra.accounting_jobid                    AS accounting_jobid,
    year, month, day
    FROM  "AwsDataCatalog"."notebook_service_statistics"."notebook_service_statistics_raw_events"
    WHERE extra.extra.analysis_notebook_template_id is not null
    AND message like '% was created %'
  SQL
}

resource "aws_athena_named_query" "create_notebook_end_events_view" {
  name        = "notebook_end_events_view"
  description = "Creates or replaces the flattened view of the end events of notebooks"
  database    = aws_glue_catalog_database.notebook_service_statistics.name
  workgroup   = aws_athena_workgroup.reports.name
  query       = <<-SQL
    CREATE OR REPLACE VIEW AwsDataCatalog.notebook_service_statistics.notebook_end_events_view AS
    SELECT
    cast((from_iso8601_timestamp(time) AT TIME ZONE 'UTC') as timestamp) AS event_timestamp,
    date(date_trunc('second', (from_iso8601_timestamp(time) AT TIME ZONE 'UTC'))) AS event_date,
    time                                            AS raw_time,
    extra.extra.vlab_id                             AS vlab_id,
    extra.extra.project_id                          AS project_id,
    extra.extra.user_id                             AS user_id,
    from_unixtime(round(extra.extra.started_on, 3)) AS started_on_timestamp,
    extra.extra.started_on                          AS started_on_float,
    extra.extra.namedserver_name                    AS namedserver_name,
    extra.extra.accounting_jobid                    AS accounting_jobid,
    extra.extra.seconds                             AS seconds,
    year, month, day
    FROM  "AwsDataCatalog"."notebook_service_statistics"."notebook_service_statistics_raw_events"
    WHERE message like '% has stopped %'
  SQL
}

resource "aws_athena_named_query" "create_analysis_notebook_template_full_runs_view" {
  name        = "analysis_notebook_template_full_runs_view"
  description = "Creates or replaces the flattened view of the end events of notebooks"
  database    = aws_glue_catalog_database.notebook_service_statistics.name
  workgroup   = aws_athena_workgroup.reports.name
  query       = <<-SQL
    CREATE OR REPLACE VIEW AwsDataCatalog.notebook_service_statistics.analysis_notebook_template_full_runs_view AS
    SELECT
    start_event.event_timestamp as start_event_timestamp,
    start_event.event_date as start_event_date,
    end_event.event_timestamp as end_event_timestamp,
    end_event.event_date as end_event_date,
    start_event.vlab_id,
    start_event.project_id,
    start_event.user_id,
    start_event.started_on_timestamp,
    start_event.started_on_float,
    end_event.seconds,
    start_event.analysis_notebook_template_id,
    start_event.analysis_notebook_template_filename,
    start_event.username,
    start_event.namedserver_name,
    start_event.accounting_jobid,
    start_event.year,
    start_event.month,
    start_event.day
    from AwsDataCatalog.notebook_service_statistics.notebook_end_events_view as end_event,
    AwsDataCatalog.notebook_service_statistics.analysis_notebook_template_start_events_view as start_event
    where start_event.accounting_jobid = end_event.accounting_jobid
    and start_event.user_id = end_event.user_id
    and start_event.project_id = end_event.project_id
    and start_event.year = end_event.year
    and start_event.month = end_event.month
    and start_event.day = end_event.day
  SQL
}

resource "aws_athena_named_query" "github_notebook_most_active_users_of_current_month" {
  name        = "github_notebooks_most_active_users_of_current_month"
  database    = aws_glue_catalog_database.notebook_service_statistics.name
  workgroup   = aws_athena_workgroup.reports.name
  description = "Number of GitHub notebook starts per user this month"

  query = <<SQL
    SELECT username, count(*) AS "Number of notebook runs"
    FROM notebook_service_statistics.github_notebook_start_events_view
    where year = year(current_date) AND month = month(current_date)
    group by username order by "Number of notebook runs" desc;
SQL
}

resource "aws_athena_named_query" "analysis_notebook_template_most_active_users_of_current_month" {
  name        = "analysis_notebook_templates_most_active_users_of_current_month"
  database    = aws_glue_catalog_database.notebook_service_statistics.name
  workgroup   = aws_athena_workgroup.reports.name
  description = "Number of AnalysisNotebookTemplate starts per user this month"

  query = <<SQL
    SELECT username, count(*) AS "Number of notebook runs"
    FROM notebook_service_statistics.analysis_notebook_template_start_events_view
    where year = year(current_date) AND month = month(current_date)
    group by username order by "Number of notebook runs" desc;
SQL
}

resource "aws_athena_named_query" "github_notebooks_by_popularity_this_month" {
  name        = "github_notebooks_by_popularity_of_current_month"
  database    = aws_glue_catalog_database.notebook_service_statistics.name
  workgroup   = aws_athena_workgroup.reports.name
  description = "Most opened github notebooks this month"

  query = <<SQL
    SELECT count(*) AS "Number of notebook runs",
    github_user, github_path, github_repo, github_branch
    FROM notebook_service_statistics.github_notebook_start_events_view
    where year = year(current_date) AND month = month(current_date)
    group by github_user, github_repo, github_branch, github_path
    order by "Number of notebook runs" DESC;
SQL
}

resource "aws_athena_named_query" "analysis_notebook_templates_by_popularity_this_month" {
  name        = "analysis_notebook_templates_by_popularity_of_current_month"
  database    = aws_glue_catalog_database.notebook_service_statistics.name
  workgroup   = aws_athena_workgroup.reports.name
  description = "Most opened AnalysisNotebookTemplates this month"

  query = <<SQL
    SELECT count(*) AS "Number of notebook runs",
    analysis_notebook_template_id, analysis_notebook_template_filename
    FROM notebook_service_statistics.analysis_notebook_template_start_events_view
    where year = year(current_date) AND month = month(current_date)
    group by analysis_notebook_template_id, analysis_notebook_template_filename
    order by "Number of notebook runs" DESC;
SQL
}

# Example query across notebook statistics and accounting database.
# Athena doesn't handle UUIDs from PostgreSQL databases very well yet.
# https://github.com/awslabs/aws-athena-query-federation/issues/442
resource "aws_athena_named_query" "analysis_notebook_templates_with_accounting_job_info_example" {
  name        = "analysis_notebook_templates_with_accounting_job_info_example"
  database    = aws_glue_catalog_database.notebook_service_statistics.name
  workgroup   = aws_athena_workgroup.reports.name
  description = "Combine AnalysisNotebookTemplate job with accounting job info"

  query = <<SQL
    SELECT * FROM AwsDataCatalog.notebook_service_statistics.analysis_notebook_template_start_events_view start_event,
    "${var.acounting_db_athena_connector_name}"."public"."job" as job where from_utf8(to_utf8(job.id)) = start_event.accounting_jobid
    and start_event.year = year(current_date) AND start_event.month = month(current_date)
SQL
}


