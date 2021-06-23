#!/bin/bash
set -x
CUDA_VER="11.1.1"
docker build -t gemfield/homepod:$CUDA_VER-cudnn8-devel-ubuntu20.04 -f Dockerfile .
#docker build -t gemfield/homepod:$CUDA_VER-cudnn8-devel-ubuntu20.04-pro -f Dockerfile.pro .
