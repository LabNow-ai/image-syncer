FROM golang:latest AS builder
WORKDIR /work
COPY ./src/image-syncer ./src/image-syncer
# ENV GOPROXY=https://proxy.golang.com.cn,direct
RUN cd src/image-syncer && CGO_ENABLED=0 GOOS=linux go build -o /image-syncer .

FROM alpine:latest
WORKDIR /bin/
COPY --from=builder /image-syncer ./
RUN chmod +x ./image-syncer
RUN apk add -U --no-cache ca-certificates && rm -rf /var/cache/apk/* && mkdir -p /etc/ssl/certs \
  && update-ca-certificates --fresh
ENTRYPOINT ["image-syncer"]
CMD ["--config", "/etc/image-syncer/image-syncer.json"]
