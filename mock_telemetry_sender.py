import websocket
import json
import time
import random

SERVER_IP = "ws://10.186.103.20:8080"

statuses = ["idle", "standing", "working"]
locations = ["corridor", "living room", "kitchen", "bedroom"]

def send_mock_data():
    while True:
        try:
            ws = websocket.WebSocket()
            ws.connect(SERVER_IP)
            print("Telemetry connected")

            while True:
                data = {
                    "type": "telemetry",
                    "battery": random.randint(20, 100),
                    "status": random.choice(statuses),
                    "location": random.choice(locations)
                }

                ws.send(json.dumps(data))
                print("Sent:", data)

                time.sleep(3)

        except Exception as e:
            print("Error:", e)
            print("Retrying in 5 seconds...")
            time.sleep(5)

if __name__ == "__main__":
    send_mock_data()
