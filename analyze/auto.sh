#!/bin/bash

#LOG
log(){
echo $1 >&2;
}
export -f log

preprocess_directory(){
test $# -lt 2 && exit

d=$1
test $(ls $d/ | wc -l) -eq 0 && echo "$d is empty" && exit
P=$2 #controll xargs concurrency

#(warts)-[warts2link]->(links)
ll=($(ls $d/*.warts.gz | head -n 4 | xargs -I {} -n 1 -P $P bash -c './run.sh warts2link {}'))

#(links)-[linkmerge]->(links)
echo "merging ${#ll[*]} files" >&2
for l in ${ll[*]}; do
  echo $l.links
done | perl linkmerge.pl >$d/$(basename $d).merged.links
echo "$d/$(basename $d).merged.links" >&2
#remove link
for l in ${ll[*]}; do
  echo "rm $l.links" >&2
  rm $l.links
done
}

#MAIN
usage(){
echo 'auto.sh <$command> [$args]'
echo 'COMMANDS:'
echo '  process_caida_date <$directory> [$parallel=4]'
echo '  process_vps_date <$warts_file_path> <$iffinder_file_path>'
}
test $# -lt 1 && usage && exit

cmd=$1
case $cmd in
  #
  # (warts)-[warts2link]->(links)-[linkmerge]->(links)
  # (links)-[link2iface]->(ifaces)
  # (ifaces)-[ar]->(aliases)
  # (aliases+links)-[linkcoll]->(rtrlinks)
  #
  "process_caida_date")
    test $# -lt 2 && usage && exit
    directory=$2; parallel=${3:=6}
    prefix=$directory/$(basename $directory)

    preprocess_directory $directory $parallel
    #link2iface $prefix.merged.links
    #../scanner/prober ar $prefix.merged.ifaces
    #link_coll $prefix.merged.aliases $prefix.merged.links
    ;;
  "process_vps_date")
    test $# -lt 3 && usage && exit
    warts_file_path=$2; iffinder_file_path=$3; 
    prefix=$(echo $input_file_path | sed 's/\.gz//' | sed 's/\.tar//')

    ./run.sh warts2link $warts_file_path
    ./run.sh link2iface $prefix.links
    tar zxf $iffinder_file_path -O | awk '$6 == "D" {print $1" "$2}' >$prefix.aliases
    ./run.sh link_coll $prefix.aliases $prefix.links
    ;;
  *)
    usage
    exit;;
esac
