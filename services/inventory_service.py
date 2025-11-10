import configparser
from config import Config

class InventoryService:
    def __init__(self):
        self.inventory_file = Config.INVENTORY_FILE

    def load_inventory_data(self):
        """Загружает данные ВМ из инвентарного файла"""
        try:
            config = configparser.ConfigParser(allow_no_value=True)
            config.read(self.inventory_file)
            virtual_machines = []

            for section in config.sections():
                if 'hosts' in section.lower() and not section.endswith(':vars'):
                    os_name = None
                    vars_section = f"{section}:vars"
                    if vars_section in config:
                        os_name = config[vars_section].get('os_name')

                    for host in config[section]:
                        if host and not host.startswith('#'):
                            virtual_machines.append({
                                'ip': host,
                                'os': os_name or 'Неизвестно'
                            })

            return virtual_machines

        except Exception as e:
            print(f"Ошибка загрузки инвентаря: {e}")
            return []