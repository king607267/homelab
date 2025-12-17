#!/bin/bash
set -eo pipefail
sdCard="/dev/sdb"
sdCardPartition2=$sdCard"2"
gz="/tmp/Armbian_25.11.0_tvi3315a.img.gz"
img="/tmp/Armbian_25.11.0_tvi3315a.img"
mountPoint="/tmp/armbian_mount"
mountRootPath="/tmp/armbian_mount/root/"
tmpImgPath="/tmp/armbian_tmp.img"
if ! command -v gunzip &> /dev/null || ! command -v wget &> /dev/null || ! command -v gzip &> /dev/null; then
  sudo sudo apt update && sudo apt -y install gunzip wget gzip
fi

if [ ! -f "$gz" ]; then
  wget https://github.com/ophub/amlogic-s9xxx-armbian/releases/download/Armbian_trixie_arm64_server_2025.11/Armbian_25.11.0_rockchip_tvi3315a_trixie_6.1.158_server_2025.11.15.img.gz -O $gz
fi

if [ ! -f "$img" ]; then
  gunzip -c $gz > $img
fi

#loop
#https://forums.linuxmint.com/viewtopic.php?t=402458
#https://linuxconfig.org/how-to-create-loop-devices-on-linux
#https://www.linuxquestions.org/questions/linux-general-1/remove-%27write-protection-on-pendrive-4175623445/
dd if=$img of=$tmpImgPath
sudo losetup -f --show $tmpImgPath
loop=$(losetup -j $tmpImgPath | cut -d: -f1)
echo "loop:$loop"
sudo partprobe $loop
sleep 1
sudo mount  "${loop}p2" $mountPoint
echo "mount ${loop}p2 to $mountPoint ok"
#https://docs.armbian.com/User-Guide_Autoconfig/
sudo cp provisioning.sh $mountRootPath
echo "PRESET_CONFIGURATION=\"$armbian_not_logged_in_yet_path\"" | sudo tee "$mountRootPath.not_logged_in_yet" > /dev/null
sudo ls -al "$mountRootPath"
sudo umount $mountPoint
echo "umount ${loop}p2 ok"
echo "copy data to result.img start"
sudo dd if="$loop" of=result.img bs=1M status=progress
echo "copy data to result.img ok"
sudo losetup -d "$loop"
gzip -k result.img result.img.gz

#sdCard
#if [ ! -e $sdCard ]; then
#    echo "Usb drive $sdCard not found"
#    exit 0
#fi
#
#read -p "Warning: All data on the USB drive $sdCard will be permanently lost during flashing. Please backup important files before proceeding. Continue? (yes/no): " confirm
#if [[ $confirm != "yes" ]]; then
#    exit 1
#fi
#
#mkdir -p $mountPoint
#if [ "$(mount -l | grep $mountPoint)" == "" ]; then
#    echo "copy data to $sdCard start"
#    sudo dd if=$img bs=1M of=$sdCard status=progress
#    echo "copy data to $sdCard ok"
#    sudo partprobe $sdCard
#    sleep 1
#    sudo mount $sdCardPartition2 $mountPoint
#    echo "mount $sdCardPartition2 to $mountPoint ok"
#fi
#
#
##https://docs.armbian.com/User-Guide_Autoconfig/
#sudo cp -f .not_logged_in_yet provisioning.sh $mountRootPath
#sudo cat $mountRootPath".not_logged_in_yet"
#sudo umount $mountPoint
#echo "copy data to result.img start"
#sudo dd if=$sdCard of=result.img bs=1M status=progress
#echo "copy data to result.img ok"