#!/bin/bash
set -eo pipefail
sdCard="/dev/sdx"
sdCardPartition1="/dev/sdx1"
sdCardPartition2="/dev/sdx2"
gz="/tmp/Armbian_25.11.0_tvi3315a.img.gz"
img="/tmp/Armbian_25.11.0_tvi3315a.img"
mountPoint="/tmp/armbian_mount"
mountRootPath="/tmp/armbian_mount/root/"
if ! command -v gunzip &> /dev/null || ! command -v wget &> /dev/null; then
  sudo sudo apt update && sudo apt -y install gunzip wget
fi

if [ ! -f "$gz" ]; then
  wget https://github.com/ophub/amlogic-s9xxx-armbian/releases/download/Armbian_trixie_arm64_server_2025.11/Armbian_25.11.0_rockchip_tvi3315a_trixie_6.1.158_server_2025.11.15.img.gz -O $gz
fi

if [ ! -f "$img" ]; then
  gunzip -c $gz > $img
fi

#https://forums.linuxmint.com/viewtopic.php?t=402458
#https://linuxconfig.org/how-to-create-loop-devices-on-linux
#https://www.linuxquestions.org/questions/linux-general-1/remove-%27write-protection-on-pendrive-4175623445/
#sudo losetup -Pfr $img
#loop=$(losetup -j $img | cut -d: -f1)
#echo "loop:$loop"
#sudo mount  "${loop}p2" $mountPoint
#sudo cp .not_logged_in_yet provisioning.sh $mountRootPath
#sudo ls -al $mountRootPath
#sudo umount $mountPoint
#sudo losetup -d "$loop"

mkdir -p $mountPoint
if [ "$(mount -l | grep $mountPoint)" == "" ]; then
    sudo dd if=$img bs=100M of=$sdCard status=progress
    sudo mount $sdCardPartition2 $mountPoint
fi


#https://docs.armbian.com/User-Guide_Autoconfig/
sudo cp -f .not_logged_in_yet provisioning.sh $mountRootPath
sudo ls -al $mountRootPath
sudo umount $mountPoint