# github_ticket_digest

Weekly digest of stale GitHub tickets, posted to a Microsoft Teams channel.
**Deployed in staging only** (gated by `is_staging` in `cs/main.tf`).

A Python AWS Lambda collects **open issues with no update in the last
`stale_days` days** (default 7) and posts a digest as an Adaptive Card to Teams
via a Power Automate workflow webhook. It is triggered by an EventBridge
schedule rule (default: Monday 08:00 UTC).

By default it reproduces project #10's "standup" board view: a single REST
issue search for `label:standup` + open + stale, then a cheap batched GraphQL
lookup of each candidate's board **Status** on project #10, dropping
`Cancelled`, `Archived (done)`, `Archived (cancelled)`. (The GitHub API cannot
return a project view's items directly, nor filter a board server-side, so the
view's filter is reconstructed here; the full board is never scanned.) Set
`project_number = 0` to skip the status enrichment and use the plain org-wide
issue search.

## GitHub token scopes

The `obiadministrator` classic PAT needs `repo` (issue search) **and
`read:project`** (to read each candidate's board Status in project mode).
Without `read:project`, project mode fails with an INSUFFICIENT_SCOPES error.

## Secrets

This module does **not** create secrets. Both secrets live in the common
deployment (`aws-terraform-deployment-common`) and their ARNs/names are passed
in as variables. Each is a JSON object; the module reads a specific key.

- `github_ticket_digest_secrets` — GitHub token for the `obiadministrator`
  service account. Key `github_token`.
- `teams_webhook_secrets` (shared) — Teams Power Automate URLs keyed by
  consumer. Key `github_ticket_digest`.

Populate the values out-of-band (not stored in Terraform):

```sh
aws secretsmanager put-secret-value \
  --secret-id github_ticket_digest_secrets \
  --secret-string '{"github_token":"ghp_xxx"}'

# Add/merge the github_ticket_digest key into the shared teams webhook secret:
aws secretsmanager put-secret-value \
  --secret-id teams_webhook_secrets \
  --secret-string '{"...existing keys...","github_ticket_digest":"https://prod-xx.logic.azure.com/workflows/..."}'
```

## IAM

The Lambda execution role is least-privilege: `secretsmanager:GetSecretValue`
on exactly the two secret ARNs, plus CloudWatch Logs write to its own log
group.

## Manual test

```sh
aws lambda invoke --function-name github-ticket-digest /dev/stdout
```
