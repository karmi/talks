import os
import time
import yaml

from dotenv import load_dotenv

from flask import Flask, request, Response, render_template
import werkzeug

import numpy as np

import requests
from elasticsearch import Elasticsearch

load_dotenv()


class InferenceAPIException(Exception):
    pass


class Search:
    def __init__(self, client):
        self.client = client

        with open("config.yml") as f:
            self.config = yaml.safe_load(f)

    def _get_embeddings(self, model_name, query):
        api_url = self.config["models"][model_name]["endpoint"]
        api_token = os.getenv("INFERENCE_API_TOKEN")

        if "e5-instruct" in model_name:
            query = f'Instruct: Given a web search query, retrieve relevant passages that answer the query\nQuery: {query}'
        elif "e5" in model_name:
            query = f"query: {query}"

        response = requests.post(
            api_url,
            headers={"Authorization": f"Bearer {api_token}"} if api_token else {},
            params={"wait_for_model": True},
            json={"inputs": query},
            timeout=300,
        )

        if not response.ok:
            raise InferenceAPIException(response.json()["error"])

        return np.array(response.json()).flatten().tolist()

    def _get_index_name(self, model_name):
        return self.config["models"][model_name]["index_name"]

    def search_lexical(self, query, model_name, size=100):
        return self.client.search(
            index=self._get_index_name(model_name),
            query={
                "bool": {
                    "should": [
                        {
                            "nested": {
                                "path": "parts",
                                "query": {
                                    "match": {
                                        "parts.chunk": query,
                                    },
                                },
                                "inner_hits": {
                                    "_source": {"includes": "parts.chunk"},
                                    "size": 5,
                                },
                            }
                        },
                        # {
                        #     "match": {
                        #         "title": {
                        #             "query": query,
                        #             "operator": "AND",
                        #             "boost": 2.0,
                        #         },
                        #     }
                        # },
                    ],
                },
            },
            size=size,
            sort=["_score", "_doc"],
            _source_excludes=["parts"],
        )

    def search_semantic(self, query, model_name, size=100):
        query = f"query: {query}" if "e5" in model_name else query

        return self.client.search(
            index=self._get_index_name(model_name),
            query={
                "nested": {
                    "path": "parts",
                    "query": {
                        "knn": {
                            "field": "parts.embedding",
                            "query_vector": self._get_embeddings(model_name, query),
                            "num_candidates": 1000,
                        }
                    },
                    "inner_hits": {
                        "_source": {"includes": "parts.chunk"},
                        "size": 5,  # Currently returns only 1. // https://github.com/elastic/elasticsearch/pull/104006
                    },
                }
            },
            size=size,
            sort=["_score", "_doc"],
            _source_excludes=["parts"],
        )


es = Elasticsearch(
    hosts=os.getenv("ELASTICSEARCH_URL"),
    basic_auth=(
        (
            os.getenv("ELASTICSEARCH_USER", None),
            os.getenv("ELASTICSEARCH_PASSWORD", None),
        )
        if os.getenv("ELASTICSEARCH_USER")
        else None
    ),
)
search = Search(es)


app = Flask(__name__, template_folder=".")


@app.errorhandler(Exception)
def handle_exception(e):
    if isinstance(e, werkzeug.exceptions.HTTPException):
        return e
    m = e.__class__.__module__
    c = e.__class__.__name__
    return f"{m}.{c}: {e}", 500


@app.route("/", methods=["GET"])
def index():
    start = time.perf_counter()

    query = request.args.get("q", "")
    search_type = request.args.get("t", "lexical")
    model_name = request.args.get("m", "e5-small")
    duration, took, req_d, total, results = 0, 0, 0, 0, []

    if query:
        if search_type == "semantic":
            response = search.search_semantic(query, model_name, size=50)
        else:
            response = search.search_lexical(query, model_name, size=50)
        # print(response)

        duration = int((time.perf_counter() - start) * 1000)
        took = response["took"]
        req_d = duration - took
        total = response["hits"]["total"]
        results = response["hits"]["hits"]

    return render_template(
        "search.html",
        results=results,
        model_names=search.config["models"].keys(),
        total=total,
        took=took,
        req_d=req_d,
        search_type=search_type,
    )


@app.route("/status", methods=["GET"])
def status():
    return Response("OK", mimetype="text/plain")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
