#!/bin/bash

kill -9 $(pidof recpt1)
kill -9 $(pidof ruby main.rb)
kill -9 $(pidof ruby watch.rb)


cd /home/pi/home-tv/pi-tv
cd lib && ruby main.rb | tee logs/log.main &
cd lib && ruby sftp.rb | tee logs/log.sftp &
recpt1 --device /dev/px4video3 --b25 --strip --sid hd --http 8888 | tee logs/log.tv &

exit 0
