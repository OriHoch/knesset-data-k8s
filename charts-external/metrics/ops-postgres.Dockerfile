FROM gcr.io/uumpa-public/sk8s-google-storage-sync:v0.0.3b

RUN apk add --update --no-cache postgresql

COPY ops-postgres-entrypoint.sh /
COPY ops-postgres-initial-sync.sh /

RUN chmod +x /*.sh

ENTRYPOINT ["/ops-postgres-entrypoint.sh"]
