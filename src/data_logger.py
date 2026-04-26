import json
import os
import time

class DataLogger:
    def __init__(self, frequency=10, filename=None):
        self.frequency = frequency
        if filename:
            self.filename = filename
        else:
            self.filename = f"data_samples/log_{int(time.time())}.jsonl"
            
        os.makedirs(os.path.dirname(os.path.abspath(self.filename)), exist_ok=True)
        self.records = []

    def log_step(self, simulator_time, task_count, agents):
        import math
        step_data = {
            "time": simulator_time,
            "task_count": task_count,
            "agents": []
        }
        for agent in agents:
            real_speed = math.hypot(agent.linear_velocity[0], agent.linear_velocity[1])
            agent_data = {
                "id": agent.id,
                "x": agent.position.x,
                "y": agent.position.y,
                "angle": agent.angle,
                "speed": real_speed,
                "destination_x": agent.destination_location.x if agent.destination_location else None,
                "destination_y": agent.destination_location.y if agent.destination_location else None
            }
            step_data["agents"].append(agent_data)
        
        self.records.append(step_data)
        
        # Flush to prevent memory getting too large if frequency is high
        if len(self.records) >= 1000:
            self.flush()

    def flush(self):
        if not self.records:
            return
            
        with open(self.filename, 'a') as f:
            for record in self.records:
                f.write(json.dumps(record) + "\n")
        self.records = []

    def export_data(self):
        self.flush()
        print(f"\n[DataLogger] Data export completed. Saved to {self.filename}")
