FROM busybox:musl
ARG PREFIX=.

RUN adduser -D static
USER static
WORKDIR /home/static
RUN if [ ! -d $PREFIX ]; then mkdir -p $PREFIX; fi

COPY --chown=static site/. $PREFIX/

# Run BusyBox httpd
CMD ["busybox", "httpd", "-f", "-v", "-p", "3000"]
