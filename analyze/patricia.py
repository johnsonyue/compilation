import re
import socket
import struct

'''
Example:
trie = PatriciaTrie()
trie.addString('1.1.1.1/24','AU')
print trie.matchString('1.1.1.9')
print trie.matchString('1.1.2.1')
'''

class Trie:
  def __init__(self):
    self._d = {}

  def addWord(self, w, v):
    p = self._d
    for c in w:
      if not p.has_key(c):
        p[c] = {}
      p = p[c]
    p['data'] = v
  def findData(self, w):
    p = self._d
    dl = []
    for c in w:
      if not p.has_key(c):
        break
      p = p[c]
      if p.has_key('data'):
        dl.append(p['data'])
    return dl
      
class PatriciaTrie:
  def __init__(self):
    self.trie = Trie()

  #helper functions
  def __isIPv4Format__(self,ip):
    f=ip.split('.')
    for o in f:
      if (not re.match("^\d+$",ip)) or int(o)<0 or int(o)>255:
        return False
    return True

  def __ip2int__(self,ip):
    packedIP = socket.inet_aton(ip)
    return struct.unpack("!L", packedIP)[0]
  
  #public methods.
  def addString(self, cidr, value):
    f=cidr.split('/')
    if len(f)<=1:
      return

    ip=f[0]; mask=int(f[1])
    if self.__isIPv4Format__(ip):
      return
    b=bin(self.__ip2int__(ip))[2:].zfill(32)[:mask]
    self.trie.addWord(b,value)

  def matchString(self, ip):
    if self.__isIPv4Format__(ip):
      return
    b=bin(self.__ip2int__(ip))[2:].zfill(32)
    dl=self.trie.findData(b)
    return None if not dl else dl[-1]
