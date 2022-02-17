import json, os, argparse, sys, time, torch
from unittest import result
import torch2trt
import trt_pose.coco
import trt_pose.models
from torch2trt import TRTModule
import trt_pose.models
import cv2
import torchvision.transforms as transforms
import PIL.Image
from trt_pose.draw_objects import DrawObjects
from trt_pose.parse_objects import ParseObjects

import common
import tensorrt as trt
import numpy as np

def check_path(path):
    if not os.path.exists(path):
        raise Exception("{} is not exists".format(path))

# -----------------------------------------------------------------------------
parser = argparse.ArgumentParser()
parser.add_argument("-e", "--engine", default="resnet18_baseline_att_224x224_A_epoch_249.engine", help="the path of tensorrt engine", type=str)
parser.add_argument("-j", "--json", default="./human_pose.json", type=str)
parser.add_argument("-s", "--size", default="3,224,224",help="the input size of the torch model.", type=str)
parser.add_argument("-b", "--batch", default=1, help="the value of batch size.", type=int)
args = parser.parse_args()

# -----------------------------------------------------------------------------
# define variable

jfile_path = args.json
engine_path = args.engine

# check the path is exists
[ check_path(path) for path in [ jfile_path, engine_path ] ]

# input_size = [ int(i) for i in args.size.split(",")] # chaneel, height, width
if "224" in engine_path:
    input_size = [3, 224, 224]
elif "256" in engine_path:
    input_size = [3, 256, 256]

batch_size = args.batch

# -----------------------------------------------------------------------------
print('Get human pose parser ... ', end="", flush=True)
t0 = time.time()
with open(jfile_path, 'r') as f:
    human_pose = json.load(f)
topology = trt_pose.coco.coco_category_to_topology(human_pose)
num_parts, num_links = len(human_pose['keypoints']), len(human_pose['skeleton'])
print("{}s".format(round(time.time()-t0,3)))

# -----------------------------------------------------------------------------
print('Load model ... ', end="", flush=True)
t0 = time.time()

trt_logger = trt.Logger(trt.Logger.WARNING)     # TensorRT logger singleton
trt.init_libnvinfer_plugins(trt_logger, '')     # We first load all custom plugins shipped with TensorRT
runtime = trt.Runtime(trt_logger)               # Initialize runtime needed for loading TensorRT engine from file

with open(engine_path, 'rb') as serial_engine:                      # read engine from serial data
    engine = runtime.deserialize_cuda_engine(serial_engine.read())

inputs, outputs, bindings, stream = common.allocate_buffers(engine, 1)  # allocate buffer
context = engine.create_execution_context()                             # create excute object 

print("{}s".format(round(time.time()-t0,3)))

# -----------------------------------------------------------------------------
print('Do inference with testing data ... ', end="", flush=True)
t0 = time.time()
data = torch.zeros((batch_size, input_size[0], input_size[1], input_size[2]))
np.copyto(inputs[0].host, data.ravel())
results = common.do_inference(context, bindings=bindings, inputs=inputs, outputs=outputs, stream=stream)
print("{}s (FPS:{})".format(round(time.time() - t0,3), int(50.0/(time.time() - t0))))
# -----------------------------------------------------------------------------