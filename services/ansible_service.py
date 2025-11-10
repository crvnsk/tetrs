import subprocess
import threading
import uuid
import os
from models.job import Job, JobStatus
from services.monitoring_service import send_message
from utils.file_utils import load_ansible_vars, save_ansible_vars

class AnsibleService:
    def __init__(self):
        self.current_job = None
        self.job_history = []

    def run_playbook(self, playbook_path, inventory_file='dev_inventory.ini', target_vms='all'):
        """Запускает Ansible плейбук"""
        cmd = ['ansible-playbook', '-i', inventory_file, playbook_path]

        if target_vms != 'all':
            cmd.extend(['--limit', target_vms])

        thread = threading.Thread(target=self._run_in_thread, args=(cmd, os.path.basename(playbook_path)))
        thread.daemon = True
        thread.start()
        return True

    def _run_in_thread(self, cmd, playbook_name):
        """Запускает Ansible в отдельном потоке"""
        job_id = str(uuid.uuid4())
        self.current_job = Job(job_id, playbook_name, ' '.join(cmd))

        try:
            send_message('start', {
                'job_id': job_id,
                'playbook': playbook_name,
                'command': ' '.join(cmd)
            })
            self.current_job.add_output(f"Запуск плейбука: {playbook_name}", "info")

            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
                universal_newlines=True
            )

            self.current_job.process = process

            for line in iter(process.stdout.readline, ''):
                if line.strip():
                    send_message('output', {'job_id': job_id, 'line': line.strip()})
                    self.current_job.add_output(line.strip(), "info")

            process.stdout.close()
            return_code = process.wait()

            stderr_output = process.stderr.read()
            if stderr_output:
                send_message('error', {'job_id': job_id, 'output': stderr_output})
                self.current_job.add_output(stderr_output, "error")

            if return_code == 0:
                success_msg = f'Плейбук {playbook_name} выполнен успешно'
                send_message('success', {'job_id': job_id, 'message': success_msg})
                self.current_job.complete(JobStatus.SUCCESS, success_msg)
            else:
                error_msg = f'Плейбук {playbook_name} завершился с ошибкой (код: {return_code})'
                send_message('error', {'job_id': job_id, 'message': error_msg})
                self.current_job.complete(JobStatus.ERROR, error_msg)

        except Exception as e:
            error_msg = f'Ошибка выполнения: {str(e)}'
            send_message('error', {'job_id': job_id, 'message': error_msg})
            self.current_job.complete(JobStatus.ERROR, error_msg)
        finally:
            if self.current_job:
                self.job_history.append(self.current_job)
                if len(self.job_history) > 10:
                    self.job_history.pop()
                self.current_job = None

    def stop_current_job(self):
        """Останавливает текущее задание"""
        if self.current_job and self.current_job.process:
            try:
                self.current_job.process.terminate()
                self.current_job.complete(JobStatus.STOPPED, "Задание остановлено пользователем")
                send_message('error', {
                    'job_id': self.current_job.job_id,
                    'message': 'Задание остановлено пользователем'
                })
                return True
            except Exception as e:
                return False
        return False

    def get_current_job_status(self):
        """Возвращает статус текущего задания"""
        if self.current_job:
            return {
                "job_id": self.current_job.job_id,
                "playbook_name": self.current_job.playbook_name,
                "command": self.current_job.command,
                "status": self.current_job.status.value,
                "start_time": self.current_job.start_time.isoformat(),
                "end_time": self.current_job.end_time.isoformat() if self.current_job.end_time else None,
                "output": self.current_job.output[-50:],
                "is_active": self.current_job.status == JobStatus.RUNNING,
                "active": True
            }
        return {"active": False}

    def update_debug_mode(self, debug_value):
        """Обновляет режим отладки в group_vars"""
        ansible_vars = load_ansible_vars()
        ansible_vars['debug_mode'] = debug_value
        save_ansible_vars(ansible_vars)

    def get_debug_mode(self):
        """Получает текущий режим отладки"""
        ansible_vars = load_ansible_vars()
        return ansible_vars.get('debug_mode', False)