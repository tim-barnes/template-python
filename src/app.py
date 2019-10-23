import logging

_log = logging.getLogger()


def print_hello():
    _log.info("Hello World")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    print_hello()
