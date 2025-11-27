#!/bin/bash
set -eo pipefail
#https://www.jimangel.io/posts/automate-ubuntu-22-04-lts-bare-metal/
#https://www.pugetsystems.com/labs/hpc/ubuntu-22-04-server-autoinstall-iso/
#https://cloudinit.readthedocs.io/en/latest/reference/examples.html
sourceISO="/tmp/autoinstall.iso"
resultISO="$(pwd)/result.iso"
buildDir="/tmp/autoinstall-ISO/"
sourceIsoPath="/tmp/autoinstall-ISO/autoinstall.iso"
sourceFiles="/tmp/autoinstall-ISO/source-files/"
sourceBootPath="/tmp/autoinstall-ISO/source-files/[BOOT]"
buildCommandPath="/tmp/autoinstall-ISO/source-files/buildCommand.sh"
destBootPath="/tmp/autoinstall-ISO/BOOT/"
destBoot1Path="BOOT/1-Boot-NoEmul.img"
destBoot2Path="BOOT/2-Boot-NoEmul.img"
grubPath="/tmp/autoinstall-ISO/source-files/boot/grub/grub.cfg"
cdromServerPath="/tmp/autoinstall-ISO/source-files/server/"
metaDataPath="/tmp/autoinstall-ISO/source-files/server/meta-data"
userDataPath="/tmp/autoinstall-ISO/source-files/server/user-data"
insertPoint="menuentry \"Try or Install Ubuntu Server\" {"
ubuntuVer="24.04.3"
if ! command -v 7z &> /dev/null || ! command -v xorriso &> /dev/null  || ! command -v wget &> /dev/null; then
  sudo sudo apt update && sudo apt -y install p7zip-full xorriso wget
fi

rm -rf $buildDir
mkdir $buildDir

if [ ! -f "$sourceISO" ]; then
  wget "https://mirrors.jxust.edu.cn/ubuntu-releases/$ubuntuVer/ubuntu-$ubuntuVer-live-server-amd64.iso" -O $sourceISO
  cp $sourceISO $buildDir
else
  cp $sourceISO $buildDir
fi

7z -y x $sourceIsoPath -o$sourceFiles
mv -f "$sourceBootPath" $destBootPath
sed -i "/${insertPoint}/i menuentry \"Autoinstall Ubuntu Server\" {" $grubPath
sed -i "/${insertPoint}/i \\\tset gfxpayload=keep" $grubPath
sed -i "/${insertPoint}/i \\\tlinux   /casper/hwe-vmlinuz quiet autoinstall ds=nocloud\\\;s=/cdrom/server/  ---" $grubPath
sed -i "/${insertPoint}/i \\\tinitrd  /casper/hwe-initrd" $grubPath
sed -i "/${insertPoint}/i }" $grubPath
sed -i 's/timeout=30/timeout=1/g' $grubPath

mkdir $cdromServerPath
touch $metaDataPath
cp "user-data" $userDataPath
xorriso -indev $sourceIsoPath -report_el_torito as_mkisofs
echo "xorriso -as mkisofs -r -o $resultISO $(xorriso -indev $sourceIsoPath -report_el_torito as_mkisofs | grep '^-') ." > $buildCommandPath
sed -i "s|zero_gpt:'$sourceIsoPath'|zero_gpt:'../$destBoot1Path'|" $buildCommandPath
sed -i "s|::'$sourceIsoPath'|::'../$destBoot2Path'|" $buildCommandPath
sed -i 's/$/ \\/' $buildCommandPath | sed '$ s/ \\/$/'
sed -i  ':a;N;$!ba;s/\(.*\)\\/\1/' $buildCommandPath
chmod u+x $buildCommandPath
cd $sourceFiles
./buildCommand.sh