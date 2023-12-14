#
# Copyright (c) 2018, 2019 Intel
# Copyright (c) 2021 Schneider Electric
# Copyright (C) 2023 YIQISOFT
#
# SPDX-License-Identifier: Apache-2.0
#
FROM golang:1.21-alpine3.18 AS builder
WORKDIR /device-opcua-go

# Install our build time packages.
RUN apk update && apk add --no-cache make git zeromq-dev gcc pkgconfig musl-dev

COPY . .

RUN make build

# Next image - Copy built Go binary into new workspace
FROM alpine:3.18
LABEL license='SPDX-License-Identifier: Apache-2.0' \
  copyright='Copyright (c) 2023: YIQISOFT'

# dumb-init needed for injected secure bootstrapping entrypoint script when run in secure mode.
RUN apk add --update --no-cache zeromq dumb-init
# Ensure using latest versions of all installed packages to avoid any recent CVEs
RUN apk --no-cache upgrade

# expose command data port
EXPOSE 59997

COPY --from=builder /device-opcua-go/cmd/device-opcua /
COPY --from=builder /device-opcua-go/cmd/res /res
COPY LICENSE /
COPY --from=builder /device-opcua-go/Attribution.txt /Attribution.txt

ENTRYPOINT ["/device-opcua"]
CMD ["--cp=consul://edgex-core-consul:8500", "--registry"]
