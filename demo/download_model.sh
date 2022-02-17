#!/bin/bash

function download(){
	ID=$1
	NAME=$2

	if [[ -f $NAME ]];then
		echo "$(date +"%F %T") $NAME is exists !"
	else
		gdown --id $ID -O $NAME
	fi
}

function convert(){
	PTH=$1
	ENG=$2

	if [[ -f $ENG ]];then
		echo "$(date +"%F %T") $ENG is exists !"
	else
		python3 converter.py \
		--model=${PTH} \
		--json=./human_pose.json \
		--engine=${ENG}
	fi
}

# ------------------------------------------------------------------------------

echo "$(date +"%F %T") Download model from google drive ..."
ROOT=`pwd`
TRG_FOLDER="./"

if [[ ! (${TRG_FOLDER} == *"${ROOT}"*) ]];then
	echo "$(date +"%F %T") Move terminal to $(realpath ${TRG_FOLDER})"
	cd ${TRG_FOLDER}
fi

# ------------------------------------------------------------------------------
NAME_1="resnet18_baseline_att_224x224_A"
NAME_2="densenet121_baseline_att_256x256_B"

G_ID_1="1XYDdCUdiF2xxx4rznmLb62SdOUZuoNbd"
G_ID_2="13FkJkx7evQ1WwP54UmdiDXWyFMY1OxDU"

MODEL_1="${NAME_1}.pth"
MODEL_2="${NAME_2}.pth"

ENG_1="${NAME_1}.engine"
ENG_2="${NAME_2}.engine"

# ------------------------------------------------------------------------------
# shwo information
echo "$(date +"%F %T") Show download information"
INFO="\
Index; Name; Jetson Nano; Jetson Xavier; Weights\n\
1; ${NAME_1}; 22; 251; download (81MB)\n\
2; ${NAME_2}; 12; 101; download (84MB)"

awk -v var="$INFO" 'BEGIN {print var}' | column -t -s ';' | boxes -p a1l4r4

# ------------------------------------------------------------------------------
# choose to download
read -p "Please enter the index you want to download [<idx>/all] : " index

case $index in
	'1')
		
		download $G_ID_1 ${MODEL_1}
		;;
	'2')
		download $G_ID_2 ${MODEL_2}
		;;
	'all')
		download $G_ID_1 ${MODEL_1}
		download $G_ID_2 ${MODEL_2}
		;;
esac

echo "$(date +"%F %T") Show file list in $(realpath ${TRG_FOLDER})"
IDX=1
ADD=1
INFO="Index;File Name\n"
for f in *.pth;
do
	CNT="${IDX};$(realpath ${f})\n"
	INFO+=$CNT
	IDX=`expr $IDX + $ADD`
done


# ------------------------------------------------------------------------------
# convert model
awk -v var="$INFO" 'BEGIN {print var}' | column -t -s ';' | boxes -p a1l4r4
read -p "Please enter the index you want to convert [<idx>/all] : " index

case $index in
	'1')
		convert ${MODEL_1} ${ENG_1}
		;;
	'2')
		convert ${MODEL_2} ${ENG_2}
		;;
	'all')
		convert ${MODEL_1} ${ENG_1}
		convert ${MODEL_2} ${ENG_2}
		;;
esac

IDX=0
ADD=1
INFO="Index;File Name\n"
for f in *.engine;
do
	CNT="${IDX};$(realpath ${f})\n"
	INFO+=$CNT
	IDX=`expr $IDX + $ADD`
done
awk -v var="$INFO" 'BEGIN {print var}' | column -t -s ';' | boxes -p a1l4r4