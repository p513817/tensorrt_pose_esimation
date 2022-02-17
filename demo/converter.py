import json, os, argparse, time, sys, logging
from logging import raiseExceptions
import torch
import torch2trt
import trt_pose.coco
import trt_pose.models

def check_path(path):
    if not os.path.exists(path):
        raise Exception("{} is not exists".format(path))

# -----------------------------------------------------------------------------

parser = argparse.ArgumentParser()
parser.add_argument("-m", "--model", help="the path of the torch model.", type=str)
parser.add_argument("-j", "--json", default="./human_pose.json", type=str)
parser.add_argument("-s", "--size", default="3,224,224",help="the input size of the torch model.", type=str)
parser.add_argument("-b", "--batch", default=1, help="the value of batch size.", type=int)
parser.add_argument("-e", "--engine", help="the path of tensorrt engine", type=str)
args = parser.parse_args()

# -----------------------------------------------------------------------------
# define variable

jfile_path = args.json
model_path = args.model
engine_path = args.engine

# check the path is exists
[ check_path(path) for path in [ jfile_path, model_path ] ]

# input_size = [ int(i) for i in args.size.split(",")] # chaneel, height, width
if "224" in model_path:
    input_size = [3, 224, 224]
elif "256" in model_path:
    input_size = [3, 256, 256]
batch_size = args.batch

# -----------------------------------------------------------------------------
print('get human pose parser ...', end='')
t0 = time.time()

with open(jfile_path, 'r') as f:
    human_pose = json.load(f)
topology = trt_pose.coco.coco_category_to_topology(human_pose)
num_parts, num_links = len(human_pose['keypoints']), len(human_pose['skeleton'])

print(' {} s '.format(round(time.time()-t0, 3)))

# -----------------------------------------------------------------------------
print("load architecture and weights ...", end='')
t0 = time.time()

if "resnet18" in model_path:
    model = trt_pose.models.resnet18_baseline_att(num_parts, 2 * num_links).cuda().eval()
elif "densenet121":
    model = trt_pose.models.densenet121_baseline_att(num_parts, 2 * num_links).cuda().eval()
else:
    raise Exception('Unexcepted model name: {}'.format(model_path))
model.load_state_dict(torch.load(model_path))

print(' {} s '.format(round(time.time()-t0, 3)))

# -----------------------------------------------------------------------------
# do convert
print("do convert ... ")
t0 = time.time()
data = torch.zeros((batch_size, input_size[0], input_size[1], input_size[2])).cuda()

model_trt = torch2trt.torch2trt(model, [data],
                                fp16_mode=True,
                                max_workspace_size=1<<25,
                                max_batch_size=batch_size)
                                
with open(engine_path, "wb") as f:
    f.write(model_trt.engine.serialize())

print('-'*20)
print('Convert model ( {}s )'.format(round(time.time()-t0, 3)))