#!/bin/bash
systemctl stop valheimserver
world_path=$(mount | grep Valheim | awk '{ print $3 }')
for i in $(ls $world_path/${WORLD_NAME}.*); do 
  aws s3 cp $i s3://${BUCKET_NAME}/$(date +"%Y_%m_%d_%I_%M_%p")/; 
done
systemctl start valheimserver