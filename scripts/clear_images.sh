#!/bin/bash

# 清理无用的 Docker 镜像
docker image prune -a --force --filter "until=168h"
