PROJECT?=go-k8s-example
APP?=main
PORT?=8000
RELEASE?=0.0.1
COMMIT?=$(shell git rev-parse --short HEAD)
BUILD_TIME?=$(shell date -u '+%Y-%m-%d_%H:%M:%S')
CONTAINER_IMAGE?=hungmingwu/${APP}:${RELEASE}

GOOS?=linux
GOARCH?=amd64
clean:
	rm -f ${APP}

build: clean
	CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} go build \
		-ldflags "-s -w -X ${PROJECT}/version.Release=${RELEASE} \
		-X ${PROJECT}/version.Commit=${COMMIT} -X ${PROJECT}/version.BuildTime=${BUILD_TIME}" \
		-o ${APP}

container:
	docker build -t $(APP):$(RELEASE) . --build-arg PROJECT=${PROJECT} --build-arg APP=${APP} \
		--build-arg RELEASE=${RELEASE} --build-arg COMMIT=${COMMIT} --build-arg BUILD_TIME=${BUILD_TIME}

run: container
	docker run --name ${APP} -p ${PORT}:${PORT} --rm \
		-e "PORT=${PORT}" \
		$(APP):$(RELEASE)

push: container
	docker tag $(APP):$(RELEASE) $(CONTAINER_IMAGE)
	docker push $(CONTAINER_IMAGE)

test:
	go test -v -race ./...

microk8s:
	for t in $(shell find ./kubernetes -type f -name "*.yaml"); do \
		cat $$t | \
			sed -E "s/\{\{(\s*)\.Release(\s*)\}\}/$(RELEASE)/g" | \
		        sed -E "s/\{\{(\s*)\.ServiceName(\s*)\}\}/$(APP)/g"; \
	echo ---; \
	done > tmp.yaml
	kubectl apply -f tmp.yaml

microk8sstop:
	kubectl delete deployment/$(APP)
	kubectl delete svc/$(APP)

