FROM ghcr.io/mlflow/mlflow:v3.10.1-full

COPY docker/start-mlflow.sh /usr/local/bin/start-mlflow.sh
RUN chmod +x /usr/local/bin/start-mlflow.sh

CMD ["/usr/local/bin/start-mlflow.sh"]

