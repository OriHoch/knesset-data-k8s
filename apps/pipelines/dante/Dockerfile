FROM debian:bullseye-slim
RUN apt-get update && \
    apt-get install -y dante-server && \
    rm -rf /var/lib/apt/lists/*
# CMD ["danted", "-f", "/etc/dante.conf"]
