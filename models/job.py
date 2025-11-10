from datetime import datetime
from enum import Enum

class JobStatus(Enum):
    RUNNING = "running"
    SUCCESS = "success"
    ERROR = "error"
    STOPPED = "stopped"

class Job:
    def __init__(self, job_id, playbook_name, command):
        self.job_id = job_id
        self.playbook_name = playbook_name
        self.command = command
        self.status = JobStatus.RUNNING
        self.start_time = datetime.now()
        self.end_time = None
        self.output = []
        self.process = None

    def add_output(self, line, type="info"):
        self.output.append({
            "timestamp": datetime.now(),
            "line": line,
            "type": type
        })
        if len(self.output) > 1000:
            self.output = self.output[-1000:]

    def complete(self, status, message=None):
        self.status = status
        self.end_time = datetime.now()
        if message:
            self.add_output(message, "success" if status == JobStatus.SUCCESS else "error")