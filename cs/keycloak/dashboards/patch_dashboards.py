#!/usr/bin/env python3
"""
Patches upstream keycloak-grafana-dashboard JSONs for ECS + Amazon Managed Prometheus,
and optionally pushes them to a Grafana workspace.

Changes applied:
  - Remove namespace="$namespace" and container="keycloak" label filters (Kubernetes-specific)
  - Remove ${namespace} variant of the namespace filter
  - Fix leading comma left after label removal: {, foo="bar"} -> {foo="bar"}
  - Replace job=~"${namespace}/keycloak-metrics|keycloak-service" with job="keycloak-metrics"
  - Replace by(pod) groupings with by(instance)
  - Remove the namespace template variable
  - Replace panel datasource uid placeholder with ${DS_PROMETHEUS}
  - Hide panels that use metrics unavailable on ECS (Kubernetes cAdvisor, missing jgroups metrics)

Updating to a new upstream release
-----------------------------------
1. Download the latest dashboards from upstream:

     curl -O https://raw.githubusercontent.com/keycloak/keycloak-grafana-dashboard/main/dashboards/keycloak-capacity-planning-dashboard.json
     curl -O https://raw.githubusercontent.com/keycloak/keycloak-grafana-dashboard/main/dashboards/keycloak-troubleshooting-dashboard.json

2. Patch and push in one step:

     python3 cs/keycloak/dashboards/patch_dashboards.py \\
         keycloak-capacity-planning-dashboard.json \\
         keycloak-troubleshooting-dashboard.json \\
         --push --workspace-id <workspace-id> --profile <aws-profile>

   Or patch only (inspect before pushing):

     python3 cs/keycloak/dashboards/patch_dashboards.py \\
         keycloak-capacity-planning-dashboard.json \\
         keycloak-troubleshooting-dashboard.json

   Then push separately:

     python3 cs/keycloak/dashboards/patch_dashboards.py --push \\
         --workspace-id <workspace-id> --profile <aws-profile>

   The --push flag reads the patched JSONs from this script's directory,
   creates a short-lived service account token, pushes the dashboards,
   then deletes the token.
"""
import argparse, json, re, sys, time
from pathlib import Path

PANELS_TO_HIDE = {
    # Kubernetes cAdvisor metric, not available on ECS
    "KUBERNETES - CPU Usage percentage",
    # vendor_jgroups_stats_sync_requests_seconds_* not exposed by Keycloak on ECS
    "Response Time (99th)",
    "Average Response Time",
}

DASHBOARD_FILES = [
    "keycloak-capacity-planning.json",
    "keycloak-troubleshooting.json",
]

FOLDER_TITLE = "Keycloak"


def patch_expr(expr):
    expr = re.sub(r',?\s*namespace="\$namespace"', '', expr)
    expr = re.sub(r',?\s*namespace="\$\{namespace\}"', '', expr)
    expr = re.sub(r',?\s*container="keycloak"', '', expr)
    expr = re.sub(
        r'job=~"\$\{namespace\}/keycloak-metrics\|keycloak-service"',
        'job="keycloak-metrics"', expr)
    expr = re.sub(r'\bby\s*\(\s*pod\s*\)', 'by(instance)', expr)
    expr = re.sub(r'\bby\s*\(\s*pod\s*,', 'by(instance,', expr)
    expr = re.sub(r'\bby\s*\(pod,', 'by(instance,', expr)
    expr = re.sub(r'\{\s*,\s*', '{', expr)
    return expr


def patch_dashboard(d):
    panels = d.get('panels', [])
    all_panels = list(panels)
    for p in panels:
        all_panels += p.get('panels', [])
    for p in all_panels:
        for t in p.get('targets', []):
            if t.get('expr'):
                t['expr'] = patch_expr(t['expr'])
        if p.get('title') in PANELS_TO_HIDE:
            p['type'] = 'text'
            p['options'] = {'content': f'> Panel not available on ECS: _{p["title"]}_', 'mode': 'markdown'}
            p.pop('targets', None)
            p.pop('fieldConfig', None)

    for v in d.get('templating', {}).get('list', []):
        if v.get('type') == 'query':
            v['datasource'] = {'type': 'prometheus', 'uid': '${DS_PROMETHEUS}'}
    d['templating']['list'] = [
        v for v in d.get('templating', {}).get('list', [])
        if v['name'] != 'namespace'
    ]
    d['__inputs__'] = [{
        "name": "DS_PROMETHEUS",
        "label": "Prometheus",
        "type": "datasource",
        "pluginId": "prometheus",
        "pluginName": "Prometheus"
    }]
    d.pop('id', None)
    d.pop('uid', None)
    return d


def do_patch(inputs, out_dir):
    default_inputs = [
        'keycloak-capacity-planning-dashboard.json',
        'keycloak-troubleshooting-dashboard.json',
    ]
    src_files = inputs if inputs else default_inputs
    for src, dst_name in zip(src_files, DASHBOARD_FILES):
        with open(src) as f:
            d = json.load(f)
        d = patch_dashboard(d)
        dst = out_dir / dst_name
        with open(dst, 'w') as f:
            json.dump(d, f, indent=2)
        print(f"Written {dst}")


def do_push(workspace_id, profile, out_dir, prometheus_uid):
    import boto3
    import urllib.request

    session = boto3.Session(profile_name=profile)
    client = session.client('grafana', region_name='us-east-1')

    workspace_resp = client.describe_workspace(workspaceId=workspace_id)
    endpoint = workspace_resp['workspace']['endpoint']

    key_name = f"patch-dashboards-{int(time.time())}"
    resp = client.create_workspace_api_key(
        keyName=key_name,
        keyRole='ADMIN',
        secondsToLive=300,
        workspaceId=workspace_id,
    )
    token = resp['key']

    base_url = f"https://{endpoint}"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

    def api(method, path, body=None):
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(f"{base_url}{path}", data=data, headers=headers, method=method)
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read())

    try:
        # Get or create folder
        folders = api("GET", "/api/folders")
        folder_uid = next((f['uid'] for f in folders if f['title'] == FOLDER_TITLE), None)
        if not folder_uid:
            folder = api("POST", "/api/folders", {"title": FOLDER_TITLE})
            folder_uid = folder['uid']
            print(f"Created folder '{FOLDER_TITLE}' (uid={folder_uid})")
        else:
            print(f"Using existing folder '{FOLDER_TITLE}' (uid={folder_uid})")

        # Resolve prometheus datasource uid if not provided
        ds_uid = prometheus_uid
        if not ds_uid:
            datasources = api("GET", "/api/datasources")
            prom = next((ds for ds in datasources if ds.get('type') == 'prometheus'), None)
            if not prom:
                print("No Prometheus datasource found", file=sys.stderr)
                sys.exit(1)
            ds_uid = prom['uid']
            print(f"Resolved Prometheus datasource uid: {ds_uid}")

        for fname in DASHBOARD_FILES:
            fpath = out_dir / fname
            with open(fpath) as f:
                dashboard = json.load(f)

            dashboard_str = json.dumps(dashboard).replace('${DS_PROMETHEUS}', ds_uid)
            dashboard = json.loads(dashboard_str)

            payload = {"dashboard": dashboard, "folderUid": folder_uid, "overwrite": True}
            result = api("POST", "/api/dashboards/db", payload)
            print(f"Pushed {fname}: {result.get('status')} → {result.get('url')}")
    finally:
        client.delete_workspace_api_key(keyName=key_name, workspaceId=workspace_id)
        print(f"Deleted API key '{key_name}'")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('inputs', nargs='*', help='Upstream dashboard JSON files to patch')
    parser.add_argument('--push', action='store_true', help='Push patched dashboards to Grafana')
    parser.add_argument('--workspace-id', help='Amazon Managed Grafana workspace ID (required with --push)')
    parser.add_argument('--profile', default='staging-admin', help='AWS profile (default: staging-admin)')
    parser.add_argument('--prometheus-uid', help='Grafana Prometheus datasource UID (auto-detected if omitted)')
    args = parser.parse_args()

    out_dir = Path(__file__).parent

    if args.inputs:
        do_patch(args.inputs, out_dir)

    if args.push:
        if not args.workspace_id:
            parser.error("--workspace-id is required with --push")
        do_push(args.workspace_id, args.profile, out_dir, args.prometheus_uid)
    elif not args.inputs:
        parser.print_help()


if __name__ == '__main__':
    main()
