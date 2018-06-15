#!/bin/bash

#环境名称数组
array=(DEV_52 DEV_205 Hotfix_156 UAT_129 DEV_136 UAT_66 UAT_55 STG_102 UAT_77 SH_4) 

# 当前系统日期
DATE=`date +"%Y-%m-%d"`

# log存放路径
#LogFile=diskWarning_$DATE.log
echo "" > /app/go_ansible/log/diskWarning_$DATE.log
echo > ./log/rootDiskStat_$DATE.log
#遍历环境名称,ansible输出环境警报日志
for data in ${array[@]}  
do  
    EnvName=${data}  
    echo "Start $EnvName checking..."
    echo -e "##############[$EnvName]################### \n----------------------------------------"  >> /app/go_ansible/log/diskWarning_$DATE.log

    #ansible 输出磁盘占用超过80%的VM信息
    ansible -i /app/go_ansible/hosts all --limit $EnvName  -m shell -a "df -hT" | grep -e "[8-9][0-9]%" -e "100%" -e "10.* |" | grep -B 1 -e "%" >> /app/go_ansible/log/diskWarning_$DATE.log
    echo -e "################[$EnvName]################## \n--------------------------------------" >> ./log/rootDiskStat_$DATE.log
    ansible -i hosts all --limit $EnvName -m shell -a "df -hT" | grep -B 1 -A 1 -e "VG00-lvroot" -e "/dev/mapper/vg01-LogVol00" -e "/dev/mapper/rootvg-rootlv" -e "10.* |" | grep -B 3 -w "/" | grep  -v "/app" | grep -e "[7-9][0-9]%" -e "100%" -e "10.* |" | grep -B 1 -e "%"  >> ./log/rootDiskStat_$DATE.log

    echo -e "-----------------------------------------\n\n"  >> /app/go_ansible/log/diskWarning_$DATE.log
    echo -e "-----------------------------------------\n\n"  >> ./log/rootDiskStat_$DATE.log
    echo "Finished $EnvName"
done

#cat diskWarning_$DATE.log | grep -B 1 -A 1 "10.* |" | grep -e "_" -e "10.*"
#cat diskWarning_$DATE.log | grep -B 1 "10.* |" | grep -e "_" -e "10.*" | awk "{if(NR!=0){print $1}}"
cat /app/go_ansible/log/diskWarning_$DATE.log | grep -B 1 "10.* |" | grep -e "_" -e "10.*"

