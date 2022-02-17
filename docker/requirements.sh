#!/bin/bash
source format_print.sh

function find_py_pkg(){
	PKG=$1
	echo $(pip3 list | grep $PKG)
}

printd "$(date +"%T") Initialize ... " Cy
apt-get update -qqy
apt-get install -qy figlet boxes tree > /dev/null 2>&1
pip3 install --upgrade -q pip > /dev/null 2>&1

ROOT=`pwd`
echo "Workspace is ${ROOT}" | boxes -p a1

# OpenCV
printd "$(date +"%T") Install OpenCV " Cy
apt-get install -qqy ffmpeg libsm6 libxext6 #> /dev/null 2>&1
pip3 install -q opencv-python==4.1.2.30 tqdm #> /dev/null 2>&1

# TLT Converter
# printd "$(date +"%T") Install Dependencies of TLT Converter " Cy
# apt-get install -qqy libssl-dev #> /dev/null 2>&1
# echo 'export TRT_LIB_PATH=/usr/lib/x86_64-linux-gnu' >> ~/.bashrc 
# echo 'TRT_INC_PATH=/usr/include/x86_64-linux-gnu' >> ~/.bashrc 

# iTAO requirements
# printd "$(date +"%T") Install Dependencies of iTAO " Cy
# apt-get install -y libxcb-xinerama0 qt5-default    
# pip3 --disable-pip-version-check install PyQt5 pyqtgraph wget GPUtil

# Torch 
printd "$(date +"%T") Install torch, torchvision with CUDA 11.1 " Cy
pip3 install -q torch==1.9.0+cu111 torchvision==0.10.0+cu111 torchaudio==0.9.0 -f https://download.pytorch.org/whl/torch_stable.html

printd "Install other msicellaneous packages " Cy
pip3 install -q tqdm cython pycocotools gdown setuptools packaging
apt-get -qqy install python3-matplotlib bsdmainutils

# torch2trt
printd "$(date +"%T") Install torch2trt " Cy
PKG="torch2trt"

if [[ -n ${PKG} ]];then git clone https://github.com/NVIDIA-AI-IOT/torch2trt && cd ${PKG}; fi
python3 setup.py -q install --plugins
cd $ROOT && rm -rf ${PKG}

# TRT_POSE
printf "$(date +%T) Check trt_pose "
TRG="pure_trt_pose"
PKG="trt-pose"

if [[ -n ${TRG} ]];then git clone https://github.com/p513817/pure_trt_pose.git && cd ${TRG} ; fi
python3 setup.py -q install
cd $ROOT && rm -rf ${TRG}

echo -e "Done${REST}"
# ---------------------------------------------------------------------------