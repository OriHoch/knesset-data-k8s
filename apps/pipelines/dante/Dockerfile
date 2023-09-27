FROM debian:bullseye-slim
RUN apt-get update && \
    apt-get install -y dante-server libpam-pwdfile openssl && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir /etc/dante
COPY dante.conf /etc/dante/dante.conf
COPY entrypoint.sh /entrypoint.sh
EXPOSE 1080
ENTRYPOINT ["/entrypoint.sh"]
