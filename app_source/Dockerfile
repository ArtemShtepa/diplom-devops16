FROM docker.io/golang:alpine AS compile-image
WORKDIR /usr/src
COPY go.mod apiserver.go ./
RUN go build apiserver.go

#FROM docker.io/alpine
FROM docker.io/debian:12
#WORKDIR /
COPY --from=compile-image /usr/src/apiserver /apiserver
RUN chmod +x /apiserver
ENTRYPOINT ["/apiserver"]
