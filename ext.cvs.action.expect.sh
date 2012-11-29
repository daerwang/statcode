#!/bin/bash
# author: lilong'en(lilongen@163.com)
#

cmd=$1
pwd=$2

expect <<EOD
spawn $cmd
expect "password:"
send "$pwd\r"
expect eof
EOD
