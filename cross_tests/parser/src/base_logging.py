import logging
import sys


class Singleton(type):
    _instances = {}

    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances.keys():
            cls._instances[cls] = super(
                Singleton, cls).__call__(*args, **kwargs)
        return cls._instances[cls]


# Данный клас излишен, так как уже есть
# менеджер логгеров в библиотеке logging
# выполняется двойное хранение, так сказать.
class LoggerManager(object):
    __metaclass__ = Singleton

    _loggers = {}

    def __init__(self, *args, **kwargs):
        pass

    @staticmethod
    def getLogger(name="main"):
        if name not in LoggerManager._loggers.keys():
            LoggerManager._loggers[name] = logging.getLogger(str(name))
            fmt = logging.Formatter(
                fmt="%(asctime)s - %(name)s:%(lineno)d - %(levelname)s - %(message)s",
                datefmt="%Y-%m-%d %H:%M:%S",
            )
            sh = logging.StreamHandler(sys.stdout)
            sh.setFormatter(fmt)
            LoggerManager._loggers[name].addHandler(sh)
        return LoggerManager._loggers[name]
