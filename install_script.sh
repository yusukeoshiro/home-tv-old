#!/bin/sh

echo "updating system..."
sudo apt-get -y update
sudo apt-get -y upgrade


echo "installing tools..."
sudo apt-get -y install autoconf build-essential cmake curl git libssl-dev libtool libboost-all-dev pkg-config yasm
sudo apt-get -y install ruby-dev

echo "installing ffmpeg"
cd
wget https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
tar jxvf ffmpeg-snapshot.tar.bz2
cd ffmpeg
./configure --enable-static --enable-omx-rpi --enable-mmal
make -j4
sudo make install


echo "installing BCAS card reader..."
# sudo dpkg --configure -a
# sudo apt -y --fix-broken install

# sudo apt install aptitude
# sudo aptitude install yum-utils
# sudo apt autoremove

sudo apt-get -y install pcscd pcsc-tools libpcsclite-dev


echo "installing arib25..."
cd
git clone https://github.com/stz2012/libarib25.git
cd libarib25/
cmake .
make
sudo make install
sudo /sbin/ldconfig

echo "installing PX-W3U4 driver for linux..."
cd
rm -rf px4_drv
git clone https://github.com/nns779/px4_drv

cd px4_drv/fwtool/
make
curl -O http://plex-net.co.jp/plex/pxw3u4/pxw3u4_BDA_ver1x64.zip
unzip -oj pxw3u4_BDA_ver1x64.zip pxw3u4_BDA_ver1x64/PXW3U4.sys
./fwtool PXW3U4.sys it930x-firmware.bin
sudo mkdir -p /lib/firmware
sudo cp it930x-firmware.bin /lib/firmware/
cd ../

sudo apt-get -y install raspberrypi-kernel-headers # Raspbrry Pi only
cd driver
make
sudo make install
sudo modprobe px4_drv

echo "installing capture software..."
cd
wget http://plex-net.co.jp/download/linux/Linux_Driver.zip
unzip Linux_Driver.zip
cd Linux_Driver/MyRecpt1/MyRecpt1/recpt1
sed -i -e "/^char \*bsdev\[NUM_BSDEV\] = {$/a \ \ \ \ \"/dev/px4video3\",\n\ \ \ \ \"/dev/px4video2\",\n\ \ \ \ \"/dev/px4video1\",\n\ \ \ \ \"/dev/px4video0\"," pt1_dev.h
sed -i -e "/^char \*isdb_t_dev\[NUM_ISDB_T_DEV\] = {$/a \ \ \ \ \"/dev/px4video0\",\n\ \ \ \ \"/dev/px4video1\",\n\ \ \ \ \"/dev/px4video2\",\n\ \ \ \ \"/dev/px4video3\"," pt1_dev.h
chmod +x autogen.sh
./autogen.sh
make clean
sh ./configure --enable-b25

make
sudo make install

exit 0