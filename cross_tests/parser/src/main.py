import os
from glob import glob
from base_logging import LoggerManager
from bench_ex import PgBenchFile
from argparse import ArgumentParser, Namespace
import logging

logger=LoggerManager().getLogger(__name__)
logger.setLevel(level=logging.DEBUG)

def process_args() -> Namespace:
    parser: ArgumentParser = ArgumentParser()
    parser.add_argument("-f",
                        "--folder",
                        type=str,
                        default='./',
                        help="Имя папки, в которой файлы тесты лежат")
    args = parser.parse_args()
    return args

list_folders = ("cache_high", "cache_low", "no_cache_high", "no_cache_low")

def main():
    args = process_args()
    base_path = str(args.folder)
    logger.debug(f"Базовый путь до папки: {type(base_path)}")
    logger.debug(f"Базовый путь до папки: {base_path}")
    all_files_txt = []
    all_files_json = []

    for folder in list_folders:
        all_files_txt.append(glob(os.path.join(base_path, folder, '*.txt')))
    for folder in list_folders:
        all_files_json.append(glob(os.path.join(base_path, folder, '*.json')))

    for id_list_files, list_files in enumerate(all_files_txt):
        for file in list_files:
            bench_example = PgBenchFile(file, id_list_files)
            logger.debug(f"Имя файла {file}")
            with open(file, "r", encoding="utf-8") as f:
                for line in f:
                    if not bench_example.serialise(line):
                        break
            print(bench_example.transaction_by_time_dict)
            break
        break
if __name__ == '__main__':
    main()
