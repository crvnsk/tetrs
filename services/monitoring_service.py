import queue
import time
import json
from flask import Response, jsonify

message_queue = queue.Queue()

def send_message(message_type, data):
    """Отправляет сообщение в очередь"""
    message = {
        'type': message_type,
        'data': data,
        'timestamp': time.time()
    }
    message_queue.put(message)

def init_monitoring(app):
    """Инициализация эндпоинтов мониторинга"""

    @app.route('/events')
    def events():
        """Server-Sent Events endpoint для мониторинга в реальном времени"""
        def generate():
            while True:
                try:
                    message = message_queue.get(timeout=30)
                    yield f"data: {json.dumps(message)}\n\n"
                except queue.Empty:
                    yield "data: {\"type\": \"keepalive\"}\n\n"

        return Response(generate(), mimetype='text/event-stream')

    @app.route('/job_status')
    def job_status():
        """Возвращает статус текущего задания"""
        from services.ansible_service import AnsibleService
        ansible_service = AnsibleService()
        status = ansible_service.get_current_job_status()
        return jsonify(status)  # ← Теперь jsonify доступен
