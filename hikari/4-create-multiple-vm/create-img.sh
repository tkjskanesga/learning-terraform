#!/bin/bash
# Create template cloudimage

TEMPLATE_ID=9000
TEMPLATE_NAME="ubuntu-2204-cloudimage"
IMAGE_PATH="/var/lib/vz/template/iso/jammy-server-cloudimg-amd64.img"
STORAGE="local-lvm"
BRIDGE="vmbr0"

qm create $TEMPLATE_ID --memory 2048 --cores 2 --name $TEMPLATE_NAME --net0 virtio,bridge=$BRIDGE
qm importdisk $TEMPLATE_ID $IMAGE_PATH $STORAGE
qm set $TEMPLATE_ID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$TEMPLATE_ID-disk-0
qm set $TEMPLATE_ID --ide2 $STORAGE:cloudinit
qm set $TEMPLATE_ID --boot order=scsi0
qm set $TEMPLATE_ID --agent 1

qm template $TEMPLATE_ID

echo "Template $TEMPLATE_NAME (ID: $TEMPLATE_ID) berhasil dibuat!"
