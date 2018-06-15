Ansible日志自动清理.md
## 深圳集群控制脚本: 10.6.6.159:/app/go_ansible/auto_clear.sh    检测脚本: auto_check.sh 
## 上海集群控制脚本: 10.6.0.168:/app/ming/auto_clear.sh   检测脚本: auto_check.sh 
### 脚本依赖系统安装ansible, 以及目录hosts 文件;
#### 通过定时任务执行, 定时任务需要用root设定/修改
	 展示定时任务: crontab -l
	 编辑定时任务: crontab -e
	 每次修改后需要重启定时任务才能生效: service crond restart
	

auto_clear.sh  of  10.6.6.159

```
#!/bin/bash

#环境名称数组
array=(DEV_52 DEV_205 Hotfix_156 UAT_129 DEV_136 UAT_66 UAT_55 STG_102 UAT_77 SH_4) 

# 当前系统日期
DATE=`date +"%Y-%m-%d"`
echo "" > /app/go_ansible/log/autoClear_$DATE.log
#遍历环境名称,ansible输出环境警报日志
for data in ${array[@]}  
do  
    EnvName=${data}  
    echo "Start $EnvName cleaning..."
    echo   "-----------------[$EnvName]--NEED TO CLEAN---------------------"  >> /app/go_ansible/log/autoClear_$DATE.log

#    ansible -i hosts_root all --limit $EnvName -m shell -a "find /app -name catal*.out | xargs truncate -s 0"
#    ansible -i hosts_root all --limit $EnvName -m shell -a "du -sh $(find /app -type f -size +500M)"
#    tmpset=$( ansible -i hosts_root all --limit $EnvName -m shell -a " du -sh \$(find /app -type f -size +500M) " ) 
#    echo $tmpset
#    ansible -i hosts_root all --limit $EnvName -m shell -a "du -sh \$(find /app -type f -size +500M)"
#    ansible -i hosts_root all --limit $EnvName -m shell -a "ls -lsh \$(find /app -type f -size +500M) | sort -nr" >> autoClear_$DATE.log

#清空(不要rm,否则需要重启占用该文件的进程才能释放空间)大小大于1G的catalina.out
    ansible -i /app/go_ansible/hosts all --limit $EnvName -m shell -a "find /app -name catalina.out -type f -size +500M | xargs truncate -s 0; find /app -name 'catalina.*.
log' -type f -mtime +7 | xargs truncate -s 0 ; rm -f \$(find /app -name 'catalina.*.log' -type f -mtime +60) ; find /app -name '*.log.*' -type f -size +500M | xargs trunca
te -s 0 ; find /app -name '*.log.*' -type f -mtime +3 | xargs truncate -s 0 ; rm -f \$(find /app -name '*.log.*' -type f -mtime +60) ; find /app -name '*.log' -type f -siz
e +2048M | xargs truncate -s 0;  echo '' > /app/webserver/hydra-manager/log/Benchtest.log; echo '' > /app/imodule/service/finance/logs/finance.log; echo '' > /app/logs/arb
iter.log; echo '' > /app/webserver/zookeeper.out; echo ''  > /app/imodule/web/tomcat-claim/bin/logs/imodule-claim-web.log; find /app -name '1.txt' -type f -size +500M | xa
rgs truncate -s 0 ;echo  '' > /app/imodule/service/notify/notify.log;" > /dev/null 2>&1

#    ansible -i hosts all --limit $EnvName -m shell -a "find /app -name catalina.out | xargs truncate -s 0;"

    ansible -i /app/go_ansible/hosts_root all --limit $EnvName -m shell -a "find /app -name catalina.out -type f -size +500M | xargs truncate -s 0; find /app -name 'catali
na.*.log' -type f -mtime +3 | xargs truncate -s 0 ; rm -f \$(find /app -name 'catalina.*.log' -type f -mtime +10) ; find /app -name '*.log.*' -type f -mtime +7 | xargs tru
ncate -s 0 ; rm -f \$(find /app -name '*.log.*' -type f -mtime +10) ; find /app -name '*.log' -type f -size +588M | xargs truncate -s 0;   "  > /dev/null 2>&1


#清空(不要删除)创建时间超过10天的日志文件,后续跟进情况关掉进程再删除文件
#删除超过7天的日志,预计60天内进程会重启过,通过 lsof | grep deleted 查看已删除但被占用的文件 重启进程来释放空间 
#    echo "超过7天前的日志自动清空,请自行查看文件是否被进程占用后自行删除"
#    ansible -i hosts_root all --limit $EnvName -m shell -a "find /app -name '*.log.*' -type f -mtime +7 | xargs truncate -s 0 ; rm -f \$(find /app -name '*.log.*' -type f
 -mtime +60)  "

#TODO
#删除.*.swp文件
#清空*.log 
#catalina.*.log按时间清空
#清空*.out
#--Benchtest.log 按大于1G清空
#imodule-claim-web.log
#finance.log


#输出/app 下考虑清理的大于500M文件的大小和文件名
    ansible -i hosts all --limit $EnvName -m shell -a "du -sh \$(find /app -type f -size +500M) | sort -nr" >> /app/go_ansible/log/autoClear_$DATE.log
    echo -e "-----------------------------------------------------\n"  >> /app/go_ansible/log/autoClear_$DATE.log
    echo "Finished $EnvName"
done

cat /app/go_ansible/log/autoClear_$DATE.log

```
