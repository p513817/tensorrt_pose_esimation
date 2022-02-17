if [[ ! `dirname "$0"` == "docker" ]];then
    echo "Move to docker/."
    cd docker
fi

echo "Build the docker image."
# use nvidia-docker because trt-pose build with GPU.
nvidia-docker build -t trt-pose .