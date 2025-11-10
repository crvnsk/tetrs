from flask import jsonify
from services.inventory_service import InventoryService

inventory_service = InventoryService()

def init_api_routes(app):
    @app.route('/api/virtual_machines')
    def api_virtual_machines():
        """API endpoint для получения списка ВМ"""
        try:
            virtual_machines = inventory_service.load_inventory_data()
            return jsonify(virtual_machines)
        except Exception as e:
            return jsonify({'error': str(e)}), 500