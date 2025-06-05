import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_redirect(event, context):
    logger.info(f"Received event: {json.dumps(event)}")
    # Extract request path
    path = event.get("requestContext", {}).get("http", {}).get("path", "/")
    logger.info(f"Request path: {path}")

    # Define redirect rules
    redirect_map = {
        "/doi/metabolism_shichkova_2025": "/jupyterhub_metabolism/hub/user-redirect/git-pull?repo=https%3A%2F%2Fgithub.com%2Fopenbraininstitute%2Fobi_platform_analysis_notebooks&urlpath=lab%2Ftree%2Fobi_platform_analysis_notebooks%2FMetabolism%2Fanalysis_notebook.ipynb&branch=main"
    }

    # Default: Polina'as notebook for now
    redirect_url = redirect_map.get(path, "/jupyterhub_metabolism/hub/user-redirect/git-pull?repo=https%3A%2F%2Fgithub.com%2Fopenbraininstitute%2Fobi_platform_analysis_notebooks&urlpath=lab%2Ftree%2Fobi_platform_analysis_notebooks%2FMetabolism%2Fanalysis_notebook.ipynb&branch=main")

    return {
        "statusCode": 302,
        "headers": {
            "Location": redirect_url
        }
    }

