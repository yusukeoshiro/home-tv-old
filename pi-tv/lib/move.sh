#!/bin/bash

# sftp yusuke@35.231.150.40:/home/yusuke/ <<< $'put /home/pi/home-tv/Videos/recording/20180919_0134_49014948.ts'
echo $1
echo $2
echo $3
echo $4

sftp $1@$2 <<< $"rename $3  $4"

