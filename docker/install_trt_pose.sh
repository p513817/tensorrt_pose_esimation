#!/bin/bash

function find_py_pkg(){
	PKG=$1
	echo $(pip3 list | grep $PKG)
}

# init
ROOT=`pwd`
echo "Workspace is ${ROOT}" | boxes -p a1

# torch2trt
printf "$(date +"%T") Check torch2trt ... "

PKG="torch2trt"
if [[ $(find_py_pkg $PKG) ]];then
	echo "PASS!"
else
	echo "FAILED"
	pip3 install setuptools packaging > /dev/null 2>&1
	cd $ROOT
	if [[ -n ${PKG} ]];then
		git clone https://github.com/NVIDIA-AI-IOT/torch2trt
	fi
	cd ${PKG}
	python3 setup.py install --plugins
	cd $ROOT
	rm -rf ${PKG}
fi

# TRT_POSE
printf "$(date +%T) Check trt_pose ... "

TRG="pure_trt_pose"
PKG="trt-pose"
if [[ $(find_py_pkg $PKG) ]];then
	echo "PASS"
else
	echo "FAILED"
	if [[ -n ${TRG} ]];then
		git clone https://github.com/p513817/pure_trt_pose.git
	fi
	cd ${TRG} 
	python3 setup.py install
	cd $ROOT
	rm -rf ${TRG}
fi

echo "DONE"