import hashlib
import time
zeroes="000000"
identikey="aaku8856-mifr0750"

fh = open("preimage.txt","w")
i=0
first6 = ""

print("start:",time.time())

while(first6!=zeroes):
    tohash = (identikey+"-"+str(i)).encode()
    cur_hash=hashlib.sha256(tohash).hexdigest()
    first6=cur_hash[0:6]
    i+=1

result = str(tohash,'utf-8')+" "+cur_hash
fh.write(result)
print(result)

print("end:  ",time.time())