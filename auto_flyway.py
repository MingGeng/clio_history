#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import sys

db_name = sys.argv[1]
cmd = sys.argv[2]
config = {}

#read config for db to set flyway reading tmp.conf
with open('env_db.conf') as urls:
           for line in urls.readlines():
               try:
                   config[line.split('=')[0].strip(' ')] = line.split('=')[1].strip(' ').strip('\n')
               except:
                   print('Config format is incurrent!')
                   raise Exception('Config format is incurrent!')


os.system("echo  flyway.url=" + config[db_name + '_url'] + ' > tmp.conf'        )
os.system('echo flyway.locations=' + config[db_name + '_locations'] + ' >> tmp.conf')
os.system('echo flyway.user=root >> tmp.conf')
os.system('echo flyway.password=Abcd1234 >> tmp.conf')
os.system('./flyway -configFile=/app/flyway-4.2.0/tmp.conf ' + cmd  )






