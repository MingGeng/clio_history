Gitlab-CE运维手册.md

# 环境准备

我司目前环境
	10.5.1.56  测试刀片
	centOS 6.5
	10.6.0.88 服务器

## Gitlab 官方最低配置要求

CPU : 2core
内存 : 4~6G

实际配置需要根据gitlab 用户人数和负载决定硬件配置;

# Gitlab-CE 安装
通过官网下载RPM包安装
下载地址 https://packages.gitlab.com/gitlab/gitlab-ce


所需依赖 
curl
openssh-server
openssh-clients
postfix
cronie
policycoreutils-python

##10.x以后版本开始依赖policycoreutils-python,请在安装前确保前置依赖已安装:

```yum install -y curl openssh-server openssh-clients postfix cronie policycoreutils-python 
```

*** 启动postfix, 并设置为开机启动
	*** not fit for centOS 6.5
			systemctl start postfix
			systemctl enable postfix
*** 设置防火墙

	*** not fit for centOS 6.5
	    firewall-cmd —add-service-http —permanent
	    firewall-cmd —reload
	



获得gitlab rpm包

通过清华开源镜像站


官网提供的安装命令
EXTERNAL_URL=“http://10.6.0.88”  rpm -i gitlab-ce-10.2.1-ce.0.el6.x86_64.rpm

根据提示,继续初始化配置;
gitlab-ctl reconfigure

停掉gitlab-ctl
gitlab-ctl stop

修改配置文件gitlab.rb
将external_url  的值改为本机内网ip地址  “http://10.6.0.88”

重新加载配置文件
gitlab-ctl reconfigure

为了推进我司技术团队国际化实力,经领导批示,不对gitlab进行汉化处理;
http://www.cnblogs.com/straycats/p/7637373.html


设置管理员密码

方法1 浏览器访问本机ip  默认登入root账号   点击修改密码

方法2 指令方式    

gitlab-rails console production

稍候 …  按如下设定超级管理员密码

```irb(main):001:0> user = User.where(id: 1).first ```
// id为1的是超级管理员
```irb(main):002:0>user.password = 'yourpassword'  ```
// 密码必须至少8个字符
```irb(main):003:0>user.save! ```
// 如没有问题 返回true
```exit```
// 退出



#Gitlab 本地备份

##手动备份gitlab
```
	gitlab-rake gitlab:backup:create
```

这里要特别说明，如果 /etc/gitlab/gitlab.rb 配置了参数“backup_path”（例如gitlab_rails['backup_path'] = '/backup'），则备份的目录就是该目录下（/backup/）；
如果没有配置参数“backup_path”，则gitlab把备份文件生成到默认目录/var/opt/gitlab/backups
创建一个名称类似为1502357536_2017_08_10_9.4.3_gitlab_backup.tar的压缩包, 这个压缩包就是Gitlab整个的完整部分, 其中开头的1502357536_2017_08_10_9.4.3是备份创建的日期

	•	/etc/gitlab/gitlab.rb 配置文件须备份
	•	/var/opt/gitlab/nginx/conf   nginx配置文件
	•	/etc/postfix/main.cfpostfix 邮件配置备份

仅仅这样不够，每天我这里的运维工作也有不少，如果每天都来手动备份，虽然只要几分钟，但是人工成本很高，所以还是要考虑使用自动定时的方式进行 
http://www.cnblogs.com/straycats/p/7671204.html

##定时任务本地备份
crontab 添加定时计划
```
su root
sudo crontab -e
```

设置每天凌晨2点进行备份
0 2 * * * /opt/gitlab/bin/gitlab-rake gitlab:backup:create

重启crontab
###centOS7
systemctl restart crond

设置定时自动清理老旧备份
##自动清理
gitlab自带的功能
vim /etc/gitlab/gitlab.rb
取消backup_keep_time的注释,设置为7天(7*3600*24=604800)
gitlab_rails['backup_keep_time'] = 604800

gitlab-ctl reconfigure

https://zhuanlan.zhihu.com/p/22439983


#远程备份
gitlab所在服务器A(centOS6.5, 10.6.0.88)
备份服务器B(centOS6.5, 10.6.0.56)

##gitlab服务器配置备份服务器ssh公钥免密执行scp
###在gitlab服务器上生成密钥对
su root
ssh-keygen -r rsa
不设置密码
!注意  生成的是root账号的密钥对
###备份一下
cp /root/.ssh/id_rsa.pub /root/.ssh/id_rsa.pub.A

###将gitlab服务器公钥上传到备份服务器/root/.ssh
scp /root/.ssh/id_rsa.pub.A root@10.6.0.56:/root/.ssh/
输入密码 执行scp


####在备份服务器创建authorized_keys
touch /root/.ssh/authorized_keys


####将公钥内容追加到authorized_keys
cat /root/.ssh/id_rsa.pub.A >> /root/.ssh/authoried_keys


####测试上传文件免密是否生效
scp /root/.ssh/id_rsa.pub.A root@10.6.0.56:/root/.ssh/id_rsa.pub.A.bak
不需要输入密码


##定时将备份文件传到备份服务器
在gitlab服务器A上, 在 /root目录下创建定期备份脚本gitlab_auto_backup_to_remote.sh
vim /root/gitlab_auto_backup_to_remote.sh
```
#!/bin/bash

#gitlab服务器备份路径
LocalBackDir=/var/opt/gitlab/backups

#远程备份服务器 gitlab备份文件目录
RemoteBackDir=/root/gitlab_backup

#远程备份服务器登录账户
RemoteUser=root

#远程服务器IP
RemoteIP=10.6.0.56

#当前系统日期
DATE=`date +"%Y-%m-%d"`

#log存放路径
LogFile=$LocalBackDir/log/$DATE.log

#查找gitlab本地备份目录下 时间为60分钟之内,并且后缀为.tar的gitlab备份文件
BACKUPFILE_SEND_TO_REMOTE=$(find $LocalBackDir -type f -mmin -60 -name '*.tar*')

#新建日志文件
touch $LogFile

#追加日志到日志文件
echo "Gitlab auto backup to remote server, start at $(date +"%Y-%m-%d %H:%M:%S")" >> $LogFile
echo "-------------
----------------------------------------------------------" >> $LogFile

#备份到远程服务器
scp $BACKUPFILE_SEND_TO_REMOTE $RemoteUser@RemoteIP:$RemoteBackDir

#追加日志到日志文件
echo "---------------------------------------------------------------------------" >> $LogFile

```


修改远程备份脚本gitlab_auto_backup_to_remote.sh的权限
`chmod 777 gitlab_auto_backup_to_remote.sh`

创建日志存放目录
mkdir -p /var/opt/gitlab/backups/log

手动测试远程备份脚本是否可用

在gitlab服务器执行find命令, 查看是否能找到需要scp到远程服务器的gitlab备份文件
`find /var/opt/gitlab/backups/log -type f -nmin -60 -name '*.tar*'`

手动执行脚本
cd ./gitlab_auto_backup_to_remote.sh

等待1-2分钟,看是否备份服务器目录/root/gitlab_backup 下已经传过来了备份文件

添加定时计划

`su root
sudo crontab -e
`

结合我之前对公司gitlab本地备份的设计，故设计在备份完10分钟后上传，故分别在每天12:10、19:10进行备份，故添加下面的内容，wq保存。
`10 12 * * * /root/auto_backup_to_remote.sh -D 1
10 19 * * * /root/auto_backup_to_remote.sh -D 1
`

####重启crontab
systemctl restart crond


##定时删除备份服务器是超期限的备份文件
根据备份服务器空间决心 7~14天的备份为好

创建删除备份文件的脚本

设计备份服务器B的/root/gitlab_backup作为接收远程上传备份文件的目录，故在备份服务器B上，先创建该目录。  

mkdir -p /root/gitlab_backup


创建删除过期备份文件的脚本auto_remove_old_backup.sh。 

vim /root/auto_remove_old_backup.md


`#!/bin/bash
# 远程备份服务器 gitlab备份文件存放路径
GitlabBackDir=/root/gitlab_backup
# 查找远程备份路径下，超过14天且文件后缀为.tar 的 Gitlab备份文件 然后删除
find $GitlabBackDir -type f -mtime +14 -name '*.tar*' -exec rm {} \;
`

修改auto_remove_old_backup.sh脚本的权限 
`chmod 777 auto_remove_old_backup.sh
`
`crontab -e`
 

设计凌晨0点执行删除过期备份文件的脚本，故添加下面的内容，wq保存。

`0 0 * * *  /root/auto_remove_old_backup.sh`
 

重启crontab
`systemctl restart crond`

__next:http://www.cnblogs.com/straycats/p/7702271.html__







		
http://blog.csdn.net/ouyang_peng/article/details/77070977
http://blog.csdn.net/ouyang_peng/article/details/77334215
http://blog.csdn.net/ouyang_peng/article/details/78562125
***http://www.cnblogs.com/alex3714/p/6902641.html***

很多时候 ，我们学了好多东西，可能一辈子也用不上，但正是这些东西，让你逐渐变成一个更优秀的人。
___todo:add these files to the gitlab project___
__todo:http://www.cnblogs.com/straycats/p/7672692.html#undefined__



















