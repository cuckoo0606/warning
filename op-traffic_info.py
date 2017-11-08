# !/usr/lib/env python
# -*- encoding:utf-8 -*-

# Auhtor: cuckoo
# Email: skshadow0606@gmail.com
# Create Date: 2017-10-18 16:18:18


'''
    统计的日志:
        /var/log/nginx/*.log, 包括不限于api, hq, weixin等
'''


import os
import time
import arrow


def job():
    n = arrow.now()
    s = n.replace(minutes=-1)
    # 通过本地导入参数
    now = s.format('DD/MMM/YYYY:HH:mm')
    cmd = './statistics.sh {0}'.format(now)
    os.system(cmd)
    # os.system('echo "" >> /var/log/traffic/info.log')


if __name__ == '__main__':
    while 1:
        job()
        time.sleep(60)
