NAME ?= opensips
OPENSIPS_VERSION ?= 2.4

all: build start

.PHONY: build start
build:
	docker build --build-arg=VERSION=$(OPENSIPS_VERSION) --tag="opensips/opensips:$(OPENSIPS_VERSION)" .

start:
	docker run -d --name $(NAME) opensips/opensips:$(OPENSIPS_VERSION)
