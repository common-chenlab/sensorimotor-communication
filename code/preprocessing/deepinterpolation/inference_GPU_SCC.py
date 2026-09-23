import os
from datetime import datetime
from scipy.io import loadmat

def inference(path,tag,sess):

    import os
    import scipy.io as sio
    from deepinterpolation.generic import JsonSaver, ClassLoader
    from datetime import datetime

    startTime=datetime.now()

    generator_param = {}
    inferrence_param = {}

    # We are reusing the data generator for training here.
    generator_param["type"] = "generator"
    generator_param["name"] = "SingleTifGenerator"
    generator_param["pre_post_frame"] = 30
    generator_param["pre_post_omission"] = 0
    generator_param[
        "steps_per_epoch"
    ] = -1  # No steps necessary for inference as epochs are not relevant. -1 deactivate it.

    generator_param["train_path"] = path

    generator_param["batch_size"] = 5
    generator_param["start_frame"] = 0
    generator_param["end_frame"] = -1  # -1 to go until the end.
    generator_param[
        "randomize"
    ] = 0  # This is important to keep the order and avoid the randomization used during training

    inferrence_param["type"] = "inferrence"
    inferrence_param["name"] = "core_inferrence"

    # Replace this path to where you stored your model
    inferrence_param[
        "model_path"
    ] = os.path.expanduser('~') + "/trained_model.h5"
  
    inferrence_param["mat_file"] = path.replace(".mat","_dp.mat")

    jobdir = os.path.expanduser('~') + "/deepinterpolation/"

    try:
        os.mkdir(jobdir)
    except:
        print("folder already exists")

    path_generator = os.path.join(jobdir, "generator_" + sess + tag + ".json")
    json_obj = JsonSaver(generator_param)
    json_obj.save_json(path_generator)

    path_infer = os.path.join(jobdir, "inferrence_" + sess + tag + ".json")
    json_obj = JsonSaver(inferrence_param)
    json_obj.save_json(path_infer)

    generator_obj = ClassLoader(path_generator)
    data_generator = generator_obj.find_and_build()(path_generator)

    inferrence_obj = ClassLoader(path_infer)
    inferrence_class = inferrence_obj.find_and_build()(path_infer, data_generator)

    # Except this to be slow on a laptop without GPU. Inference needs parallelization to be effective.
    out = inferrence_class.run()
    framedata=data_generator.list_samples[0:len(data_generator)*5]
    matdata = np.ascontiguousarray(out)
    matdata = matdata[:,data_generator.a:512-data_generator.a,data_generator.b:512-data_generator.b]
    matsavedata = np.swapaxes(matdata, 0, 2)
    matsavedata = np.swapaxes(matsavedata, 0, 1)
    new_mat_name = path.replace(".mat", "_dp.mat")
    sio.savemat(new_mat_name, mdict={'inference_data':matsavedata, 'frame_id':framedata}, do_compression=True)

    os.remove(path_generator)
    os.remove(path_infer)

    print(datetime.now() - startTime)

def inference2(path,start,end,tag,sess):
    import os
    from deepinterpolation.generic import JsonSaver, ClassLoader
    import numpy as np
    import scipy.io as sio
    from scipy.io import loadmat

    generator_param = {}
    inferrence_param = {}

    # We are reusing the data generator for training here.
    generator_param["type"] = "generator"
    generator_param["name"] = "SingleTifGenerator"
    generator_param["pre_post_frame"] = 30
    generator_param["pre_post_omission"] = 0
    generator_param[
        "steps_per_epoch"
    ] = -1  # No steps necessary for inference as epochs are not relevant. -1 deactivate it.

    generator_param["train_path"] = path

    generator_param["batch_size"] = 1
    generator_param["start_frame"] = start
    generator_param["end_frame"] = end # -1 to go until the end.
    generator_param[
        "randomize"
    ] = 0  # This is important to keep the order and avoid the randomization used during training

    inferrence_param["type"] = "inferrence"
    inferrence_param["name"] = "core_inferrence"

    # Replace this path to where you stored your model
    inferrence_param[
        "model_path"
    ] = os.path.expanduser('~') + "/trained_model.h5"
   
    inferrence_param["mat_file"] = path.replace(".mat","_dp.mat")

    jobdir = os.path.expanduser('~') + "/deepinterpolation"

    try:
        os.mkdir(jobdir)
    except:
        print("folder already exists")

    path_generator = os.path.join(jobdir, "generator2_" + sess + tag +".json")

    json_obj = JsonSaver(generator_param)
    json_obj.save_json(path_generator)

    path_infer = os.path.join(jobdir, "inferrence2_" + sess + tag + ".json")
    json_obj = JsonSaver(inferrence_param)
    json_obj.save_json(path_infer)

    generator_obj = ClassLoader(path_generator)
    data_generator = generator_obj.find_and_build()(path_generator)

    inferrence_obj = ClassLoader(path_infer)
    inferrence_class = inferrence_obj.find_and_build()(path_infer, data_generator)

    # Except this to be slow on a laptop without GPU. Inference needs parallelization to be effective.
    new_mat_name = path.replace(".mat", "_dp.mat")
    old=loadmat(new_mat_name)["inference_data"]
    old_id = loadmat(new_mat_name)["frame_id"]
    new_id = data_generator.list_samples[0:len(data_generator)*5]
    framedata = np.concatenate([np.squeeze(old_id),new_id])
    out = inferrence_class.run()
    matdata = np.ascontiguousarray(out)
    matdata = matdata[:,data_generator.a:512-data_generator.a,data_generator.b:512-data_generator.b]
    old = np.ascontiguousarray(np.swapaxes(old, 1, 2))
    old = np.ascontiguousarray(np.swapaxes(old, 0, 1))
    matsavedata=np.concatenate([old,matdata],0)
    matsavedata = np.swapaxes(matsavedata, 0, 2)
    matsavedata = np.swapaxes(matsavedata, 0, 1)
    sio.savemat(new_mat_name, mdict={'inference_data':matsavedata, 'frame_id':framedata}, do_compression=True)

    os.remove(path_generator)
    os.remove(path_infer)

import sys
import numpy as np
import glob
import requests
import json
from tqdm import tqdm
import tensorflow.python.keras.backend as K
import tensorflow as tf
import os

gpus = tf.config.experimental.list_physical_devices('GPU')
for gpu in gpus:
    tf.config.experimental.set_memory_growth(gpu, True)

tf.compat.v1.disable_v2_behavior()

animal = sys.argv[1]
session = sys.argv[2]

f = open(os.path.expanduser('~') + "/deepinterpolation/" + animal + "-" + session + "_files.json")
data = json.load(f)
f.close()

task_id = int(os.environ["SGE_TASK_ID"])
if (task_id*100) < (len(data))-1:
    train_paths_td=data[(task_id-1)*100:task_id*100]
else:
    train_paths_td=data[(task_id-1)*100:(len(data))]

for i, path in enumerate(tqdm(train_paths_td)):
    sess = (path.split('-'))[1].split('/')[0]
    tag=path.split("/")[-1].replace('.mat','')

    print('start pass 1')
    startTime=datetime.now()
    with tf.device('/gpu:0'):
        inference(path,tag,sess)
    print(datetime.now() - startTime)

    print('start pass 2')
    mat_file = loadmat(path)['motion_corrected']
    new_path = path.replace('.mat', '_dp.mat')
    dp_file= loadmat(new_path)['inference_data']
    start=int(np.floor(float(mat_file.shape[2]-60)) / 5)*5 #to grab extra frames missed by batch size
    end = mat_file.shape[2]-1
    if (dp_file.shape[2] != mat_file.shape[2]-60):
        inference2(path,start,end,tag,sess) 
