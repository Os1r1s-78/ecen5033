#!/usr/bin/python3

import hashlib
import time
import sys

#Default Values
n = 6 #number of leading zeroes 
filename = "preimage.txt"
identikey="aaku8856-mifr0750" # Aakash Kumar and Miles Frain

if len(sys.argv) > 2:
    # Or input from command line as string
    identikey = sys.argv[1]
    n = int(sys.argv[2])

if len(sys.argv) > 1:
    # Or input from command line as string
    identikey = sys.argv[1]

i=0
firstn = ""
zeroes = ""

for j in range(n):
    zeroes+="0"

start_time = time.time()

while(firstn!=zeroes):
    tohash = (identikey+"-"+str(i)).encode() # append number at end of given string
    cur_hash=hashlib.sha256(tohash).hexdigest() #calculate hash
    firstn=cur_hash[0:n] #get first n hex chars of the hash
    i+=1

result = str(tohash,'utf-8')+" "+cur_hash
fh = open(filename,"w")
fh.write(result)
print(result)

end_time = time.time()
print("time taken:",int(end_time-start_time),"secs")