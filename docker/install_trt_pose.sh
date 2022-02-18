#!/bin/bash
if [[ ! `dirname "$0"` == "docker" ]];then
    echo "Move to docker/."
    cd docker
fi

source ./format_print.sh

# torch2trt
printd "$(date +"%T") Install torch2trt " Cy
PKG="torch2trt"

if [[ -n ${PKG} ]];then git clone https://github.com/NVIDIA-AI-IOT/torch2trt && cd ${PKG}; fi
python3 setup.py -q install --plugins
cd $ROOT && rm -rf ${PKG}

# TRT_POSE
printd "$(date +%T) Check trt_pose "
TRG="pure_trt_pose"
PKG="trt-pose"

if [[ -n ${TRG} ]];then git clone https://github.com/p513817/pure_trt_pose.git && cd ${TRG} ; fi
python3 setup.py -q install
cd $ROOT && rm -rf ${TRG}

printd "DONE" Cy