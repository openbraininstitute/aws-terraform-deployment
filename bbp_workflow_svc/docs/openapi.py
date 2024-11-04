import json
from pathlib import Path
from fastapi import FastAPI, Path as PathParam, Query, Cookie, Form, File, Header
from fastapi.responses import PlainTextResponse, RedirectResponse
from typing import Annotated

app = FastAPI()


@app.options("/")
def options() -> None:
    """Sets CORS headers."""
    pass


@app.get("/session", response_model=None, status_code=204, responses={422: {"model": None}})
def session(authorization: Annotated[str, Header(description="Keycloak token.")]) -> None:
    """Starts user bbp-workflow instance(if not already running) and sets session cookie.

    Should be the first endpoint invoked by UI to establish session."""
    pass


@app.get("/auth", response_class=RedirectResponse, status_code=204,
         responses={422: {"model": None},
                    503: {"description": "Service not ready, retry."}})
def auth(url: Annotated[str, Query(description="This endpoint might redircet to keycloak for authentication if "
                                               "there is no SSO session, else redirect to this query param URL.")],
         sessionid: Annotated[str, Cookie(description="Session id cookie.")]) -> None:
    """Ensures token is present for the workflow.

    Should be the second endpoint invoked by UI to make sure bbp-workflow service
    is healthy and contains valid token. When invoked, should include credentials(session cookie).

    If service is not yet available, return status code: 503 with retry-after header."""
    return None


@app.post("/launch/{task}/", response_class=PlainTextResponse, status_code=201,
          responses={422: {"model": None},
                     201: {"description": "WorkflowExecution URL",
                           "content": {
                               "text/plain": {
                                   "examples": {
                                       "WorkflowExecution": {"value": "https://host/path/workflow-execution-resource-id"}}}}}})
def launch(task: Annotated[str, PathParam(description="Fully qualified name of the luigi task(e.g. package.module.TaskClass).")],
           virtual_lab: Annotated[str, Query(description="Virtual lab id.")],
           project: Annotated[str, Query(description="Project id.")],
           sessionid: Annotated[str, Cookie(description="Session id cookie.")],
           cfg_name: Annotated[str, Form(description="Configuration file name from the attached form files.")],
           files: Annotated[list[bytes], File(description="Attached form files required by the workflow.")]) -> None:
    """Launches workflow."""
    pass


@app.get("/{proxy+}", responses={422: {"model": None}})
def default() -> None:
    """Forwards to user bbp-workflow instance."""
    pass


if __name__ == "__main__":
    Path(__file__).with_suffix(".json").write_text(json.dumps(app.openapi(), indent=4))
