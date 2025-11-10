from flask import render_template, request, flash, redirect, url_for, jsonify
from services.inventory_service import InventoryService
from services.ansible_service import AnsibleService
from services.build_service import BuildService

inventory_service = InventoryService()
ansible_service = AnsibleService()
build_service = BuildService()

def init_routes(app):
    @app.route('/')
    def index():
        selected_builds = build_service.get_selected_builds()
        virtual_machines = inventory_service.load_inventory_data()
        local_builds = build_service.get_local_builds()
        current_job_status = ansible_service.get_current_job_status()
        debug_mode = ansible_service.get_debug_mode()

        monitoring_active = current_job_status.get('active', False)

        return render_template('index.html',
                             selected_builds=selected_builds,
                             debug_mode=debug_mode,
                             virtual_machines=virtual_machines,
                             local_builds=local_builds,
                             monitoring_active=monitoring_active,
                             current_job=current_job_status)

    @app.route('/toggle_debug', methods=['POST'])
    def toggle_debug():
        debug_value = request.form.get('debug') == 'true'
        ansible_service.update_debug_mode(debug_value)

        if debug_value:
            flash('Режим отладки ВКЛЮЧЕН', 'info')
        else:
            flash('Режим отладки ВЫКЛЮЧЕН', 'info')

        return redirect(url_for('index'))

    @app.route('/run', methods=['POST'])
    def run_playbook():
        playbook_file = request.form.get('playbook')
        target_vms = request.form.get('target_vms', 'all')
        inventory_file = request.form.get('inventory_file', 'dev_inventory.ini')

        if not playbook_file:
            flash("Ошибка: не выбран плейбук", 'error')
            return redirect(url_for('index'))

        try:
            ansible_service.run_playbook(playbook_file, inventory_file, target_vms)
            flash('Запущен плейбук с мониторингом в реальном времени', 'info')
        except Exception as e:
            flash(f'Ошибка запуска плейбука: {str(e)}', 'error')

        return redirect(url_for('index'))

    @app.route('/stop_job', methods=['POST'])
    def stop_job():
        if ansible_service.stop_current_job():
            return jsonify({'success': True, 'message': 'Задание остановлено'})
        return jsonify({'success': False, 'message': 'Нет активных заданий'})