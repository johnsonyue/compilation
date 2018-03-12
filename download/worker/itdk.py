import os
import re
import sys
import time
import math
import json
import urllib2
import HTMLParser

import multi_thread
import utils

#html parsers
class CaidaParser(HTMLParser.HTMLParser):
  def __init__(self):
    HTMLParser.HTMLParser.__init__(self)
    self.img_cnt=0
    self.alt=""
    self.file=[]
    self.dir=[]

  def get_attr_value(self, target, attrs):
    for e in attrs:
      key = e[0]
      value = e[1]
      if (key == target):
        return value

  def handle_starttag(self, tag, attrs):
    if (tag == "img"):
      if (self.img_cnt >=2):
        alt_value = self.get_attr_value("alt", attrs)
        self.alt=alt_value
      self.img_cnt = self.img_cnt + 1
    
    if (tag == "a" and self.alt == "[DIR]"):
      href_value = self.get_attr_value("href", attrs)
      self.dir.append(href_value)
    elif (tag == "a" and self.alt != ""):
      href_value = self.get_attr_value("href", attrs)
      self.file.append(href_value)

def get_file_list_from_directory(url):
  opener = utils.get_caida_opener(utils.caida_itdk_base_url)

  f = opener.open(url)
  text = f.read()
  parser = CaidaParser()
  parser.feed(text)
  
  return parser.file

def get_caida_file_size(url, opener):
  request=urllib2.Request(url)
  request.add_header("Range", "bytes=0-10737418240")
  try:
    f = opener.open(request)
    res = int(f.info()["Content-Length"])
    f.close()
    print res, str(res/1024/1024)+" MB"
  except:
    print "remote file not found: "+url
    return -1

  return res

def download_caida_restricted_wrapper(argv, resource):
  url=argv[0]
  start=argv[1]
  end=argv[2]
  file_path=argv[3]
  opener=argv[4]
  
  return download_segemented_caida_restricted_worker(url, start, end, file_path, opener)

def download_segemented_caida_restricted_worker(url, start, end, file_path, opener):
  request=urllib2.Request(url)
  request.add_header( "Range", "bytes="+str(start)+"-"+str(end) )
  request.add_header("User-agent", "Mozila/5.0")

  res = True
  ex = ''
  try:
    utils.log("downloading: "+url+" "+str(start/1024)+"K"+"-"+str(end/1024)+"K")
    if not os.path.exists(file_path):
      f = opener.open(request, timeout=10)
      fp = open(file_path, 'wb')
      fp.write(f.read())
      fp.close();f.close()
  except Exception, e:
    utils.log(str(e))
    res = False
    ex = e
    if os.path.exists(file_path):
      os.remove(file_path)
  
  if res:
    utils.log( str(url.split('/')[-1]) + ' ' + str(res) + str(ex) )
  
  return res

def assemble_segements(file_path):
  utils.log( "assembling segements ..." )

  file_list = os.listdir(utils.dir_name(file_path))
  num_file = 0
  for fn in file_list:
    if(re.findall(utils.file_name(file_path)+".\d+", fn)):
      num_file = num_file + 1
  
  fp = open(file_path, 'wb')
  for i in range(num_file):
    fn = file_path+'.'+str(i)
    f = open(fn, 'rb')
    fp.write(f.read())
    f.close()
    os.remove(file_path+'.'+str(i))
  
  fp.close()
  utils.log( "finished assembling segements" )

def download_file(url, file_path, resources, mt_num, seg_size=20*1024*1024):
  opener = utils.get_caida_opener(utils.caida_itdk_base_url)

  #get the size and segment number first.
  file_size = get_caida_file_size(url, opener)
  if file_size == -1:
    return
  utils.log( 'file_size: ' + str(file_size) )
  file_num = int(math.ceil(float(file_size)/seg_size))
  if file_num == 0:
    return

  #get the range list.
  range_list = []
  for i in range(0,file_num-1):
    range_list.append((i*seg_size, (i+1)*seg_size-1))
  if (file_num == 1):
    i = -1
  range_list.append(((i+1)*seg_size, file_size))
  
  #build argv_list.
  argv = []
  for i in range(len(range_list)):
    r=range_list[i]
    arg=( url,r[0],r[1],file_path+'.'+str(i),opener )
    argv.append(arg)
  
  #run with multi thread.
  multi_thread.run_with_multi_thread(download_caida_restricted_wrapper, argv, resources, mt_num)
  
  #assemble segements.
  assemble_segements(file_path)

def download_directory(url, directory, mt_num=-1):
  #get file list.
  is_succeeded = False
  round_cnt = 1
  while(not is_succeeded):
    try:
      file_list=get_file_list_from_directory(url)
      is_succeeded = True
    except Exception, e:
      utils.log(str(e))
      is_succeed = False
      round_cnt = round_cnt + 1
      time.sleep(1*round_cnt)

  utils.touch(directory+'/')

  #resource list
  resources = ['']

  for f in file_list:
    download_file(utils.url_join([url,f]), utils.path_join([directory,f]), resources, mt_num)
