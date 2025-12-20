FROM ubuntu:22.04
COPY . /app
RUN chmod +x /app/src/main.sh
ENTRYPOINT ["/app/src/main.sh"]
