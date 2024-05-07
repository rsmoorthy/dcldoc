FROM busybox:musl

RUN adduser -D static
USER static
WORKDIR /home/static

COPY --chown=static site/. ./

# Run BusyBox httpd
CMD ["busybox", "httpd", "-f", "-v", "-p", "3000"]
