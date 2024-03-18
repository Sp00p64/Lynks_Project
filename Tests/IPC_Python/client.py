from multiprocessing.connection import Client

address = ('localhost', 6000)
conn = Client(address, authkey=b'secret password')
conn.send('close')
print(conn.recv())
# can also send arbitrary objects:
# conn.send(['a', 2.5, None, int, sum])
#conn.close()