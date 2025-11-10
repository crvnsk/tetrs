
 CyberFiles autodeploy

Проект представляет из себя набор ansible плейбуков, предназначенных для автоматического разворачивания и конфигурирования продукта (сервер КФ и сервер шлюза)). В состав проекта входит несколько вспомогательных плейбуков и удобное консольное меню для управления.

.
├── app.py                          # ✓ Главный файл
├── config.py                       # ✓ Конфигурация  
├── dev_inventory.ini              # ✓ Инвентарь
├── group_vars/all.yml             # ✓ Переменные
├── models/                        # ✓ Модели
├── services/                      # ✓ ВСЕ сервисы
├── utils/                         # ✓ Утилиты
├── routes/                        # ✓ Маршруты
├── templates/                     # ✓ Полные шаблоны
├── static/                        # ✓ Статика
└── playbooks/                     # ✓ Плейбуки


 Automated features

- Скачивание последнего\конкретного билда cyberfiles
- Скачивание последнего\конкретного билда сyberfiles-gateway
- Установка сyberfiles
- Установка сyberfiles-gateway
- Удаление сyberfiles
- Удаление сyberfiles-gateway


 Supported environments 

Поддерживаемые операционные системы:

- Astra Linux 1.7
- Astra Linux 1.8
- Redos 7,8
- Centos 9
- Alt 10


 Deployment

Клонируйте репозиторий

```bash
  sudo apt update
  sudo apt install git
  git clone https://git.aip.ooo......
  cd  cyberfiles_deploy
```

Установите необходимые пакеты

```bash
  chmod +x ./install-deps-debian.sh
  sudo ./install-deps-debian.sh
```

 .venv (recommended)

Рекомендую воспользоваться готовым консольным меню

```bash
  chmod +x ./main.sh
  ./main.sh
```

Установить зависимости при помощи ./main.sh
(будет создано виртуальное окружение)
 -  misc 
   -  Install requirements (.venv)


 systemwide (experimental)

Или установить зависимости системно, не используя виртуальное окружение

```bash
  chmod +x ./install-ansible-systemwide.sh
  chmod +x ./install-requirements-userwide.sh
  sudo ./install-ansible-systemwide.sh
  sudo ./install-requirements-userwide.sh
```

 Configuration

Перед использованием требуется внести правки в конфиги согласно настройкам окружения.

 ./inventorie.ini

`[all:vars]`
`ignore_api_errors` - игнорировать ошибки при выполнении запросов к API (опционально)

`[web_servers]` - ip адреса всех WEB серверов

`[ldap]` - WEB сервера которые будут использовать ldap для связи с windows active directory

`[protego_agents]` - ip адреса всех агентов

`[db_postgres]` - WEB сервера которые будут использовать postgresql в качестве базы данных

`[db_ms_sql]` - WEB сервера которые будут использовать ms sql в качестве базы данных

`[astra_hosts:vars]` - пароли для ssh и root доступа

 ./group_vars/db_postgres.yml или ./group_vars/db_ms_sql.yml

`db_host` - ip адрес базы данных

`db_port` - порт базы данных

`db_user` - имя пользователя

`db_password` - пароль пользователя


 ./group_vars/ldap.yml
 Подправил ./group_vars/dev_ldap.yml

`ldap.host` - ip адрес контроллера LDAP (обычно ip вашего DC)

`ldap.port` - порт контроллера LDAP (обычно )

`ldap.ssl` - используется ли ssl для подключения к LDAP 

`ldap.base_dn` - базовая dn для подключения к LDAP ("DC=local,DC=lab")

`ldap.user_dn` - имя доменного пользователя для подключения к LDAP (достаточно прав простого пользователя)

`ldap.password` - пароль доменного пользователя для подключения к LDAP


 ./group_vars/all.yml

 `product.agent.linux.installers` - бинари для установки агента, оставьте пустым по умолчанию
`product.cyberfiles_gateway.linux.installers` - желаемая версия gateway (будет скачана, если доступна), оставьте пустым по умолчанию

 `product.agent.linux.version` - желаемая версия агента (будет скачана, если доступна), оставьте пустым по умолчанию
`product.cyberfiles_gateway.linux.version` - желаемая версия gateway (будет скачана, если доступна), оставьте пустым по умолчанию

 `product.agent.log_level` - уровень логирования агента (применяется при установке)
`product.cyberfiles_gateway.linux.log_level` - уровень логирования gateway (применяется при установке)

 `product.web_server.linux.installers` - бинари для установки сервера, оставьте пустым по умолчанию
`product.cyberfiles.linux.installers` - бинари для установки сервера КФ, оставьте пустым по умолчанию

 `product.web_server.linux.version` - желаемая версия сервера (будет скачана, если доступна), оставьте пустым по умолчанию
`product.cyberfiles.linux.version` - желаемая версия сервера (будет скачана, если доступна), оставьте пустым по умолчанию

 `product.web_server.log_level` - уровень логирования сервера (применяется при установке)


 Authors

- Pavel.Ivanov@cyberprotect.ru






source .venv/bin/activate
pip freeze > requirements.txt
pip install -r requirements.txt --upgrade
