#!/bin/bash
if [[ -f format_print.sh ]];then
	source format_print.sh
else
	function printd(){
		echo $1
	}
fi

function find_py_pkg(){
	PKG=$1
	echo $(pip3 list | grep $PKG)
}

printd "$(date +"%T") Initialize ... " Cy
apt-get update -qqy
apt-get install -qy figlet boxes tree > /dev/null 2>&1
pip3 install --force pip~=21.0.0

ROOT=`pwd`
echo "Workspace is ${ROOT}" | boxes -p a1

# OpenCV
printd "$(date +"%T") Install OpenCV " Cy
apt-get install -qqy ffmpeg libsm6 libxext6 #> /dev/null 2>&1
pip3 install -q opencv-python==4.1.2.30 tqdm #> /dev/null 2>&1

# Torch 
printd "$(date +"%T") Install torch, torchvision with CUDA 11.1 " Cy
pip3 install torch==1.9.0+cu111 torchvision==0.10.0+cu111 torchaudio==0.9.0 -f https://download.pytorch.org/whl/torch_stable.html

printd "Install other msicellaneous packages " Cy
pip3 install -q tqdm cython pycocotools gdown setuptools packaging
apt-get -qqy install python3-matplotlib bsdmainutils

echo -e "Done${REST}"
# ---------------------------------------------------------------------------