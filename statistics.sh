#!/bin/bash

# 
# 全局变量 
#
# 引入配置文件
source settings.py
# 访问地址
url="http://web.sofyun.com.cn/v1/systemconfig"


#
# 通用
#
# 计算CPU使用率
CPU_USE=`top -bn 1 -i |grep Cpu |awk '{print $2+$4}'`
# 计算内存使用率
if [ $MEN_TYPE -eq 1 ];then
    MEN_USE=`free |grep Mem|awk '{print ($2-$4-$6)/$2*100}'`
else
    MEN_USE=`free |grep Mem|awk '{print ($2-$4-$6-$7)/$2*100}'`
fi
# 计算磁盘使用率
DISK_USE=`df |grep vda1|awk '{print $5}'|awk -F '%' '{print $1}'`
# 发送到日志中心
arg=${CPU_USE}-${MEN_USE}-${DISK_USE}
`curl -d "name=${NAME}&subname=${SUBNAME}&arg=${arg}" $url`


#
# 外网
#
# 统计api.log的数量
if [[ "${TYPE[@]}" =~ 2 ]];then
    API_COUNTS=`tail -n 100000 /var/log/nginx/api.log |grep $1 |grep -v ' 403 '|wc |awk '{print $1}'`
    # 统计weixin.log的数量
    WX_COUNTS=`tail -n 100000 /var/log/nginx/weixin.log |grep $1 |grep -v ' 403 '|wc |awk '{print $1}'`
    # 统计hq.log的数量
    HQ_COUNTS=`tail -n 100000 /var/log/nginx/hq.log |grep $1 |grep -v ' 403 '|wc |awk '{print $1}'`

    # 发送到日志中心
    arg_api=api-${API_COUNTS}
    `curl -d "name=${NAME}&subname=${SUBNAME}&arg=${arg_api}" $url`
    arg_wx=wx-${WX_COUNTS}
    `curl -d "name=${NAME}&subname=${SUBNAME}&arg=${arg_wx}" $url`
    arg_hq=hq-${HQ_COUNTS}
    `curl -d "name=${NAME}&subname=${SUBNAME}&arg=${arg_hq}" $url`
fi


#
# 内网服务器
#
if [[ "${TYPE[@]}" =~ 1 ]];then
    # 发送MongoDb状态日志
    MongoStatus=`ps -ef |grep mongo|grep -v grep|awk '{print $1}' |wc -L`
    if [ $MongoStatus -eq 0  ];then
        `sudo mongod -f /etc/mongod.conf --fork`
        `curl -d "name=${NAME}&subname=${SUBNAME}&arg=error" $url`
    fi
fi
