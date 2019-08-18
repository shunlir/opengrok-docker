#!/bin/sh

ver=1.3.1
docker build \
    --build-arg version=${ver} \
    -t shunlir/opengrok:latest \
    -t shunlir/opengrok:${ver} \
    .