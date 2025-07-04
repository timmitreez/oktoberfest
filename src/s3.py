import os
import json
import logging

log = logging.getLogger()
log.setLevel(logging.INFO)

DATA_PATH = os.getenv("SESSION_STORAGE", "data/vacancies.json")

log.info("Using target filepath {}".format(DATA_PATH))

def upload():
    log.info("Saving data locally")
    # with open(DATA_PATH, "w") as f:
    #     json.dump(data, f)

def download():
    log.info("Loading data locally")
    if os.path.exists(DATA_PATH):
        with open(DATA_PATH, "r") as f:
            return json.load(f)
    else:
        log.warning("Local data file not found.")
        return {}
