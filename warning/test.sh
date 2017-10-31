#!/bin/bash
# Program
#    
# History
# 
# Auhtor: cuckoo
# Email: skshadow0606@gmail.com
# Create Date: 2017-10-30 10:16:49


i=`ps -ef |grep mongo|grep -v grep|awk '{print $1}'`
if [ -n i ];then
    echo "不为0"
else
    echo "空的"   
fi
