#!/bin/sh

driveFormat () {
  drive="$1"
  driveNo="$2"
  # Partition drive
  (echo n; echo p; echo 1; echo ; echo ; echo w) | fdisk $drive
  # Make filesystem
  mkfs -t xfs ${drive}1
  # Make mountpoint and mount the partition
  mkdir -p /data/disk${driveNo} && sudo mount ${drive}1 /data/disk${driveNo}
  # Create entry in fstab if not already present
  grep --silent "/data/disk${driveNo}" /etc/fstab || \
    echo "UUID=$(blkid -s UUID -o value ${drive}1) /data/disk${driveNo}    $(blkid -s TYPE -o value ${drive}1)    defaults      0 0" >> /etc/fstab
}

count=1
for i in /dev/sdc /dev/sdd; do
  driveFormat $i $count
  count=$((count+1))
done
