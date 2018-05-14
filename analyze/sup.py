import sys
import socket
import struct

#
# ARGS:
#    "<source list>" "<destination list>"
# read from STDIN: sorted edge list
#        IN OUT [...]
#

#sub
def ip_str2int(ip):
  packedIP = socket.inet_aton(ip)
  return struct.unpack("!L", packedIP)[0]

def ip_int2str(i):
	return socket.inet_ntoa(struct.pack('!L',i)) 

def dfs(p,pi,n):
  if pi!=None and el[pi][3] == 1: #sup
    return 1
  if pi!=None and (el[pi][2] == 1 or el[pi][1] in p): #dead
    return 0
  if len(p) > 10:
    return 0

  is_sup = False
  if n in dl:
    is_sup = True
  elif ind.has_key(n):
    i = ind[n]
    while i<len(el) and el[i][0] == n:
      if (dfs(p + [n], i, el[i][1])):
        is_sup = True
      i+=1

  if pi!=None:
    if is_sup:
      el[pi][3] = 1
      print ' '.join(map(ip_int2str,el[pi][:2]))
      return 1
    else:
      el[pi][2] = 1
      return 0

#main
sl = map(ip_str2int, raw_input().split()) #source list
dl = map(ip_str2int, raw_input().split()) #destination list
#print len(sl),len(dl)

el = [] #edge list
while True:
  try:
    line=raw_input().strip()
  except:
    break
  fl=line.split()
  el.append([ip_str2int(fl[0]),ip_str2int(fl[1]),0,0])

p = None #previous src
ind = {} #node index
for i in range(len(el)):
  e = el[i]
  if e[0] != p:
    ind[e[0]] = i
  p=e[0]

for s in sl:
  dfs([],None,s)
