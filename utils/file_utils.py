import yaml
import os
from config import Config

def load_ansible_vars():
    """Загружает переменные Ansible из group_vars"""
    try:
        with open(Config.ANSIBLE_VARS_FILE, 'r') as f:
            return yaml.safe_load(f)
    except Exception as e:
        print(f"Ошибка загрузки переменных Ansible: {e}")
        return {}

def save_ansible_vars(vars_data):
    """Сохраняет переменные Ansible в group_vars"""
    try:
        with open(Config.ANSIBLE_VARS_FILE, 'w') as f:
            yaml.dump(vars_data, f, default_flow_style=False, sort_keys=False)
        return True
    except Exception as e:
        print(f"Ошибка сохранения переменных Ansible: {e}")
        return False