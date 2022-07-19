#!/bin/sh

podman run -it --rm -v $(pwd):/app:Z d2d_client:latest
