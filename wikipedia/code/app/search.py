import os
import time

from dotenv import load_dotenv

from flask import Flask, request, Response, render_template

from elasticsearch import Elasticsearch

from sentence_transformers import SentenceTransformer

load_dotenv()


class Search:
    TORCH_DEVICE = os.getenv("TORCH_DEVICE", "cpu")

    def __init__(self, client):
        self.client = client

        _models = {
            "e5-small": "intfloat/multilingual-e5-small",
            "e5-base": "intfloat/multilingual-e5-base",
            "e5-large": "intfloat/multilingual-e5-large",
            "minilm": "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
        }

        self.config = {}
        for name, model_id in _models.items():
            suffix = name.split("-")[-1]
            self.config[name] = {
                "model_name": model_id,
                "index_name": f"wikipedia-search-{suffix}",
                "model": SentenceTransformer(model_id, device=self.TORCH_DEVICE),
            }

    def _get_model(self, model_name):
        return self.config[model_name]["model"]

    def _get_index_name(self, model_name):
        return self.config[model_name]["index_name"]

    def search_lexical(self, query, model_name, size=100):
        print(model_name)
        return self.client.search(
            index=self._get_index_name(model_name),
            query={
                "nested": {
                    "path": "parts",
                    "query": {
                        "match": {
                            "parts.chunk": query,
                        },
                    },
                    "inner_hits": {
                        "_source": False,
                        "fields": ["parts.chunk"],
                        "size": 5,
                    },
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
            knn={
                "field": "parts.embedding",
                "query_vector": self._get_model(model_name).encode(query),
                "k": size,
                "num_candidates": 1000,
                "inner_hits": {
                    "_source": False,
                    "fields": ["parts.chunk"],
                    "size": 5,  # https://github.com/elastic/elasticsearch/pull/104006
                },
            },
            size=size,
            sort=["_score", "_doc"],
            _source_excludes=["parts"],
        )


es = Elasticsearch(
    hosts=os.getenv("ELASTICSEARCH_URL"),
    basic_auth=(
        os.getenv("ELASTICSEARCH_USER", None),
        os.getenv("ELASTICSEARCH_PASSWORD", None),
    )
    if os.getenv("ELASTICSEARCH_USER")
    else None,
)
search = Search(es)


app = Flask(__name__, template_folder=".")


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
        model_names=search.config.keys(),
        total=total,
        took=took,
        req_d=req_d,
    )


@app.route("/status", methods=["GET"])
def status():
    return Response("OK", mimetype="text/plain")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
