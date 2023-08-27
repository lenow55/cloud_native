import os
from glob import glob
from base_logging import LoggerManager
from bench_ex import PgBenchFile
from argparse import ArgumentParser, Namespace
import logging
import pandas as pd

logger=LoggerManager().getLogger(__name__)
logger.setLevel(level=logging.INFO)

def process_args() -> Namespace:
    parser: ArgumentParser = ArgumentParser()
    parser.add_argument("-f",
                        "--folder",
                        type=str,
                        default='./',
                        help="Имя папки, в которой файлы тесты лежат")
    parser.add_argument("-o",
                        "--output",
                        type=str,
                        default='out.csv',
                        help="Имя файла, в который сохранится csv")
    args = parser.parse_args()
    return args

list_folders = ("cache_high", "cache_low", "no_cache_high", "no_cache_low")

def main():
    args = process_args()
    base_path = str(args.folder)
    logger.debug(f"Базовый путь до папки: {base_path}")
    all_files_txt = []
    all_files_json = []
    bench_list = []

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
            bench_list.append(bench_example)

    df = pd.DataFrame([x.as_dict() for x in bench_list])
    df.to_csv(args.output, index=False)
    logger.info(f"Обработка закончена. Вывод в {args.output}")
if __name__ == '__main__':
    main()
