import os
import sys
import glob
import json

#input animal, session, and channel number on command line (i.e. run create_json.py sm031 13 1)
animal = sys.argv[1]
session = sys.argv[2]
channel = sys.argv[3]
project = sys.argv[4]

animal_path ='/net/claustrum4/mnt/storage/data/Projects/' + project + '/Animals/' + animal + '/2P/' # /net/claustrum4/mnt/storage/data/Projects/Transsynaptic/Animals/os004/2P/os004-1
local_train_paths = glob.glob(os.path.join(animal_path, animal + '-' + session + '/PreProcess/*_Ch' + channel))
output_name = animal + '-' + session + "_files.json"

train_paths_td = []
for local_train_path in local_train_paths:
    train_paths = sorted(set(glob.glob(os.path.join(local_train_path,'A*_Ch' + channel + '*.mat')))-set(glob.glob(os.path.join(local_train_path,'A*_Ch' + channel + '*_dp.mat'))))
    train_paths_done = glob.glob(os.path.join(local_train_path,'*_dp.mat'))
    for i in train_paths:
        doneFile = i.replace('.mat', '_dp.mat')
        if doneFile not in train_paths_done:
            train_paths_td.append(i)
print(len(train_paths_td))

json_obj = json.dumps(train_paths_td)

#change to name json file
with open(output_name, "w") as outfile:
    outfile.write(json_obj)

with open(animal + '-' + session + '.length', "w") as f:
    f.write(str(len(train_paths_td)))
    f.write('\n')
