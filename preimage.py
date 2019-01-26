import hashlib
import time

#Change this n for number of hex 0s at start
n = 6
filename = "preimage.txt"

# Aakash Kumar and Miles Frain
identikey="aaku8856-mifr0750"

fh = open(filename,"w")
i=0
firstn = ""
zeroes = ""

for j in range(n):
    zeroes+="0"

start_time = time.time()

while(firstn!=zeroes):
    tohash = (identikey+"-"+str(i)).encode()
    cur_hash=hashlib.sha256(tohash).hexdigest()
    firstn=cur_hash[0:n]
    i+=1

result = str(tohash,'utf-8')+" "+cur_hash
fh.write(result)
print(result)

end_time = time.time()
print("time taken:",end_time-start_time,"secs")