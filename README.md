# How to setup raspberry pi


```
sudo apt-get install autoconf build-essential cmake curl git libssl-dev libtool libboost-all-dev pkg-config yasm
sudo apt-get install linux-image-4.9.0-6-amd64 linux-headers-4.9.0-6-amd64
```



```
# installing arib25
cd
git clone https://github.com/stz2012/libarib25.git
cd libarib25/
cmake .
make
sudo make install
sudo /sbin/ldconfig
```

```
cd
git clone https://github.com/m-tsudo/pt3.git
cd pt3
sudo apt install dkms
sudo bash ./dkms.install
```


```
# card reader
sudo apt-get install pcscd pcsc-tools libpcsclite-dev
pcsc_scan
```

```
cd
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

```



```
cd
git clone https://github.com/stz2012/recpt1.git
cd recpt1/recpt1
sed -i -e "/^char \*bsdev\[NUM_BSDEV\] = {$/a \ \ \ \ \"/dev/px4video1\",\n\ \ \ \ \"/dev/px4video0\"," pt1_dev.h
sed -i -e "/^char \*isdb_t_dev\[NUM_ISDB_T_DEV\] = {$/a \ \ \ \ \"/dev/px4video2\",\n\ \ \ \ \"/dev/px4video3\"," pt1_dev.h
./autogen.sh
./configure
make
sudo make install
```

```
cd
wget http://plex-net.co.jp/download/linux/Linux_Driver.zip
unzip Linux_Driver.zip
cd Linux_Driver/MyRecpt1/MyRecpt1/recpt1
sed -i -e "/^char \*bsdev\[NUM_BSDEV\] = {$/a \ \ \ \ \"/dev/px4video1\",\n\ \ \ \ \"/dev/px4video0\"," pt1_dev.h
sed -i -e "/^char \*isdb_t_dev\[NUM_ISDB_T_DEV\] = {$/a \ \ \ \ \"/dev/px4video2\",\n\ \ \ \ \"/dev/px4video3\"," pt1_dev.h
./autogen.sh
sh ./configure --enable-b25

make
sudo make install

```


```
# test recording...
recpt1 --b25 --strip 24 10 ~/test.ts
recpt1 --b25 --strip 22 10 ~/tbs.ts
```

```
sudo modprobe -r px4_drv sudo modprobe px4_drv

```


```
scp pi@raspberrypi:/home/pi/test.ts ~/Desktop/test.ts
```

recpt1 --b25 --strip --sid hd --http 8888


https://www.jifu-labo.net/2018/02/plex_tv_tuner/