#!/bin/bash

#环境名称数组
array=(DEV_205 UAT_55 DEV_52 UAT_66 UAT_77 Hotfix_156 UAT_129 SH_4 STG_102) 

# 当前系统日期
DATE=`date +"%Y-%m-%d"`

# log存放路径
#LogFile=diskWarning_$DATE.log
echo "" > /app/go_ansible/log/mdf_levy_conf_$DATE.log
#遍历环境名称,ansible输出配置变更日志
for data in ${array[@]}
do
    EnvName=${data}
    echo "Start $EnvName modifing..."
    echo -e "##############[$EnvName]################### \n-----------------------------------------"  >> /app/go_ansible/log/mdf_levy_conf_$DATE.log

    #ansible 输出现有levy配置值
    ansible -i /app/go_ansible/hosts_mdf_levy_config all --limit $EnvName  -m shell -a "
sed -i 's/levyinform.pdf.url=\/app\/pdfdata\/levy\///g' /app/imodule/config/imodule-levy-*/config.properties;
echo 'levyinform.pdf.url=/app/levy/pdfdata/' >> /app/imodule/config/imodule-levy-web/config.properties;  
echo 'levyinform.pdf.url=/app/levy/pdfdata/' >> /app/imodule/config/imodule-levy-service/config.properties; 
grep levyinform.pdf.url /app/imodule/config/imodule-levy-*/config.properties;" >> /app/go_ansible/log/mdf_levy_conf_$DATE.log
done

cat ./log/mdf_levy_conf_$DATE.log
#echo 'levyinform.pdf.url=/app/levy/pdfdata/' >> /app/imodule/config/imodule-levy-web/config.properties;  
#echo 'levyinform.pdf.url=/app/levy/pdfdata/' >> /app/imodule/config/imodule-levy-service/config.properties; 

