#!/bin/bash

source ./docker/format_print.sh
# ---------------------------------------------------------
VID=$1
IMG=trt-pose
CAM=""
# ---------------------------------------------------------
if [[ -n $VID ]];then CAM="-cam"; fi
NAME="trt-pose${CAM}"
# ---------------------------------------------------------

function check_image(){ 
	echo "$(docker images --format "table {{.Repository}}:{{.Tag}}" | grep ${1} | wc -l )" 
}
function check_container(){ 
	echo "$(docker ps -a --format "{{.Names}}" | grep ${1} | wc -l ) " 
}
# ---------------------------------------------------------
if [[ $( check_container ${NAME} ) -gt 0 ]]; then

	echo "${NAME} is exist!"
	docker start ${NAME} > /dev/null 2>&1
	docker attach ${NAME}

else

	echo "Runing a new one (${NAME})"
	if [[ -z $VID ]];then
		docker run --gpus all \
		--name $NAME \
		-it --net=host --ipc=host \
		-w /$NAME \
		-v `pwd`/:/$NAME \
		-v /tmp/.x11-unix:/tmp/.x11-unix:rw \
		-e DISPLAY=unix$DISPLAY \
		$IMG "./docker/install_trt_pose.sh && bash"
	else
		
		echo "Mount camera "
		docker run --gpus all \
		--name $NAME \
		-it --net=host --ipc=host \
		-w /$NAME \
		--device /dev/video0:/dev/video0 \
		-v `pwd`/:/$NAME \
		-v /tmp/.x11-unix:/tmp/.x11-unix:rw \
		-e DISPLAY=unix$DISPLAY \
		$IMG "./docker/install_trt_pose.sh && bash"
	fi
fi
