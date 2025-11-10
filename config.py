import os

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'your-secret-key-here'
    DEBUG_MODE = False
    INVENTORY_FILE = 'dev_inventory.ini'
    ANSIBLE_VARS_FILE = 'group_vars/all.yml'
    DOWNLOADED_BUILDS_PATH = '/tmp/downloaded_builds'