import re
from datetime import datetime
from base_logging import LoggerManager
import logging
from typing import Callable

logger=LoggerManager().getLogger(__name__)
logger.setLevel(level=logging.INFO)

class PgBenchFile:
    def __init__(self, name, id_folder):
        self.name = name
        self.id_folder = id_folder
        self.timestamp = ""
        self.test_number = 0
        self.cost = 0
        self.scale = 0
        self.percent_write = 0
        self.pool_bit = 0
        self.count_connections = 0
        self.query_cache_bit = 0
        self.base_size_bit = 0
        self.tps = 0
        self.initial_connection_time = 0
        self.latency_avg = 0
        self.latency_std = 0
        self.latency_avg = 0
        self.latency_avg = 0
        self.number_of_clients = 0
        self.number_of_threads = 0
        self.duration = 0
        self.progress_list_dict = []
        self.transaction_by_time_dict = []

        self.function = self.read_timestamp
        self.compiled_re_timestamp = re.compile(
            r"TIMESTAMP: (\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)")
        self.compiled_re_progress = re.compile(
            r"starting vacuum")
        self.compiled_re_bench = re.compile(
            r"progress: (\d+\.\d+) s, (\d+\.\d+) tps, lat (\d+\.\d+) ms stddev (\d+\.\d+)")
        self.compiled_re_footer = re.compile(
            r"number of transactions actually processed:")
        self.compiled_transaction_by_time = re.compile(
            r"([\d.]+)\s+(BEGIN|END|SELECT|INSERT)\s*(.*)"
        )
        self.process_flag = True

    def serialise(self, row):
        self.function = self.function(row=row)
        return self.process_flag

    def read_timestamp(self, row: str) -> Callable:
        match = self.compiled_re_timestamp.search(row)
        if match:
            timestamp = match.group(1)
            self.timestamp = datetime.fromisoformat(timestamp)
            logger.debug(f"Извлеченная дата: {self.timestamp}")
        else:
            logger.fatal(f"Дата не найдена", exc_info=True)
        return self.read_test_number

    def read_test_number(self, row: str) -> Callable:
        parts = row.split()
        try:
            self.test_number = int(parts[1])
            logger.debug(f"Номер теста {self.test_number}")
        except Exception as ex:
            logger.error(ex)
            logger.fatal("Номер не определён", exc_info=True)
            exit(1)
        return self.read_cost

    def read_cost(self, row: str) -> Callable:
        parts = row.split()
        try:
            self.cost = int(parts[1])
            logger.debug(f"Стоимость запроса {self.cost}")
        except Exception as ex:
            logger.error(ex)
            logger.fatal("Стоимость не определена", exc_info=True)
        return self.read_scale

    def read_scale(self, row: str) -> Callable:
        parts = row.split()
        try:
            self.scale = int(parts[1])
            logger.debug(f"Размерность {self.scale}")
        except Exception as ex:
            logger.error(ex)
            logger.fatal("Размерность не определена", exc_info=True)
        return self.read_percent_write

    def read_percent_write(self, row: str) -> Callable:
        parts = row.split()
        try:
            self.percent_write = int(parts[1])
            logger.debug(f"Процент записи {self.percent_write}")
        except Exception as ex:
            logger.error(ex)
            logger.error("Процент записи не определен", exc_info=True)
        return self.read_pool_bit

    def read_pool_bit(self, row: str) -> Callable:
        parts = row.split()
        try:
            self.pool_bit = bool(parts[1])
            logger.debug(f"PgPool включён: {self.pool_bit}")
        except Exception as ex:
            logger.error(ex)
            logger.error("PgPool не определён", exc_info=True)
        return self.read_count_connections

    def read_count_connections(self, row: str) -> Callable:
        parts = row.split()
        try:
            self.count_connections = int(parts[1])
            logger.debug(f"Количество соединений {self.count_connections}")
        except Exception as ex:
            logger.error(ex)
            logger.error("Количество соединений не определёно", exc_info=True)
        return self.read_query_cache_bit

    def read_query_cache_bit(self, row: str) -> Callable:
        parts = row.split()
        try:
            self.query_cache_bit = bool(parts[1])
            logger.debug(f"Кэш включён: {self.query_cache_bit}")
        except Exception as ex:
            logger.error(ex)
            logger.error("Кэш не определён", exc_info=True)
        return self.read_base_size_bit

    def read_base_size_bit(self, row: str) -> Callable:
        parts = row.split()
        try:
            self.base_size_bit = bool(parts[1])
            logger.debug(f"База помещается в кэш: {self.base_size_bit}")
        except Exception as ex:
            logger.error(ex)
            logger.error("Размер базы не определён", exc_info=True)
        return self.read_unusefull

    def read_unusefull(self, row: str) -> Callable:
        match = self.compiled_re_progress.search(row)
        match2 = self.compiled_re_footer.search(row)
        if match:
            return self.read_progress_dict
        elif match2:
            return self.read_latency_avg
        else:
            return self.read_unusefull

    def read_progress_dict(self, row: str) -> Callable:
        matches = self.compiled_re_bench.findall(row)
        logger.debug(matches)
        for match in matches:
            progress = float(match[0])
            tps = float(match[1])
            latency = float(match[2])
            stddev = float(match[3])

            result_dict = {
                "progress": progress,
                "tps": tps,
                "latency": latency,
                "stddev": stddev
            }

            self.progress_list_dict.append(result_dict)
            return self.read_progress_dict
        return self.read_unusefull

    def read_latency_avg(self, row: str) -> Callable:
        parts = row.split()
        try:
            self.latency_avg = float(parts[3])
            logger.debug(f"Средняя задержка: {self.latency_avg}")
        except Exception as ex:
            logger.error(ex)
            logger.error("Средняя задержка не определёна", exc_info=True)
        return self.read_latency_std

    def read_latency_std(self, row: str) -> Callable:
        parts = row.split()
        try:
            self.latency_std = float(parts[3])
            logger.debug(f"Средняя задержка std: {self.latency_std}")
        except Exception as ex:
            logger.error(ex)
            logger.error("Средняя задержка std не определёна", exc_info=True)
        return self.read_initial_connection_time

    def read_initial_connection_time(self, row: str) -> Callable:
        parts = row.split()
        try:
            self.initial_connection_time = float(parts[4])
            logger.debug(f"Время установки соединения: {self.initial_connection_time}")
        except Exception as ex:
            logger.error(ex)
            logger.error(
                "Время установки соединения не определёно", exc_info=True)
        return self.read_tps

    def read_tps(self, row: str) -> Callable:
        parts = row.split()
        try:
            self.tps = float(parts[2])
            logger.debug(f"TPS: {self.tps}")
        except Exception as ex:
            logger.error(ex)
            logger.error("TPS не определёно", exc_info=True)
        return self.read_transaction_by_time_dict

    def read_transaction_by_time_dict(self, row: str) -> Callable:
        matches = self.compiled_transaction_by_time.findall(row)
        logger.debug(matches)
        for match in matches:
            numeric_value = float(match[0])
            command = match[1]

            result_dict = {
                "command": command,
                "numeric_value": numeric_value,
            }
            self.transaction_by_time_dict.append(result_dict)
            if command == "END":
                self.process_flag = False
        return self.read_transaction_by_time_dict
