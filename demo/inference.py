import json, os, argparse, sys, time, torch
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

# -----------------------------------------------------------------------------
FONT = cv2.FONT_HERSHEY_COMPLEX_SMALL
THICK = 1
FONT_SIZE = 0.6
PADDING = 10
MEAN = torch.Tensor([0.485, 0.456, 0.406]).cuda()
STD = torch.Tensor([0.229, 0.224, 0.225]).cuda()
DEVICE = torch.device('cuda')

def preprocess(image, input_size=(224,224)):
    image = cv2.resize(image, input_size)
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    image = PIL.Image.fromarray(image)
    image = transforms.functional.to_tensor(image).to(DEVICE)
    image.sub_(MEAN[:, None, None]).div_(STD[:, None, None])
    return image[None, ...].cpu()

def execute(image, input_size, context, bindings, inputs, outputs, stream):
    
    data = preprocess(image, tuple(input_size[-2:]))
    h = input_size[1]//4
    w = input_size[2]//4
    
    np.copyto(inputs[0].host, data.ravel())
    cmap, paf = common.do_inference(context, bindings=bindings, inputs=inputs, outputs=outputs, stream=stream)
    cmap = np.resize(cmap, (1, 18, h, w))
    paf = np.resize(paf, (1, 42, h, w))
    return torch.Tensor(cmap), torch.Tensor(paf)

def put_text(frame, text, position, fg_color=None, bg_color=None):
    fg_color = fg_color if fg_color else (0,0,0)
    bg_color = bg_color if bg_color else (255,255,255)
    # (t_width, t_height) = cv2.getTextSize(text, FONT, FONT_SIZE, THICK)[0]
    frame_bg = cv2.putText(frame, text, position, FONT, FONT_SIZE, bg_color , THICK + 3,  cv2.LINE_AA)
    frame_fg = cv2.putText(frame_bg, text, position, FONT, FONT_SIZE, fg_color , THICK, cv2.LINE_AA)
    return frame_fg

# -----------------------------------------------------------------------------
parser = argparse.ArgumentParser()
parser.add_argument("-e", "--engine", default="resnet18_baseline_att_224x224_A_epoch_249.engine", help="the path of tensorrt engine", type=str)
parser.add_argument("-j", "--json", default="./human_pose.json", type=str)
parser.add_argument("-s", "--size", default="3,224,224",help="the input size of the torch model.", type=str)
parser.add_argument("-b", "--batch", default=1, help="the value of batch size.", type=int)
args = parser.parse_args()

# -----------------------------------------------------------------------------

jfile_path = args.json
engine_path = args.engine

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
print('Do inference with camera or video ... ')

parse_objects = ParseObjects(topology)
draw_objects = DrawObjects(topology)

# path = './people_walking_720p.mp4'
path = '/dev/video0'
cap = cv2.VideoCapture(path)

while(cap.isOpened()):
    t0 = time.time()
    ret, frame = cap.read()
    
    if not ret: 
        break
    
    cmap, paf = execute(frame, input_size, context, bindings, inputs, outputs, stream)
    counts, objects, peaks = parse_objects(cmap, paf)#, cmap_threshold=0.15, link_threshold=0.15)
    img_draw = draw_objects(frame, counts, objects, peaks)
    img_draw = put_text(img_draw, f'COUNTS:{int(counts.cpu())}', (10,10))
    img_draw = put_text(img_draw, f'FPS:{int(1/(time.time()-t0))}', (10,30))
    
    cv2.imshow('tesnorrt-pose-estimation', img_draw)
    if cv2.waitKey(1)==ord('q'):
        break
cv2.destroyAllWindows()
cap.release()
