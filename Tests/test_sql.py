import sqlite3

conn = sqlite3.connect('../project.db')
cursor = conn.execute("SELECT client from orders")
agents=[]
for row in cursor:
    agents.append(row[0])
print(agents)