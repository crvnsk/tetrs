import os
import re
from glob import glob
from config import Config
from utils.file_utils import load_ansible_vars, save_ansible_vars

class BuildService:
    def __init__(self):
        self.downloaded_builds_path = Config.DOWNLOADED_BUILDS_PATH

    def load_ansible_vars(self):
        """Загружает переменные Ansible"""
        from utils.file_utils import load_ansible_vars
        return load_ansible_vars()
       
    
    def get_selected_builds(self):
        """Получает текущие выбранные билды с путями"""
        ansible_vars = load_ansible_vars()

        cf_build = ansible_vars['product']['cf_server']['linux'].get('version_cf_server', 'Не выбран')
        gw_build = ansible_vars['product']['gw_server']['linux'].get('version_gw_server', 'Не выбран')

        cf_base_uri = ansible_vars['product']['cf_server']['linux']['base_uri'].rstrip('/')
        gw_base_uri = ansible_vars['product']['gw_server']['linux']['base_uri'].rstrip('/')

        if cf_build and cf_build != 'Не выбран':
            cf_display = cf_build
            cf_full_path = f"{cf_base_uri}/{cf_build}/"
        else:
            cf_display = cf_build
            cf_full_path = ""

        if gw_build and gw_build != 'Не выбран':
            gw_display = gw_build
            gw_full_path = f"{gw_base_uri}/{gw_build}/"
        else:
            gw_display = gw_build
            gw_full_path = ""

        return {
            'cf_build': cf_display,
            'gw_build': gw_display,
            'cf_full_path': cf_full_path,
            'gw_full_path': gw_full_path,
        }

    def get_local_builds(self):
        """Получает список локальных билдов"""
        local_builds = {
            'cf_server': [],
            'gw_server': []
        }

        try:
            # CF Server
            cf_path = os.path.join(self.downloaded_builds_path, 'cf_server')
            if os.path.exists(cf_path):
                # Ищем все файлы CF
                cf_files = glob(os.path.join(cf_path, 'cyberfiles-*'))
                for file_path in cf_files:
                    if os.path.isfile(file_path):
                        filename = os.path.basename(file_path)
                        local_builds['cf_server'].append({
                            'filename': filename,
                            'path': file_path,
                            'size': os.path.getsize(file_path)
                        })

            # GW Server
            gw_path = os.path.join(self.downloaded_builds_path, 'gw_server')
            if os.path.exists(gw_path):
                # Ищем все файлы GW
                gw_files = glob(os.path.join(gw_path, 'cyberfiles-gateway-*'))
                for file_path in gw_files:
                    if os.path.isfile(file_path):
                        filename = os.path.basename(file_path)
                        local_builds['gw_server'].append({
                            'filename': filename,
                            'path': file_path,
                            'size': os.path.getsize(file_path)
                        })

        except Exception as e:
            print(f"Ошибка получения локальных билдов: {e}")

        return local_builds

    def update_build_selection(self, server, build_path):
        """Обновляет выбранный билд"""
        ansible_vars = load_ansible_vars()

        if server == "cf_server":
            ansible_vars['product']['cf_server']['linux']['version_cf_server'] = build_path
        elif server == "gw_server":
            ansible_vars['product']['gw_server']['linux']['version_gw_server'] = build_path
        else:
            raise ValueError("Неверный сервер")

        save_ansible_vars(ansible_vars)
        return True