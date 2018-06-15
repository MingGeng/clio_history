service alfresco stop
wait
cp -rf /app/alfresco-community/solr4 /app/backup/alfresco_$(date +%Y%m%d)
cp -rf /app/alfresco-community/alf_data  /app/backup/alfresco_$(date +%Y%m%d)
rm -rf /app/backup/alfresco_$(date +%Y%m%d)/alf_data/postgresql
cd /app/alfresco-community/postgresql/scripts
./ctl.sh start
wait
pg_dump -U alfresco -w -h 127.0.0.1 -p 5432 -d alfresco > /app/backup/alfresco_$(date +%Y%m%d)/postgresql.sql
service alfresco start
cd /app/backup
tar cvf alfresco_$(date +%Y%m%d).tar alfresco_$(date +%Y%m%d)
rm -rf /app/backup/alfresco_$(date +%Y%m%d)