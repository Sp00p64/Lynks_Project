from multiprocessing.connection import Listener

address = ('localhost', 6000)     # family is deduced to be 'AF_INET'
listener = Listener(address, authkey=b'secret password')
conn = listener.accept()
print('connection accepted from', listener.last_accepted)
while True:
    msg = conn.recv()
    print("Received: "+msg)
    # do something with msg
    if msg == 'close':
        conn.send("Closing")
        conn.close()
        break
listener.close()