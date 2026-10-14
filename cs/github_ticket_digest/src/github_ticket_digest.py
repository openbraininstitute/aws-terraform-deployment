"""Weekly stale GitHub ticket digest to Microsoft Teams.

Triggered weekly by an EventBridge schedule. Collects open issues that have
not been updated for N days ("stale"), optionally scoped to a GitHub Projects
v2 board and filtered by its Status field, then posts an Adaptive Card digest
to a Teams channel via a Power Automate workflow webhook.

Secrets (GitHub token, Teams webhook URL) are read from AWS Secrets Manager
via names passed in environment variables. Standard library + boto3 only.

Environment variables:
  GITHUB_TOKEN_SECRET_ID      id (name or ARN) of the Secrets Manager secret
                              (JSON) holding the GitHub token (obiadministrator)
  GITHUB_TOKEN_SECRET_KEY     JSON key within that secret holding the token
  TEAMS_WEBHOOK_SECRET_ID     id (name or ARN) of the Secrets Manager secret
                              (JSON) holding Teams Power Automate workflow URLs
  TEAMS_WEBHOOK_SECRET_KEY    JSON key within that secret holding the webhook URL
  GITHUB_ORG                  GitHub org to search (default: openbraininstitute)
  GITHUB_PROJECT_NUMBER       if >0, source items from this Projects v2 board
                              via GraphQL (requires read:project); else org-wide
                              REST issue search
  GITHUB_LABELS               comma-separated labels; only items carrying all of
                              them are included (default: none)
  GITHUB_ASSIGNEES            comma-separated logins; only items assigned to all
                              of them are included (default: none)
  GITHUB_EXCLUDE_STATUSES     comma-separated project "Status" option names to
                              exclude (project mode only), e.g.
                              "Cancelled,Archived (done),Archived (cancelled)"
  GITHUB_INCLUDE_STATUSES     comma-separated project "Status" option names to
                              keep (project mode only); if set, only these
                              statuses pass
  STALE_DAYS                  staleness threshold in days (default: 7)
  INCLUDE_PRS                 "true" to include pull requests (default: false)
  MAX_ITEMS                   max items to list in the digest (default: 100)
"""

from __future__ import annotations

import json
import logging
import os
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

import boto3
from botocore.exceptions import BotoCoreError, ClientError

logger: logging.Logger = logging.getLogger()
logger.setLevel(logging.INFO)

secrets_client = boto3.client("secretsmanager")

GITHUB_API = "https://api.github.com"
GITHUB_GRAPHQL_API = "https://api.github.com/graphql"
GITHUB_SEARCH_PAGE_SIZE = 100
# GitHub search API caps results at 1000 (10 pages of 100).
GITHUB_SEARCH_MAX_PAGES = 10
HTTP_TIMEOUT_SECONDS = 30


def _get_secret_by_name_and_key(id_env_var: str, key_env_var: str) -> str:
    """Fetch a value from a JSON Secrets Manager secret.

    The secret id (name or ARN) is read from ``id_env_var`` and the JSON key to
    extract from ``key_env_var``.
    """
    secret_id: Optional[str] = os.environ.get(id_env_var)
    if not secret_id or not secret_id.strip():
        raise ValueError(f"Missing or empty environment variable: {id_env_var}")
    secret_key: Optional[str] = os.environ.get(key_env_var)
    if not secret_key or not secret_key.strip():
        raise ValueError(f"Missing or empty environment variable: {key_env_var}")
    try:
        secret_str = secrets_client.get_secret_value(SecretId=secret_id)[
            "SecretString"
        ]
        secret_dict = json.loads(secret_str)
        return secret_dict[secret_key]
    except (ClientError, BotoCoreError) as exc:
        logger.error(
            "Failed to fetch secret %s key %s: %s",
            id_env_var,
            key_env_var,
            exc,
            exc_info=True,
        )
        raise
    except (json.JSONDecodeError, KeyError) as exc:
        logger.error(
            "Secret %s is not valid JSON or missing key %s: %s",
            id_env_var,
            key_env_var,
            exc,
            exc_info=True,
        )
        raise


def _github_search_issues(query: str, token: str) -> List[Dict[str, Any]]:
    """Run a GitHub Search API query, following pagination.

    GitHub's search endpoint returns at most 1000 results. We page through
    using page/per_page and stop when a page is short or we hit the cap.
    """
    items: List[Dict[str, Any]] = []
    for page in range(1, GITHUB_SEARCH_MAX_PAGES + 1):
        params = urllib.parse.urlencode(
            {
                "q": query,
                "per_page": GITHUB_SEARCH_PAGE_SIZE,
                "page": page,
                "sort": "updated",
                "order": "asc",
            }
        )
        url = f"{GITHUB_API}/search/issues?{params}"
        req = urllib.request.Request(
            url,
            headers={
                "Authorization": f"Bearer {token}",
                "Accept": "application/vnd.github+json",
                "X-GitHub-Api-Version": "2022-11-28",
                "User-Agent": "obi-github-ticket-digest",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT_SECONDS) as resp:
                payload = json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace")
            logger.error("GitHub API error %s on page %s: %s", exc.code, page, body)
            raise
        page_items = payload.get("items", [])
        items.extend(page_items)
        total = payload.get("total_count", 0)
        logger.info(
            "GitHub search page %s: got %s items (total_count=%s, accumulated=%s)",
            page,
            len(page_items),
            total,
            len(items),
        )
        if len(page_items) < GITHUB_SEARCH_PAGE_SIZE:
            break
    return items


def _github_graphql(query: str, variables: Dict[str, Any], token: str) -> Dict[str, Any]:
    """Execute a GitHub GraphQL request and return the parsed JSON."""
    req = urllib.request.Request(
        GITHUB_GRAPHQL_API,
        data=json.dumps({"query": query, "variables": variables}).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "User-Agent": "obi-github-ticket-digest",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT_SECONDS) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        logger.error("GitHub GraphQL error %s: %s", exc.code, body)
        raise
    if "errors" in payload:
        raise RuntimeError(f"GitHub GraphQL errors: {json.dumps(payload['errors'])}")
    return payload["data"]


_PROJECT_STATUS_QUERY_TEMPLATE = """
query({args}) {{
  {fields}
}}
"""

_PROJECT_STATUS_NODE_FRAGMENT = """
  i{idx}: node(id: $id{idx}) {{
    ... on Issue {{
      projectItems(first: 20) {{
        nodes {{
          project {{ number }}
          status: fieldValueByName(name: "Status") {{
            ... on ProjectV2ItemFieldSingleSelectValue {{ name }}
          }}
        }}
      }}
    }}
  }}
"""

GITHUB_STATUS_BATCH_SIZE = 20


def _parse_ts(value: Optional[str]) -> Optional[datetime]:
    """Parse a GitHub ISO-8601 UTC timestamp, or None if absent/invalid."""
    if not value:
        return None
    try:
        return datetime.strptime(value, "%Y-%m-%dT%H:%M:%SZ").replace(
            tzinfo=timezone.utc
        )
    except ValueError:
        return None


def _is_stale(updated_at: Optional[str], cutoff: datetime) -> bool:
    dt = _parse_ts(updated_at)
    return dt is not None and dt < cutoff


def fetch_project_statuses(
    token: str,
    node_ids: List[str],
    project_number: int,
) -> Dict[str, Optional[str]]:
    """Return {issue_node_id: status_name_on_project} for the given issues.

    For each issue we look at its project items, pick the one belonging to
    ``project_number``, and read its "Status" single-select value. An issue
    not on the project (or with no status set) maps to ``None``. Issues are
    looked up in batches of aliased ``node(id:)`` queries to minimise calls.
    Requires the token to have the ``read:project`` scope.
    """
    result: Dict[str, Optional[str]] = {}
    ids = [nid for nid in node_ids if nid]
    for start in range(0, len(ids), GITHUB_STATUS_BATCH_SIZE):
        batch = ids[start : start + GITHUB_STATUS_BATCH_SIZE]
        args = ", ".join(f"$id{j}:ID!" for j in range(len(batch)))
        fields = "".join(
            _PROJECT_STATUS_NODE_FRAGMENT.format(idx=j) for j in range(len(batch))
        )
        query = _PROJECT_STATUS_QUERY_TEMPLATE.format(args=args, fields=fields)
        variables = {f"id{j}": nid for j, nid in enumerate(batch)}
        data = _github_graphql(query, variables, token)
        for j, nid in enumerate(batch):
            node = data.get(f"i{j}") or {}
            status: Optional[str] = None
            for pi in ((node.get("projectItems") or {}).get("nodes") or []):
                if (pi.get("project") or {}).get("number") == project_number:
                    status = (pi.get("status") or {}).get("name")
                    break
            result[nid] = status
        logger.info(
            "Status enrichment: resolved %s/%s issues (batch of %s)",
            len(result),
            len(ids),
            len(batch),
        )
    return result


def fetch_stale_issues(
    token: str,
    org: str,
    stale_days: int,
    include_prs: bool,
    labels: Optional[List[str]] = None,
    assignees: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """Collect open, stale issues (and optionally PRs) across the org.

    If ``labels`` is given, only items carrying all of those labels are
    returned (GitHub ANDs multiple ``label:`` qualifiers). If ``assignees``
    is given, only items assigned to all of those logins are returned.
    """
    cutoff = datetime.now(timezone.utc) - timedelta(days=stale_days)
    cutoff_day = cutoff.strftime("%Y-%m-%d")

    query = f"org:{org} state:open updated:<{cutoff_day}"
    if not include_prs:
        query += " is:issue"
    for label in labels or []:
        label = label.strip()
        if label:
            query += f' label:"{label}"'
    for assignee in assignees or []:
        assignee = assignee.strip()
        if assignee:
            query += f" assignee:{assignee}"

    logger.info("GitHub search query: %s", query)
    raw_items = _github_search_issues(query, token)

    issues: List[Dict[str, Any]] = []
    for item in raw_items:
        if not isinstance(item, dict):
            continue
        is_pr = "pull_request" in item
        if is_pr and not include_prs:
            continue
        html_url = item.get("html_url", "")
        repo_full = ""
        repo_url = item.get("repository_url", "")
        if repo_url:
            repo_full = "/".join(repo_url.split("/")[-2:])
        issues.append(
            {
                "repository": repo_full,
                "number": item.get("number"),
                "title": item.get("title", "").strip(),
                "url": html_url,
                "updated_at": item.get("updated_at"),
                "is_pr": is_pr,
                "node_id": item.get("node_id"),
                "assignees": [
                    a.get("login")
                    for a in (item.get("assignees") or [])
                    if isinstance(a, dict) and a.get("login")
                ],
                "labels": [
                    lb.get("name")
                    for lb in (item.get("labels") or [])
                    if isinstance(lb, dict) and lb.get("name")
                ],
            }
        )

    issues.sort(key=lambda c: c.get("updated_at") or "")
    return {
        "org": org,
        "stale_days": stale_days,
        "cutoff": cutoff.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "include_prs": include_prs,
        "labels": labels or [],
        "issues": issues,
    }


def fetch_stale_issues_from_project(
    token: str,
    org: str,
    project_number: int,
    stale_days: int,
    include_prs: bool,
    labels: Optional[List[str]] = None,
    assignees: Optional[List[str]] = None,
    exclude_statuses: Optional[List[str]] = None,
    include_statuses: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """Stale digest scoped to a Projects v2 board.

    Runs the REST issue search, enriches those candidates with their board
    ``Status`` for ``project_number`` via batched GraphQL, then filters by
    status: if ``include_statuses`` is given, only those statuses are kept;
    ``exclude_statuses`` drops matching statuses. Requires the token to have
    ``repo`` and ``read:project`` scopes. Returns the same payload shape as
    :func:`fetch_stale_issues`, with each issue annotated with its ``status``.
    """
    drop_statuses = {s.strip() for s in (exclude_statuses or []) if s.strip()}
    status_order = [s.strip() for s in (include_statuses or []) if s.strip()]
    keep_statuses = set(status_order)

    base = fetch_stale_issues(
        token, org, stale_days, include_prs, labels, assignees
    )
    candidates = base["issues"]

    node_ids = [c.get("node_id") for c in candidates if c.get("node_id")]
    statuses = fetch_project_statuses(token, node_ids, project_number)

    kept: List[Dict[str, Any]] = []
    excluded = 0
    for c in candidates:
        status = statuses.get(c.get("node_id"))
        c["status"] = status
        if keep_statuses and status not in keep_statuses:
            excluded += 1
            continue
        if status in drop_statuses:
            excluded += 1
            continue
        kept.append(c)

    logger.info(
        "Project #%s digest: %s candidate(s), excluded %s by status, kept %s.",
        project_number,
        len(candidates),
        excluded,
        len(kept),
    )

    base["issues"] = kept
    base["project_number"] = project_number
    base["exclude_statuses"] = sorted(drop_statuses)
    base["include_statuses"] = sorted(keep_statuses)
    base["status_order"] = status_order
    return base


def _sanitize_markdown(text: str) -> str:
    """Render issue titles as literal text in Teams markdown.

    Removes backticks (which Teams turns into code spans) and escapes other
    markdown-active characters so titles like ``m5_xlarge`` or ``*note*`` are
    not italicised/bolded or turned into links.
    """
    text = text.replace("`", "")
    for ch in ("\\", "*", "_", "[", "]"):
        text = text.replace(ch, "\\" + ch)
    return text


def _days_since(updated_at: Optional[str]) -> Optional[int]:
    dt = _parse_ts(updated_at)
    if dt is None:
        return None
    return (datetime.now(timezone.utc) - dt).days


def build_adaptive_card(digest: Dict[str, Any], max_items: int) -> Dict[str, Any]:
    """Build a Teams Adaptive Card payload from the digest."""
    issues: List[Dict[str, Any]] = digest["issues"]
    org = digest["org"]
    stale_days = digest["stale_days"]
    total = len(issues)

    body: List[Dict[str, Any]] = [
        {
            "type": "TextBlock",
            "size": "Large",
            "weight": "Bolder",
            "text": f"Weekly stale ticket digest — {org}",
            "wrap": True,
        },
        {
            "type": "TextBlock",
            "isSubtle": True,
            "spacing": "None",
            "text": (
                f"{total} open item(s) with no update in the last "
                f"{stale_days} day(s)."
            ),
            "wrap": True,
        },
    ]

    if total == 0:
        body.append(
            {"type": "TextBlock", "text": "No stale tickets. 🎉", "wrap": True}
        )
        return _wrap_card(body)

    shown = issues[:max_items]

    def item_blocks(item: Dict[str, Any]) -> List[Dict[str, Any]]:
        days = _days_since(item.get("updated_at"))
        age = f"{days}d" if days is not None else "age unknown"
        assignees = item.get("assignees") or []
        who = ", ".join(assignees) if assignees else "unassigned"
        title = _sanitize_markdown(item.get("title") or "(no title)")
        url = item.get("url") or ""
        repo = item.get("repository") or ""
        short_repo = repo.split("/")[-1] if repo else repo
        number = item.get("number")
        ref = f"{short_repo}#{number}" if short_repo else f"#{number}"
        link = f"[{ref}]({url})" if url else ref
        meta = " · ".join(p for p in (link, age, who) if p)
        return [
            {
                "type": "TextBlock",
                "spacing": "Small",
                "text": title,
                "wrap": True,
            },
            {
                "type": "TextBlock",
                "spacing": "None",
                "isSubtle": True,
                "text": meta,
                "wrap": True,
            },
        ]

    # Group by board status, in the configured order; any leftover statuses
    # (shouldn't occur with an allow-list) fall into a trailing group.
    status_order: List[str] = digest.get("status_order") or []
    if status_order:
        groups: List[tuple] = [(s, [i for i in shown if i.get("status") == s]) for s in status_order]
        leftover = [i for i in shown if i.get("status") not in set(status_order)]
        if leftover:
            groups.append(("Other", leftover))
        for name, items in groups:
            if not items:
                continue
            body.append(
                {
                    "type": "TextBlock",
                    "spacing": "Large",
                    "separator": True,
                    "size": "Large",
                    "weight": "Bolder",
                    "color": "Accent",
                    "text": f"{name} ({len(items)})",
                    "wrap": True,
                }
            )
            for item in items:
                body.extend(item_blocks(item))
    else:
        for item in shown:
            body.extend(item_blocks(item))

    if total > len(shown):
        body.append(
            {
                "type": "TextBlock",
                "spacing": "Medium",
                "isSubtle": True,
                "text": f"… and {total - len(shown)} more.",
                "wrap": True,
            }
        )

    return _wrap_card(body)


def _wrap_card(body: List[Dict[str, Any]]) -> Dict[str, Any]:
    return {
        "type": "message",
        "attachments": [
            {
                "contentType": "application/vnd.microsoft.card.adaptive",
                "contentUrl": None,
                "content": {
                    "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                    "type": "AdaptiveCard",
                    "version": "1.5",
                    "msteams": {"width": "Full"},
                    "body": body,
                },
            }
        ],
    }


def send_to_teams(payload: Dict[str, Any], webhook_url: str) -> None:
    """Post an Adaptive Card payload to a Teams Power Automate webhook."""
    req = urllib.request.Request(
        webhook_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT_SECONDS) as resp:
            logger.info("Digest sent to Teams, response code: %s", resp.getcode())
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        logger.error("Failed to post to Teams (%s): %s", exc.code, body)
        raise
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to post to Teams: %s", exc, exc_info=True)
        raise


def _env_int(name: str, default: int) -> int:
    raw = os.environ.get(name)
    if raw is None or not raw.strip():
        return default
    try:
        return int(raw)
    except ValueError:
        logger.warning("Invalid int for %s=%r, using default %s", name, raw, default)
        return default


def _env_bool(name: str, default: bool) -> bool:
    raw = os.environ.get(name)
    if raw is None or not raw.strip():
        return default
    return raw.strip().lower() in ("1", "true", "yes", "on")


def handler(event: Dict[str, Any], _context: Any) -> Dict[str, Any]:
    """Lambda entry point."""
    logger.info("Received event: %s", json.dumps(event) if event else "{}")
    try:
        org = os.environ.get("GITHUB_ORG", "openbraininstitute").strip() or (
            "openbraininstitute"
        )
        stale_days = _env_int("STALE_DAYS", 7)
        include_prs = _env_bool("INCLUDE_PRS", False)
        max_items = _env_int("MAX_ITEMS", 100)
        project_number = _env_int("GITHUB_PROJECT_NUMBER", 0)
        labels = [
            lb.strip()
            for lb in os.environ.get("GITHUB_LABELS", "").split(",")
            if lb.strip()
        ]
        assignees = [
            a.strip()
            for a in os.environ.get("GITHUB_ASSIGNEES", "").split(",")
            if a.strip()
        ]
        exclude_statuses = [
            s.strip()
            for s in os.environ.get("GITHUB_EXCLUDE_STATUSES", "").split(",")
            if s.strip()
        ]
        include_statuses = [
            s.strip()
            for s in os.environ.get("GITHUB_INCLUDE_STATUSES", "").split(",")
            if s.strip()
        ]

        github_token = _get_secret_by_name_and_key(
            "GITHUB_TOKEN_SECRET_ID", "GITHUB_TOKEN_SECRET_KEY"
        )
        webhook_url = _get_secret_by_name_and_key(
            "TEAMS_WEBHOOK_SECRET_ID", "TEAMS_WEBHOOK_SECRET_KEY"
        )

        if project_number > 0:
            logger.info(
                "Sourcing from project #%s (org %s)", project_number, org
            )
            digest = fetch_stale_issues_from_project(
                github_token,
                org,
                project_number,
                stale_days,
                include_prs,
                labels,
                assignees,
                exclude_statuses,
                include_statuses,
            )
        else:
            logger.info("Sourcing from org-wide issue search (org %s)", org)
            digest = fetch_stale_issues(
                github_token, org, stale_days, include_prs, labels, assignees
            )
        logger.info("Found %s stale item(s).", len(digest["issues"]))

        card = build_adaptive_card(digest, max_items)
        send_to_teams(card, webhook_url)

        return {
            "statusCode": 200,
            "body": f"Posted digest with {len(digest['issues'])} stale item(s).",
        }
    except Exception as exc:  # noqa: BLE001
        logger.error("Unhandled error in handler: %s", exc, exc_info=True)
        return {"statusCode": 500, "body": "Failed to produce stale ticket digest."}
