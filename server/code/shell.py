import websocket
import threading
import time
from progress.spinner import PixelSpinner

from prompt_toolkit.shortcuts import prompt
from prompt_toolkit.styles import Style
import json
style = Style.from_dict({
    # User input (default text).
    '':          '#ffffff',  # Soft grey for neutral text, enhancing readability against most backgrounds

    # Prompt.
    'username': '#8a56e2',  # Soft purple for usernames, offering a friendly and distinguishable appearance
    'at':       '#55acee',  # Light blue, reminiscent of links or clickable elements, for the 'at' symbol
    'colon':    '#ffcc00',  # Warm yellow for colons, adding a spark of color that draws attention to the separation
    'pound':    '#77dd77',  # Soft green for pound symbols, providing a refreshing touch that's easy on the eyes
    'host':     '#ff6b6b bg:#333333',  # Bright red on a dark grey background for hosts, creating a standout effect
    'path':     'ansiwhite underline',  # White with an underline for paths, ensuring clarity and emphasis
})
class ShellControlClient:
    def __init__(self, url):
        self.url = url
        self.message_received = True
        self.wait_time = 10
        self.client_connected = False
        self.client_username = None

    def on_message(self, ws, message):
        try:
            json.loads(message)
            message_is_json = True
        except Exception as error:
            # print("Error is ")
            # print(error)
            message_is_json = False

        if message == "[!] No client listening":
            print("[*] No client is yet available at this time...")

        elif "[*] Client is listening".lower() in message.lower():
            print("")
            print("[*] Client has just connected")
            self.client_connected = True
            
        elif message_is_json:
            json_message = json.loads(message)
            try:
                self.client_username = json_message['user'].strip("\n")
            except:
                self.client_username = None
        else:
            print(f"\n{message}")
            self.message_received = True
            if hasattr(self, 'response_timer'):
                self.response_timer.cancel()  # Cancel the timer when message is received

    def on_error(self, ws, error):
        print("Error: " + str(error))

    def on_close(self, ws, close_status_code, close_msg):
        print("### Connection Closed ###")

    def wait(self):
        time.sleep(0.5)
        spinner = PixelSpinner('[*] Waiting for a client to connect ')
        print("")
        while True:
            if self.client_connected == False:
                spinner.next()
                time.sleep(0.1)
            else:
                spinner.finish()
                break


    def on_open(self, ws):
        def run(*args):
            while True:
                if self.client_connected and self.message_received:
                    message = [
                        ('class:username', self.client_username.upper() if self.client_username != None else '?'),
                        # ('class:colon',    ':'),
                        # ('class:path',     '/user/john'),
                        ('class:pound',    ' > '),
                    ]
                    command = prompt(message, style=style)
                    if len(command) > 0:
                        #print("command is " + command)
                        self.message_received = False
                        # if command:
                        #     exit()
                        ws.send(command)
                        # Start a timer that waits for 5 seconds for a response
                        self.response_timer = threading.Timer(self.wait_time, self.check_response)
                        self.response_timer.start()
            #time.sleep(0.1)  # Small delay to prevent high CPU usage
        thread = threading.Thread(target=run)
        thread.start()

    def check_response(self):
        if not self.message_received:
            print(f"No response received in {self.wait_time} seconds, try again.")
            self.message_received = True  # Reset to allow sending a new command

    def run_forever(self):
        websocket.enableTrace(False)
        ws_app = websocket.WebSocketApp(self.url,
                                        on_open=self.on_open,
                                        on_message=self.on_message,
                                        on_error=self.on_error,
                                        on_close=self.on_close)
        ws_app.run_forever()

if __name__ == "__main__":
    client = ShellControlClient("ws://localhost:4242/shell_control")
    thread = threading.Thread(target=client.wait)
    thread.start()
    client.run_forever()
