"""Parse articles and upload them on Elastic Search."""

from __future__ import annotations

import asyncio
import hashlib
import json
import logging
import pathlib
import time
from contextlib import AsyncExitStack
from datetime import datetime, timedelta
from typing import Any, Optional

import httpx
import pydantic
from aiobotocore.session import get_session
from airflow import DAG
from airflow.models import Variable
from airflow.operators.python import PythonOperator
from botocore import UNSIGNED
from botocore.config import Config
from elasticsearch import ApiError
from elasticsearch.helpers import BulkIndexError as ESBulkIndexError
from opensearchpy.exceptions import TransportError
from opensearchpy.helpers import BulkIndexError as OSBulkIndexError
from httpx import AsyncClient, HTTPError
from opensearchpy import AsyncOpenSearch as AsyncOpensearch
from opensearchpy.helpers import async_bulk
from pydantic import BaseModel, ConfigDict, SecretStr, model_validator

# setup logging
logger = logging.getLogger("parse_and_upload")
logging.basicConfig(
    format="[%(levelname)s]  %(asctime)s %(name)s  %(message)s", level=logging.INFO
)

SETTINGS: dict[str, Any] = {
    "number_of_shards": 4,
    "number_of_replicas": 0,
    "index.knn": "true",
}

MAPPINGS_PARAGRAPHS: dict[str, Any] = {
    "dynamic": "true",
    "properties": {
        "article_id": {"type": "keyword"},
        "doi": {"type": "keyword"},
        "pmc_id": {"type": "keyword"},
        "pubmed_id": {"type": "keyword"},
        "arxiv_id": {"type": "keyword"},
        "title": {"type": "text"},
        "authors": {"type": "keyword"},
        "journal": {"type": "keyword"},
        "date": {"type": "date", "format": "yyyy-MM-dd"},
        "paragraph_id": {"type": "short"},
        "text": {"type": "text"},
        "article_type": {"type": "keyword"},
        "embed_multi-qa-mpnet-base-dot-v1:1_0_0": {
            "type": "knn_vector",
            "dimension": 768,
            "method": {
                "name": "hnsw",
                "engine": "nmslib",
                "space_type": "cosinesimil",
                "parameters": {},
            },
        },
        "section": {"type": "keyword"},
    },
}


class AsyncOpenSearch(BaseModel):
    """Class to use async Opensearch as document store."""

    host: str
    port: int
    user: Optional[str] = None
    password: Optional[SecretStr] = None
    use_ssl_and_verify_certs: Optional[bool] = None
    client: AsyncOpensearch

    model_config = ConfigDict(arbitrary_types_allowed=True)

    @model_validator(mode="before")
    def connect_to_ds(cls, values: dict[str, Any]) -> dict[str, Any]:
        """Connect to OS."""
        values["use_ssl_and_verify_certs"] = values.get(
            "use_ssl_and_verify_certs", True
        )  # by default we use SSL
        if values.get("user") is None and values.get("password") is None:
            client = AsyncOpensearch(
                hosts=[{"host": values["host"], "port": values["port"]}],
                verify_certs=values["use_ssl_and_verify_certs"],
                use_ssl=values["use_ssl_and_verify_certs"],
                request_timeout=60,
                max_retries=3,
                retry_on_timeout=True,
            )
        else:
            client = AsyncOpensearch(
                hosts=[{"host": values["host"], "port": values["port"]}],
                http_auth=(values["user"], values["password"]),
                verify_certs=values["use_ssl_and_verify_certs"],
                use_ssl=values["use_ssl_and_verify_certs"],
                request_timeout=60,
                max_retries=3,
                retry_on_timeout=True,
            )

        values["client"] = client
        return values

    async def get_available_indexes(self) -> list[str]:
        """Return all available indexes."""
        indices = await self.client.indices.get_alias()
        return list(indices.keys())

    async def create_index(
        self,
        index: str,
        settings: Optional[dict[str, Any]],
        mappings: Optional[dict[str, Any]],
    ) -> None:
        """Create a new index."""
        if index in await self.get_available_indexes():
            raise RuntimeError("Index already in OS")
        body = {"settings": settings, "mappings": mappings}
        await self.client.indices.create(index=index, body=body)
        logger.info(f"Index {index} created successfully")

    async def exists(self, index: str, doc_id: str) -> bool:
        """Return True if this document exists in the index.

        Parameters
        ----------
        index
            OS index where documents are stored.
        doc_id
            ID under which the document might be indexed.

        Returns
        -------
            True if the document exists within an index.
        """
        return await self.client.exists(index=index, id=doc_id)

    async def search(
        self,
        index: str,
        query: Optional[dict[str, Any]] = None,
        size: int = 10,
        aggs: Optional[dict[str, Any]] = None,
        **kwargs: Any,
    ) -> dict[str, Any]:
        """Wrap around the search api."""
        body = None
        if query is not None:
            if "query" not in query.keys():
                body = {"query": query}
            else:
                body = query
        if aggs is not None:
            if body is not None:
                body["aggs"] = aggs
            else:
                body = {"aggs": aggs}
        return await self.client.search(index=index, body=body, size=size, **kwargs)

    async def bulk(self, actions: list[dict[str, Any]], **kwargs: Any) -> None:
        """Bulk upload of documents."""
        await async_bulk(client=self.client, actions=actions, **kwargs)
        logger.info("Successfully updated documents in bulk")

    async def close(self) -> None:
        """Close the aiohttp session."""
        await self.client.close()


async def check_docs_exists_in_db(
    client: AsyncOpenSearch, index: str, pmc_ids: list[str]
):
    """Return list of index of documents .

    Parameters
    ----------
    client
        Async Opensearch client.
    index
        OS index where documents are stored.
    pmc_ids
        PMC IDs of the documents.

    Returns
    -------
        True if the document exists within an index.
    """
    query = {
        "size": 0,
        "query": {"terms": {"pmc_id": pmc_ids}},
        "aggs": {"matched_ids": {"terms": {"field": "pmc_id", "size": len(pmc_ids)}}},
    }
    docs = await client.search(index=index, query=query, **{"request_timeout": 60})
    existing_ids = [
        doc["key"] for doc in docs["aggregations"]["matched_ids"]["buckets"]
    ]
    return existing_ids


async def parent_async(
    files_content: list[bytes],
    s3_bucket_keys: list[pathlib.Path],
    url: str,
    multipart_params: dict[str, Any] | None = None,
    timeout: int | None = None,
    ignore_errors: bool = False,
    max_concurrent_requests: int | None = None,
    httpx_client: httpx.AsyncClient | None = None,
) -> (
    list[list[float]]  # Embedding
    | list[dict[str, str | list[str] | None] | None]  # ETL
    | list[list[int | float]]  # Question Answering Reranker
):
    """Batch the body and calls asynchronously the specified API.

    Parameters
    ----------
    files_content
        Content of the files to send to the parser.
    s3_bucket_keys
        Keys of the files.
    url
        URL of the target API.
    multipart_params
        Optional parameters to go along with the file. NOT QUERY PARAMETERS.
    timeout
        Sets global timeout for http requests.
    ignore_errors
        Controls whether the code should raise an exception and stop upon having a non 2xx status code. Can be True for ETL only so far.
    max_concurrent_requests
        Maximum number of requests that can be sent simultaneously to the server.
    httpx_client
        Async HTTPx Client.

    Returns
    -------
    answers: list[list[float]] | list[dict[str, str | list[str] | None] | None] | list[list[int | float]]
        Output of the requests.

    """
    # Define the client and call the child function
    if max_concurrent_requests is not None:
        semaphore = asyncio.Semaphore(max_concurrent_requests)
    else:
        semaphore = None

    if httpx_client is None:
        transport = httpx.AsyncHTTPTransport(retries=6)

        async with httpx.AsyncClient(
            timeout=timeout, transport=transport
        ) as http_client:
            tasks = [
                asyncio.create_task(
                    child_async(
                        http_client,
                        url,
                        s3_bucket_key,
                        file_content,
                        multipart_params,
                        semaphore,
                    )
                )
                for s3_bucket_key, file_content in zip(s3_bucket_keys, files_content)
            ]
            res = await asyncio.gather(*tasks, return_exceptions=ignore_errors)
    else:
        tasks = [
            asyncio.create_task(
                child_async(
                    httpx_client,
                    url,
                    s3_bucket_key,
                    file_content,
                    multipart_params,
                    semaphore,
                )
            )
            for s3_bucket_key, file_content in zip(s3_bucket_keys, files_content)
        ]
        res = await asyncio.gather(*tasks, return_exceptions=ignore_errors)

    res = [
        (
            response.json()
            if isinstance(response, httpx.Response) and response.status_code // 100 == 2
            else None
        )
        for response in res
    ]

    return res


async def child_async(
    http_client: httpx.AsyncClient,
    url: str,
    s3_bucket_key: pathlib.Path,
    file_content: bytes,
    multipart_params: dict[str, Any] | None = None,
    semaphore: asyncio.Semaphore | None = None,
) -> Any:
    """Call the specified API and returns the answer.

    Parameters
    ----------
    http_client
        Client to use to send the requests.
    url
        URL of the target API.
    s3_bucket_key
        Key of the S3 bucket.
    file_content
        File content.
    multipart_params
        Optional parameters to go along with the file. NOT QUERY PARAMETERS.
    semaphore
        asyncio.Semaphore class used to limit the number of simultaneously outgoing requests.

    Returns
    -------
    answers: Any
        Output of the request.

    """
    async with semaphore if semaphore is not None else AsyncExitStack():  # type: ignore
        try:
            files = [("inp", (s3_bucket_key.name, file_content))]
            data = {"parameters": json.dumps(multipart_params)}
            logging.debug(f"Sending request for file {s3_bucket_key.stem}")
            result = await http_client.post(url, files=files, data=data)
            logging.debug(
                f"Received request for file {s3_bucket_key}. response code:"
                f" {result.status_code}"
            )
            result.raise_for_status()
        except HTTPError as err:
            raise HTTPError(
                f"The status code is {result.status_code}, the body is {file_content}"
            ) from err
    return result


class ParsingService(pydantic.BaseModel):
    """Class to parse files.

    Parameters
    ----------
    ignore_errors
        Controls whether the code should raise an exception and stop upon having a request with non 2xx status code.
    max_concurrent_requests
        Maximum number of requests that can be sent simultaneously to the server.
    """

    url: Optional[pydantic.AnyHttpUrl] = None
    client: Optional[Any] = None
    max_concurrent_requests: Optional[int] = None
    ignore_errors: bool = True

    async def arun(
        self,
        files: list[bytes],
        s3_bucket_keys: list[pathlib.Path],
        multipart_params: Optional[dict[str, Any]] = None,
        httpx_client: Optional[AsyncClient] = None,
    ) -> list[dict[str, Any]]:
        """Parse one or multiple files.

        Parameters
        ----------
        files
            Files to parse.
        s3_bucket_keys
            Keys of the different files coming from S3 bucket.
        multipart_params
            Optional request parameters to go along with the file. NOT QUERY PARAMETERS.
        httpx_client
            Async HTTP Client (Optional)

        Returns
        -------
        list
            Parsing of the files.
        """
        logger.info(f"Parsing {len(files)} texts with client side batch size of 1")
        # create payload
        parsed = await parent_async(
            files_content=files,
            s3_bucket_keys=s3_bucket_keys,
            url=str(self.url),
            multipart_params=multipart_params,
            ignore_errors=self.ignore_errors,
            max_concurrent_requests=self.max_concurrent_requests,
            httpx_client=httpx_client,
        )

        return parsed  # type: ignore


async def parse_and_upload(
    start_date: datetime,
    max_concurrent_requests: int = 10,
    index: str = "paragraphs",
    batch_size: int = 500,
) -> int:
    """Run the article parsing and upload results on ES."""
    # Setup document store.
    db_url = Variable.get("db_url")
    host, _, port = db_url.rpartition(":")
    ds_client = AsyncOpenSearch(host=host, port=int(port))  # type: ignore

    if index not in await ds_client.get_available_indexes():
        await ds_client.create_index(
            index,
            settings=SETTINGS,
            mappings=MAPPINGS_PARAGRAPHS,
        )

    # Setup parsing service
    parsing_url = Variable.get("parsing_url")
    parsing_service = ParsingService(
        url=parsing_url,
        ignore_errors=True,
        max_concurrent_requests=max_concurrent_requests,
    )

    # Setup s3 bucket
    logger.info("Starting S3 client.")
    session = get_session()
    start_time = time.time()

    for prefix in [
        "oa_comm/xml/all/",
        "oa_noncomm/xml/all/",
        "author_manuscript/xml/all/",
    ]:
        async with session.create_client(
            "s3", region_name="us-east-1", config=Config(signature_version=UNSIGNED)
        ) as client:
            s3_paginator = client.get_paginator("list_objects_v2")
            s3_iterator = s3_paginator.paginate(Bucket="pmc-oa-opendata", Prefix=prefix)
            logger.info("Filtering interesting articles.")
            filtered_iterator = s3_iterator.search(
                f"""Contents[?to_string(LastModified)>='\"{start_date.strftime('%Y-%m-%d %H:%M:%S%')}+00:00\"'
                    && contains(Key, '.xml')]"""
            )
            finished = False
            while not finished:
                start_time_batch = time.time()

                s3_bucket_dict = {}
                i = 0
                # Creating batches.
                async for obj in filtered_iterator:
                    i += 1
                    s3_bucket_key = pathlib.Path(obj["Key"])
                    s3_bucket_dict[s3_bucket_key.stem] = s3_bucket_key
                    if i == batch_size:
                        break

                if i != batch_size:
                    finished = True

                all_pmc_ids = list(s3_bucket_dict.keys())
                existing_files = await check_docs_exists_in_db(
                    ds_client, index, all_pmc_ids
                )

                s3_bucket_keys = [
                    v for k, v in s3_bucket_dict.items() if k not in existing_files
                ]

                logger.info("Get objects.")
                files = []
                for s3_bucket_key in s3_bucket_keys:
                    response = await client.get_object(
                        Bucket="pmc-oa-opendata", Key=str(s3_bucket_key)
                    )
                    body = await response["Body"].read()
                    files.append(body)

                logger.info(f"Request server to parse {len(s3_bucket_keys)} documents.")
                results = await parsing_service.arun(
                    files=files,
                    s3_bucket_keys=s3_bucket_keys,
                )
                logger.info("Collecting data to upload to the document store.")
                upload_bulk = []
                for s3_bucket_key, res in zip(s3_bucket_keys, results):
                    if res is None:
                        logging.error(f"File {s3_bucket_key} failed to be parsed.")
                        continue
                    try:
                        for i, abstract in enumerate(res["abstract"]):
                            doc_id = hashlib.md5(
                                (res["uid"] + abstract).encode("utf-8"),
                                usedforsecurity=False,
                            ).hexdigest()

                            par = {
                                "_index": index,
                                "_id": doc_id,
                                "_source": {
                                    "article_id": res["uid"],
                                    "section": "Abstract",
                                    "text": abstract,
                                    "paragraph_id": i,
                                    "authors": res["authors"],
                                    "title": res["title"],
                                    "pubmed_id": res["pubmed_id"],
                                    "pmc_id": res["pmc_id"],
                                    "arxiv_id": res["arxiv_id"],
                                    "doi": res["doi"],
                                    "date": res["date"],
                                    "journal": res["journal"],
                                    "article_type": res["article_type"],
                                },
                            }
                            if len(par) > 0:
                                upload_bulk.append(par)

                        for ppos, (section, text) in enumerate(
                            res["section_paragraphs"]
                        ):
                            doc_id = hashlib.md5(
                                (res["uid"] + text).encode("utf-8"),
                                usedforsecurity=False,
                            ).hexdigest()

                            par = {
                                "_index": index,
                                "_id": doc_id,
                                "_source": {
                                    "article_id": res["uid"],
                                    "section": section,
                                    "text": text,
                                    "paragraph_id": ppos + len(res["abstract"]),
                                    "authors": res["authors"],
                                    "title": res["title"],
                                    "pubmed_id": res["pubmed_id"],
                                    "pmc_id": res["pmc_id"],
                                    "arxiv_id": res["arxiv_id"],
                                    "doi": res["doi"],
                                    "date": res["date"],
                                    "journal": res["journal"],
                                    "article_type": res["article_type"],
                                },
                            }
                            if len(par) > 0:
                                upload_bulk.append(par)
                    except TypeError as e:
                        logger.error(
                            f"Article {s3_bucket_key} could not be parsed properly. {e}"
                        )
                        continue

                logger.info("Upload data to database.")
                try:
                    await ds_client.bulk(upload_bulk, **{"request_timeout": 60})
                except (ApiError, ESBulkIndexError, TransportError, OSBulkIndexError) as e:
                    logger.info(
                        f"Article {s3_bucket_key} could not be uploaded properly. {e}"
                    )
                logger.info(
                    f"From start took: {time.time() - start_time}. Batch took: {time.time() - start_time_batch}"
                )

    logger.info("Done.")

    return 0


def run_parse_and_upload(**kwargs):
    """Run parse and upload."""
    return asyncio.run(
        parse_and_upload(
            start_date=kwargs["start_date"],
            max_concurrent_requests=kwargs["max_concurrent_requests"],
            index=kwargs["index"],
            batch_size=kwargs["batch_size"],
        )
    )


with DAG(
    "poc_upload_database_jats_xml",
    default_args={
        "retries": 1,
        "retry_delay": timedelta(minutes=1),
    },
    schedule_interval=timedelta(days=1),
    start_date=datetime(2024, 3, 1),
    catchup=False,
) as dag:

    start_date = Variable.get("start_date", None)
    batch_size = Variable.get("batch_size", 400)
    index = Variable.get("index")

    if start_date is not None:
        start_date = datetime.strptime(start_date, "%d-%m-%Y")
        if start_date > datetime.today():
            raise ValueError(
                "Date is in the future! Hope you found the secret for time travelling."
            )
    else:
        start_date = datetime.today() - timedelta(days=1)

    task0 = PythonOperator(
        task_id="parse_and_upload",
        python_callable=run_parse_and_upload,
        op_kwargs={
            "start_date": start_date,
            "max_concurrent_requests": 1000,
            "index": index,
            "batch_size": int(batch_size),
        },
    )

    task0
