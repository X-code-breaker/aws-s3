#!/bin/sh
#!/usr/bin/aws

logs="s3-info.csv"
ld=`date "+%Y-%m-%d"`
pd=`date "+%Y-%m-%d" --date="1 days ago"`
echo "">$logs
echo "=================script start time `date`  ====================" >> $logs
echo -e "name,creation_data,size,objects,admin_contact,service_id,LastModified"  >> $logs
ns3=`aws s3api list-buckets --query 'Buckets[].Name' | wc -l`
i=2
while [ $i -lt $ns3 ]
do
#bucket name
mybucket=`aws s3api list-buckets --query 'Buckets[].Name' |awk -F '"' '{print $2}'| tail -$i|head -1`
#size of the bucket
size=`aws cloudwatch get-metric-statistics --namespace "AWS/S3" --metric-name BucketSizeBytes --dimensions Name=StorageType,Value=StandardStorage Name=BucketName,Value=${mybucket} --start-time ${pd}T00:00:00Z --end-time ${ld}T23:59:59Z --period 86400 --statistics Sum --unit Bytes --region us-west-2 | grep Sum | awk '{print $2}' | tail -1| sed 's/,/ /g'`
#No. of objects in the bucket
obj=`aws cloudwatch get-metric-statistics --namespace "AWS/S3" --metric-name NumberOfObjects --dimensions Name=StorageType,Value=AllStorageTypes Name=BucketName,Value=${mybucket} --start-time ${pd}T00:00:00Z --end-time ${ld}T23:59:59Z --period 86400 --statistics Average --unit Count --region us-west-2 --output text | tail -1| awk '{print $2}' | sed 's/,/ /g'`
if [ -z "$size" ]
then
#to cross check the total size and objects of the bucket
size=`aws s3 ls ${mybucket} --recursive | awk ' {sum+=$3} END {print sum} '`
obj=`aws s3 ls ${mybucket} --recursive| wc -l`
fi
size=`echo $size | awk '{ byte =$1 /1024/1024 ; print byte " MB" }'`
#You can set the limits for large buckets ( for time savings)
if [ "${obj%.*}" -lt 100000 ]
then
#check the last modified date
lt_mod=`aws s3 ls ${mybucket} --recursive | awk '{print $1}' | sort | tail -1` 
else
lt_mod=" "
fi
echo -e "${mybucket},${creation_data},${size},${obj},${admin_contact},${service_id},${lt_mod}" >> ${logs}
let i='i + 1'
done
