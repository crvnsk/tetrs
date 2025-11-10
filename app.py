from flask import Flask, jsonify
import os
from config import Config
from routes.main_routes import init_routes
from routes.api_routes import init_api_routes
from routes.build_routes import init_build_routes
from services.monitoring_service import init_monitoring

app = Flask(__name__)
app.config.from_object(Config)

# Инициализация маршрутов
init_routes(app)
init_api_routes(app)
init_build_routes(app)
# Инициализация мониторинга
init_monitoring(app)

@app.route('/debug/test')
def debug_test():
    """Отладочный маршрут для проверки работы"""
    return jsonify({
        'status': 'ok',
        'message': 'Flask работает',
        'inventory_file': os.path.exists('dev_inventory.ini'),
        'playbooks_exist': {
            'download': os.path.exists('playbooks/downloader/product_download_installers.playbook.yml'),
            'full_install': os.path.exists('playbooks/product_full_install.playbook.yml'),
            'cf_install': os.path.exists('playbooks/product_cf_server_install.playbook.yml'),
            'gw_install': os.path.exists('playbooks/product_gw_install.playbook.yml')
        }
    })

if __name__ == '__main__':
    print("=== ЗАПУСК ПРИЛОЖЕНИЯ ===")
    try:
        app.run(host='0.0.0.0', port=5000, debug=True, threaded=True)
    except Exception as e:
        print(f"ОШИБКА ПРИ ЗАПУСКЕ: {e}")
        import traceback
        traceback.print_exc()
