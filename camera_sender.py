import cv2
import websocket
import time
import numpy

# PC LAN IP from ipconfig
SERVER_IP = "ws://172.23.200.150:8080"

def send_video():
    while True:
        try:
            ws = websocket.WebSocket()
            ws.connect(SERVER_IP)
            print("Connected to WebSocket server.")

            cap = cv2.VideoCapture(0)
            cap.set(cv2.CAP_PROP_FRAME_WIDTH, 320)
            cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 240)

            # Set JPEG quality (0-100, default is 95)
            encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), 50]

            while True:
                ret, frame = cap.read()
                if not ret:
                    print("Failed to grab frame")
                    break

                ret, buffer = cv2.imencode('.jpg', frame, encode_param)
                if not ret:
                    print("Failed to encode frame")
                    continue

                try:
                    # Send the raw JPEG data as a binary message
                    ws.send(buffer.tobytes(), opcode=websocket.ABNF.OPCODE_BINARY)
                except Exception as e:
                    print(f"WebSocket send error: {e}")
                    break # Reconnect

                time.sleep(0.04)  # Aim for ~25 FPS

            cap.release()
            ws.close()

        except Exception as e:
            print(f"An error occurred: {e}")
            print("Retrying in 5 seconds...")
            time.sleep(5)

if __name__ == "__main__":
    send_video()
