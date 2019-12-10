FROM golang:latest AS go-builder
ADD . /go_build
WORKDIR /go_build
ARG PROJECT
ARG APP
ARG RELEASE
ARG COMMIT
ARG BUILD_TIME
RUN ls /go_build
RUN CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} go build \
    -ldflags "-s -w -X ${PROJECT}/version.Release=${RELEASE} \
             -X ${PROJECT}/version.Commit=${COMMIT} -X ${PROJECT}/version.BuildTime=${BUILD_TIME}" \
             -o ${APP}

FROM scratch

ENV PORT 8000
EXPOSE $PORT

COPY --from=go-builder /go_build/main /main
CMD ["/main"]
