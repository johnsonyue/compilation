#!/bin/bash

#LOG
log(){
echo $1 >&2;
}
export -f log

#SUB
warts2link(){
test $# -lt 1 && echo 'warts2link $prefix.warts[.tar.gz;.gz]' && exit

input_file_path=$1
prefix=$(echo $input_file_path | sed 's/\.gz$//' | sed 's/\.tar$//' | sed 's/\.warts$//')

log $prefix #debug
echo $prefix

(test ! -z "$(echo $input_file_path | grep -E '\.tar\.gz$')" && tar zxf $input_file_path -O || test ! -z "$(echo $input_file_path | grep -E '\.gz$')" && gzip -cd $input_file_path || cat $input_file_path) | (test ! -z "$(echo $input_file_path | grep -E 'warts')" && sc_warts2text || cat) | perl trace2link.pl -p $prefix -
#output_file_path: $prefix.links
}

link2iface(){
test $# -lt 1 && echo 'link2iface $prefix.links' && exit

input=$1
prefix=$(echo $input | sed 's/\.links$//')

cat $input | python <(
cat << "END"
out={}
while True:
  try:
    line=raw_input()
  except:
    break
  fields = line.split()
  print fields[0] # 'from' must be a router iface
  if not out.has_key(fields[1]):
    out[fields[1]] = fields[2]
  elif fields[2] == "N":
    out[fields[1]] = "N"
for k,v in out.items():
  if v == "N":
    print k
END
) | sort | uniq >$prefix.ifaces
#output_file_path: $prefix.ifaces
}

link_coll(){
test $# -lt 2 && echo 'collapse $aliases $prefix.links' && exit

aliases=$1
links=$2
prefix=$(echo $links | sed 's/\.links$//')

./collapse.sh $aliases $links >$prefix.rtrlinks
#output_file_path: $prefix.rtrlinks
}

#MAIN
usage(){
echo 'run.sh <$command> [$args]'
echo 'COMMANDS:'
echo '  warts2link'
echo '  link2iface'
echo '  link_coll'
}
test $# -lt 1 && usage && exit

cmd=$1
case $cmd in
  "warts2link")
    test $# -lt 2 && usage && exit
    input_file_path=$2;
    
    warts2link $input_file_path
    ;;
  "link2iface")
    test $# -lt 2 && usage && exit
    input=$2;

    link2iface $input
    ;;
  "link_coll")
    test $# -lt 3 && usage && exit
    aliases=$2; links=$3;

    link_coll $aliases $links
    ;;
  *)
    usage
    exit;;
esac
