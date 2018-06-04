#!/bin/bash
vp_conf(){
  cat config.json | tr '\n' ' ' | python -c "import json,sys; o=json.loads(raw_input()); [sys.stdout.write(k+' '+v+'\n') for k,v in o['manager']['vp']['$1'].items()]" \
  | grep $2 | cut -d' ' -f2
}

# traceroute
start_probe(){
  vp=$1
  probe_cmd=$2
  input_filepath=$3
  
  case $probe_cmd in
    "tr" | "ar")
      remote_file_on_vp $vp send $input_filepath
      ;;
    "check")
      ;;
    "*")
      usage
      exit
      ;;
  esac

  expect -c "set timeout -1
  spawn ssh $username@$ip -p $ssh_port \"$code_dir/prober $probe_cmd $data_dir/$(basename $input_filepath)\"
  expect -re \".*password.*\" {send \"$password\r\"}
  expect eof"
}

remote_file_on_vp(){
  vp=$1
  file_cmd=$2

  case $file_cmd in
    "send")
      test $# -lt 3 && usage && exit
      
      filepath=$3

      expect -c "set timeout -1
      spawn ssh $username@$ip -p $ssh_port \"mkdir -p $data_dir\"
      expect -re \".*password.*\" {send \"$password\r\"}
      expect eof"

      expect -c "set timeout -1
      spawn scp -C -P $ssh_port $filepath $username@$ip:$data_dir
      expect -re \".*password.*\" {send \"$password\r\"}
      expect eof"
      ;;
    "fetch")
      test $# -lt 4 && usage && exit
      
      filename=$3; directory=$4

      expect -c "set timeout -1
      spawn rsync -avrt --copy-links -e \"ssh -p $ssh_port\" $username@$ip:$data_dir/$filename $directory
      expect -re \".*password.*\" {send \"$password\r\"}
      expect eof"
      ;;
    "delete")
      test $# -lt 3 && usage && exit
      
      filename=$3;

      expect -c "set timeout -1
      spawn ssh $username@$ip -p $ssh_port \"rm $data_dir/$filename\"
      expect -re \".*password.*\" {send \"$password\r\"}
      expect eof"
      ;;
    "*")
      ;;
  esac
}

usage(){
  echo "run.sh <\$vp> <\$commands> [\$args...]"
  echo "COMMANDS:"
  echo "  target <\$prefix>"
  echo "  start_probe tr/ar <\$input_filename>"
  echo "  start_probe check <\$input_fileprefix>"
  echo "  remote_file send <\$filepath>"
  echo "  remote_file fetch <\$filename> <\$directory>"
  echo "  remote_file delete <\$filename>"
}

test $# -lt 2 && usage && exit

vp=$1
username=$(vp_conf $vp username); ip=$(vp_conf $vp ip); ssh_port=$(vp_conf $vp ssh_port); printf -v password "%q" "$(vp_conf $vp password)";
data_dir=$(vp_conf $vp data_dir); code_dir=$(vp_conf $vp code_dir);

cmd=$2
case $cmd in
  "target")
    test $# -lt 1 && usage && exit
    
    prefix=$2
    mkdir -p $(dirname prefix)

    cd target/
    ./target.sh gen_target_from_geodb -p $prefix
    cd ../
    ;;
  "start_probe")
    test $# -lt 4 && usage && exit
    start_probe $vp $3 $4
    ;;
  "remote_file")
    test $# -lt 2 && usage && exit
    remote_file_on_vp $vp "${@:3}"
    ;;
  "*")
    usage
    exit
    ;;
esac
