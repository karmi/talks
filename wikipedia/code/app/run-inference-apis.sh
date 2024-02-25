# Run inference APIs locally with Apple MPS support
#
# https://github.com/huggingface/text-embeddings-inference#local-install
#
# brew install rust
# cd tmp/
# git clone https://github.com/huggingface/text-embeddings-inference.git
# cd text-embeddings-inference/
# cargo install --path router -F candle -F metal

shutdown() {
  echo "Shutting down..."
  for pid in "${PIDS[@]}"; do kill -9 "$pid"; done
  exit 0
}

trap shutdown SIGINT

mkdir -p tmp/log/

PIDS=()
LOG_FILES=(
  "inference_E5-SMALL.log"
  "inference_E5-BASE.log"
  "inference_E5-LARGE.log"
  "inference_E5-INSTRUCT.log"
  "inference_MINILM.log"
)

for f in "${LOG_FILES[@]}"; do touch "tmp/log/${f}"; done

nohup ~/.cargo/bin/text-embeddings-router --huggingface-hub-cache ~/.cache/huggingface/hub --model-id intfloat/multilingual-e5-small --port 5001 --tokenization-workers 2 > tmp/log/${LOG_FILES[0]} 2>&1 &
PIDS+=($!)

nohup ~/.cargo/bin/text-embeddings-router --huggingface-hub-cache ~/.cache/huggingface/hub --model-id intfloat/multilingual-e5-base --port 5002 --tokenization-workers 2 > tmp/log/${LOG_FILES[1]} 2>&1 &
PIDS+=($!)

nohup ~/.cargo/bin/text-embeddings-router --huggingface-hub-cache ~/.cache/huggingface/hub --model-id intfloat/multilingual-e5-large --port 5003 --tokenization-workers 2 > tmp/log/${LOG_FILES[2]} 2>&1 &
PIDS+=($!)

nohup ~/.cargo/bin/text-embeddings-router --huggingface-hub-cache ~/.cache/huggingface/hub --model-id intfloat/multilingual-e5-large-instruct --port 5004 --tokenization-workers 2 > tmp/log/${LOG_FILES[2]} 2>&1 &
PIDS+=($!)

nohup ~/.cargo/bin/text-embeddings-router --huggingface-hub-cache ~/.cache/huggingface/hub --model-id sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2 --port 5005 --tokenization-workers 2 > tmp/log/${LOG_FILES[3]} 2>&1 &
PIDS+=($!)

(tail -f tmp/log/inference_*.log)
