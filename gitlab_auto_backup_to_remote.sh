#!/bin/bash

# Gitlab服务器备份路径
LocalBackDir=/var/opt/gitlab/backups

# 远程备份服务器Gitlab备份文件目录
RemoteBackDir=/root/gitlab_backup_88

# 远程备份服务器登录账户
RemoteUser=root

# 远程服务器IP
RemoteIP=10.6.1.56

# 当前系统日期
DATE=`date +"%Y-%m-%d"`

# log存放路径
LogFile=$LocalBackDir/log/$DATE.log

# 查找Gitlab本地备份目录下 时间为60分钟之内,并且后缀为.tar的Gitlab备份文件
BACKUPFILE_SEND_TO_REMOTE=$(find $LocalBackDir -type f -mmin -60 -name '*.tar*')

# 新建日志文件
touch $LogFile

# 追加日志到日志文件
echo "Gitlab auto backup to remote server:$RemoteIP" >> $LogFile
echo "---------$(date +"%Y-%m-%d %H:%M:%S") Started---------" >> $LogFile

# 备份到远程服务器
scp $BACKUPFILE_SEND_TO_REMOTE $RemoteUser@$RemoteIP:$RemoteBackDir

# 备份配置文件到远程服务器
scp /etc/gitlab/gitlab.rb $RemoteUser@$RemoteIP:$RemoteBackDir
scp -r /var/opt/gitlab/nginx/conf $RemoteUser@$RemoteIP:$RemoteBackDir
scp /etc/postfix/main.cf $RemoteUser@$RemoteIP:$RemoteBackDir
scp /etc/gitlab/gitlab-secrets.json $RemoteUser@$RemoteIP:$RemoteBackDir

# 追加日志到日志文件
echo "---------$(date +"%Y-%m-%d %H:%M:%S") Finished--------" >> $LogFile
