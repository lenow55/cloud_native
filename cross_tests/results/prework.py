import os
from glob import glob


list_folders = ("cache_high", "cache_low", "no_cache_high", "no_cache_low")

all_files_txt = []
all_files_json = []

for folder in list_folders:
    all_files_txt.append(glob(os.path.join(folder, '*.txt')))
for folder in list_folders:
    all_files_json.append(glob(os.path.join(folder, '*.json')))

for id_list_files, list_files in enumerate(all_files_txt):
    for file in list_files:
        bench_result = ""
        bench_header = ""
        with open(file, "r", encoding="utf-8") as f:
            for line in f:

            bench_result = f.read()





