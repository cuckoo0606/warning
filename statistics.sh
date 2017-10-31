#!/bin/bash

# 引入配置文件
source settings.py

# 读取配置中心数据或本地默认配置
data=`curl http://web.sofyun.com.cn/v1/systemconfig?name="${NAME}" |grep api > a.txt`
echo '-----'
api=`cat a.txt | jq '.api'`
hq=`cat a.txt | jq '.hq'`
wx=`cat a.txt | jq '.wx'`
cpu=`cat a.txt | jq '.cpu'`
men=`cat a.txt | jq '.men'`
disk=`cat a.txt | jq '.disk'`

if [ "$api" -eq 0 ];then
    api=${API}
fi

if [ "$hq" -eq 0 ];then
    hq=${HQ}
fi

if [ "$wx" -eq 0 ];then
    wx=${WX}
fi

if [ "$cpu" == 0 ];then
    cpu=${CPU}
fi

if [ "$men" == 0 ];then
    men=${MEN}
fi

if [ "$disk" -eq 0 ];then
    disk=${DISK}
fi


# 通用
# 计算CPU使用率
CPU_USE=`top -bn 1 -i |grep Cpu |awk '{print $2+$4}'`
# 计算内存使用率
if [ $MEN_TYPE -eq 1 ];then
    MEN_USE=`free |grep Mem|awk '{print ($2-$4-$6)/$2*100}'`
else
    MEN_USE=`free |grep Mem|awk '{print ($2-$4-$6-$7)/$2*100}'`
fi
echo $MEN_USE
# 计算磁盘使用率
DISK_USE=`df |grep vda1|awk '{print $5}'|awk -F '%' '{print $1}'`

# 信息
echo "$1 cpu=${CPU_USE}" >> /var/log/traffic/info.log
echo "$1 men=${MEN_USE}" >> /var/log/traffic/info.log
echo "$1 disk=${DISK_USE}" >> /var/log/traffic/info.log

# 内存使用率
echo "{\"mem\": "${MEN_USE}"}" >> /var/log/traffic/mem.log
# CPU使用率
echo "{\"cpu\": "${CPU_USE}"}" >> /var/log/traffic/cpu.log
# 磁盘使用率
echo "{\"disk\": "${DISK_USE}"}" >> /var/log/traffic/disk.log

# 预警
judge_cpu=$(echo "$CPU_USE > $cpu"|bc)
if [ $judge_cpu -eq 1 ];then
    echo "$1 cpu=${CPU_USE}" >> /var/log/traffic/warning.log
fi

judge_men=$(echo "$MEN_USE > $men"|bc)
if [ $judge_men -eq 1 ];then
    echo "$1 men=${MEN_USE}" >> /var/log/traffic/warning.log
fi

if [ "$DISK_USE" -ge "$disk" ];then
   echo "$1 disk=${DISK_USE}" >> /var/log/traffic/warning.log
fi


# 外网服务器

# 统计api.log的数量
if [[ "${TYPE[@]}" =~ 2 ]];then
    API_COUNTS=`tail -n 100000 /var/log/nginx/api.log |grep $1 |grep -v ' 403 '|wc |awk '{print $1}'`
    # 统计weixin.log的数量
    WX_COUNTS=`tail -n 100000 /var/log/nginx/weixin.log |grep $1 |grep -v ' 403 '|wc |awk '{print $1}'`
    # 统计hq.log的数量
    HQ_COUNTS=`tail -n 100000 /var/log/nginx/hq.log |grep $1 |grep -v ' 403 '|wc |awk '{print $1}'`

    # 信息
    echo "$1 api=${API_COUNTS}" >> /var/log/traffic/info.log
    echo "$1 wx=${WX_COUNTS}" >> /var/log/traffic/info.log
    echo "$1 hq=${HQ_COUNTS}" >> /var/log/traffic/info.log
    
    echo "{\"weixin\": "${WX_COUNTS}"}" >> /var/log/traffic/weixin.log
    echo "{\"api\": "${API_COUNTS}"}" >> /var/log/traffic/api.log
    echo "{\"hq\": "${HQ_COUNTS}"}" >> /var/log/traffic/hq.log

    # 预警
    if [ "$API_COUNTS" -ge "$api" ];then
       echo "$1 api=${API_COUNTS}" >> /var/log/traffic/warning.log
    fi

    if [ "$HQ_COUNTS" -ge "$hq" ];then
       echo "$1 hq=${HQ_COUNTS}" >> /var/log/traffic/warning.log
    fi

    if [ "$WX_COUNTS" -ge "$wx" ];then
       echo "$1 wx=${WX_COUNTS}" >> /var/log/traffic/warning.log
    fi
fi


# 内网服务器
if [[ "${TYPE[@]}" =~ 1 ]];then
    # 判断MongoDB状态
    MongoStatus=`ps -ef |grep mongo|grep -v grep|awk '{print $1}' |wc -L`
    if [ $MongoStatus -eq 0  ];then
        echo "$1 MongoDB状态异常" >> /var/log/traffic/mongo.log
	else
		echo "$1 MongoDB状态正常" >> /var/log/traffic/info.log
    fi
fi
