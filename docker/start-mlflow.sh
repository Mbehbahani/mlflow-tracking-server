#!/bin/sh
set -eu

# Allow existing explicit configuration to win.
if [ -z "${BACKEND_S3:-${BACKEND_s3:-}}" ]; then
  MINIO_BUCKET_CANDIDATE="${MINIO_BUCKET:-${MINIO_BUCKET_NAME:-${S3_BUCKET:-}}}"
  if [ -n "$MINIO_BUCKET_CANDIDATE" ]; then
    export BACKEND_S3="s3://${MINIO_BUCKET_CANDIDATE}/"
  fi
fi

# Auto-detect S3-compatible endpoint settings for MinIO.
if [ -z "${MLFLOW_S3_ENDPOINT_URL:-}" ]; then
  MINIO_HOST_CANDIDATE="${MINIO_ENDPOINT:-${MINIO_HOST:-${MINIO_API_HOST:-}}}"
  MINIO_PORT_CANDIDATE="${MINIO_PORT:-${MINIO_API_PORT:-9000}}"
  MINIO_SCHEME_CANDIDATE="${MINIO_SCHEME:-http}"

  if [ -n "$MINIO_HOST_CANDIDATE" ]; then
    case "$MINIO_HOST_CANDIDATE" in
      http://*|https://*)
        export MLFLOW_S3_ENDPOINT_URL="$MINIO_HOST_CANDIDATE"
        ;;
      *)
        export MLFLOW_S3_ENDPOINT_URL="${MINIO_SCHEME_CANDIDATE}://${MINIO_HOST_CANDIDATE}:${MINIO_PORT_CANDIDATE}"
        ;;
    esac
  fi
fi

# Map common MinIO variable names to the AWS-style names boto3 expects.
if [ -z "${AWS_ACCESS_KEY_ID:-}" ] && [ -n "${MINIO_ACCESS_KEY:-${MINIO_ROOT_USER:-}}" ]; then
  export AWS_ACCESS_KEY_ID="${MINIO_ACCESS_KEY:-${MINIO_ROOT_USER:-}}"
fi

if [ -z "${AWS_SECRET_ACCESS_KEY:-}" ] && [ -n "${MINIO_SECRET_KEY:-${MINIO_ROOT_PASSWORD:-}}" ]; then
  export AWS_SECRET_ACCESS_KEY="${MINIO_SECRET_KEY:-${MINIO_ROOT_PASSWORD:-}}"
fi

# MinIO usually works with us-east-1 if no region is set.
if [ -z "${AWS_DEFAULT_REGION:-}" ] && [ -n "${MLFLOW_S3_ENDPOINT_URL:-}" ]; then
  export AWS_DEFAULT_REGION="${MINIO_REGION:-us-east-1}"
fi

exec mlflow server \
  --host "${MLFLOW_HOST:-0.0.0.0}" \
  --port "${MLFLOW_PORT:-8080}" \
  --backend-store-uri "$BACKEND_STORE_URI" \
  --default-artifact-root "${BACKEND_S3:-${BACKEND_s3:-/app/mlruns}}" \
  --allowed-hosts "*" \
  --cors-allowed-origins "*"