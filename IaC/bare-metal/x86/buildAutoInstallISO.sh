#!/bin/bash
set -eo pipefail
#https://www.jimangel.io/posts/automate-ubuntu-22-04-lts-bare-metal/
#https://www.pugetsystems.com/labs/hpc/ubuntu-22-04-server-autoinstall-iso/
#https://cloudinit.readthedocs.io/en/latest/reference/examples.html
#https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html#user-data
ubuntuVer="22.04.5" #22.04.5 or 24.04.3
sourceISO="/tmp/${ubuntuVer}autoinstall.iso"
resultISO="$(pwd)/result.iso"
buildDir="/tmp/autoinstall-ISO/"
sourceIsoPath="/tmp/autoinstall-ISO/${ubuntuVer}autoinstall.iso"
sourceFiles="/tmp/autoinstall-ISO/source-files/"
sourceBootPath="/tmp/autoinstall-ISO/source-files/[BOOT]"
buildCommandPath="/tmp/autoinstall-ISO/buildCommand.sh"
destBootPath="/tmp/autoinstall-ISO/BOOT/"
destBoot1Path="BOOT/1-Boot-NoEmul.img"
destBoot2Path="BOOT/2-Boot-NoEmul.img"
grubPath="/tmp/autoinstall-ISO/source-files/boot/grub/grub.cfg"
cdromServerPath="/tmp/autoinstall-ISO/source-files/server/"
metaDataPath="/tmp/autoinstall-ISO/source-files/server/meta-data"
userDataPath="/tmp/autoinstall-ISO/source-files/server/user-data"
insertPoint="menuentry \"Try or Install Ubuntu Server\" {"
if ! command -v 7z &> /dev/null || ! command -v xorriso &> /dev/null  || ! command -v wget &> /dev/null; then
  sudo sudo apt update && sudo apt -y install p7zip-full xorriso wget
fi

rm -rf $buildDir
mkdir $buildDir

if [ ! -f "$sourceISO" ]; then
  wget "http://ubuntu.mirror.gnc.am/ubuntu-releases/$ubuntuVer/ubuntu-$ubuntuVer-live-server-amd64.iso" -O $sourceISO
  cp $sourceISO $buildDir
else
  cp $sourceISO $buildDir
fi

7z -y x $sourceIsoPath -o$sourceFiles
mv -f "$sourceBootPath" $destBootPath
sed -i "/${insertPoint}/i menuentry \"Autoinstall Ubuntu Server\" {" $grubPath
sed -i "/${insertPoint}/i \\\tset gfxpayload=keep" $grubPath
sed -i "/${insertPoint}/i \\\tlinux   /casper/hwe-vmlinuz quiet autoinstall ds=nocloud\\\;s=${x86_remote_user_data}  ---" $grubPath
sed -i "/${insertPoint}/i \\\tinitrd  /casper/hwe-initrd" $grubPath
sed -i "/${insertPoint}/i }" $grubPath
sed -i 's/timeout=30/timeout=1/g' $grubPath

if [[ $x86_remote_user_data != http* ]]; then
  mkdir $cdromServerPath
  touch $metaDataPath

  echo "#cloud-config" >> $userDataPath
  echo "autoinstall:" >> $userDataPath
  echo "  version: 1" >> $userDataPath
  echo "  early-commands:" >> $userDataPath
  echo "    - ping -c1 ${TF_VAR_def_gateway}" >> $userDataPath
#  echo "  proxy: ${TF_VAR_proxy_ip}" >> $userDataPath
  echo "  apt:" >> $userDataPath
  echo "    preserve_sources_list: false" >> $userDataPath
  echo "    mirror-selection:" >> $userDataPath
  echo "      primary:" >> $userDataPath
  echo "        - country-mirror" >> $userDataPath
  echo "        - uri: \"http://cn.ubuntu.com/ubuntu\"" >> $userDataPath
  echo "          arches: [i386, amd64]" >> $userDataPath
  echo "        - uri: \"http://ports.ubuntu.com/ubuntu-ports\"" >> $userDataPath
  echo "          arches: [s390x, arm64, armhf, powerpc, ppc64el, riscv64]" >> $userDataPath
  echo "    fallback: abort" >> $userDataPath
  echo "    geoip: true" >> $userDataPath
  echo "  drivers:" >> $userDataPath
  echo "    install: false" >> $userDataPath
  echo "  kernel:" >> $userDataPath
  echo "    flavor: hwe" >> $userDataPath
  echo "  locale: en_US.UTF-8" >> $userDataPath
  echo "  network:" >> $userDataPath
  echo "    version: 2" >> $userDataPath
  echo "    ethernets:" >> $userDataPath
  echo "      enp1s0:" >> $userDataPath
  echo "        addresses:" >> $userDataPath
  echo "        - ${x86_auto_install_ip}" >> $userDataPath
  echo "        nameservers:" >> $userDataPath
  echo "          addresses:" >> $userDataPath
  echo "          - ${TF_VAR_dns_server}" >> $userDataPath
  echo "          - 8.8.8.8" >> $userDataPath
  echo "          search: []" >> $userDataPath
  echo "        routes:" >> $userDataPath
  echo "        - to: default" >> $userDataPath
  echo "          via: ${TF_VAR_def_gateway}" >> $userDataPath
  echo "          on-link: true" >> $userDataPath
  echo "  source:" >> $userDataPath
  echo "    id: ubuntu-server" >> $userDataPath
  echo "    search_drivers: false" >> $userDataPath
  echo "  ssh:" >> $userDataPath
  echo "    allow-pw: true" >> $userDataPath
  echo "    install-server: true" >> $userDataPath
  echo "  storage:" >> $userDataPath
  echo "    layout:" >> $userDataPath
  echo "      name: lvm" >> $userDataPath
  echo "  updates: security" >> $userDataPath
  echo "  user-data:" >> $userDataPath
  echo "    disable_root: false" >> $userDataPath
  echo "    timezone: Asia/Shanghai" >> $userDataPath
  echo "    package_update: true" >> $userDataPath
  echo "    package_upgrade: true" >> $userDataPath
  echo "    packages:" >> $userDataPath
  echo "      - nfs-common" >> $userDataPath
  echo "      - qemu-kvm" >> $userDataPath
  echo "      - libvirt-daemon-system" >> $userDataPath
  echo "      - libvirt-clients" >> $userDataPath
  echo "      - bridge-utils" >> $userDataPath
  echo "    users:" >> $userDataPath
  echo "      - name: ${TF_VAR_user}" >> $userDataPath
  echo "        primary_group: users" >> $userDataPath
  echo "        groups: sudo" >> $userDataPath
  echo "        lock_passwd: false" >> $userDataPath
  echo "        # don't need PW since using SSH, leaving this in though..." >> $userDataPath
  echo "        #docker run --rm -it serversideup/mkpasswd --method=SHA-512" >> $userDataPath
  echo "        passwd: ${TF_VAR_passwd}" >> $userDataPath
  echo "        shell: /bin/bash" >> $userDataPath
  echo "        # use cat ~/.ssh/id_rsa.pub or generate to get your public key" >> $userDataPath
  echo "        ssh_authorized_keys:" >> $userDataPath
  echo "          "- "$TF_VAR_ssh_authorized_keys" | sed 's/[][]//g; s/,/\n          - /g;' >> $userDataPath
  echo "        sudo: ALL=(ALL) NOPASSWD:ALL" >> $userDataPath
  echo "        sudo: ALL=(ALL) ALL" >> $userDataPath
  echo "    # shutdown after first host initial provisioning" >> $userDataPath
  echo "    power_state:" >> $userDataPath
  echo "      mode: poweroff" >> $userDataPath
  echo "  late-commands:" >> $userDataPath
  echo "    - curtin in-target --target=/target -- lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv" >> $userDataPath
  echo "    - curtin in-target --target=/target -- resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv" >> $userDataPath
  echo "    - |" >> $userDataPath
  echo "      cat <<EOF | sudo tee /target/etc/environment" >> $userDataPath
  echo "      #PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin\"" >> $userDataPath
  echo "      http_proxy=${http_proxy}" >> $userDataPath
  echo "      https_proxy=${https_proxy}" >> $userDataPath
  echo "      no_proxy=${no_proxy}" >> $userDataPath
  echo "      EOF" >> $userDataPath
  echo "      # shut-down the host to avoid an infinite installer loop" >> $userDataPath
  echo "    - shutdown -h now" >> $userDataPath

  cat $userDataPath > "user-data-bak"
fi
#xorriso created ISO boots in kvm but not physical laptop
#https://unix.stackexchange.com/questions/712319/xorriso-created-iso-boots-in-virtualbox-but-not-physical-laptop
xorriso -indev $sourceIsoPath -report_el_torito as_mkisofs
echo "xorriso -as mkisofs -r -o $resultISO $(xorriso -indev $sourceIsoPath -report_el_torito as_mkisofs | grep '^-') ." > $buildCommandPath
sed -i "s|zero_gpt:'$sourceIsoPath'|zero_gpt:'../$destBoot1Path'|" $buildCommandPath
sed -i "s|::'$sourceIsoPath'|::'../$destBoot2Path'|" $buildCommandPath
sed -i 's/$/ \\/' $buildCommandPath | sed '$ s/ \\/$/'
sed -i  ':a;N;$!ba;s/\(.*\)\\/\1/' $buildCommandPath
chmod u+x $buildCommandPath
cd $sourceFiles
cat "$buildCommandPath" | bash