#!/bin/bash
#
# Quick script to deploy a set of servers with datadisk
#
RESOURCEGROUP="kafkalab.karl.dev"
CORPORATE_NET="<ExternalIP>"
az account set --subscription "<Name of Subscription>"

do_help() {
  echo $"Usage: $0
  -g      Create resourcegroup and NSG
  -h      Give this help list"
  echo
  exit 0
}

do_create_rg() {
  az group create -l northeurope --name $RESOURCEGROUP
  az network nsg create --resource-group $RESOURCEGROUP --location northeurope --name NSG-FrontEnd
  az network nsg rule create --resource-group $RESOURCEGROUP --nsg-name NSG-FrontEnd  --name ssh-rule \
   --access Allow --protocol Tcp --direction Inbound --priority 100  --source-address-prefix $CORPORATE_NET \
   --source-port-range "*" --destination-address-prefix "*" --destination-port-range 22
  az network vnet create --name myVNET --resource-group $RESOURCEGROUP --location northeurope \
   --address-prefix 192.168.0.0/16 --subnet-name SeverNet --subnet-prefix 192.168.1.0/24
  az network vnet subnet update --vnet-name myVNET --name SeverNet --resource-group $RESOURCEGROUP \
   --network-security-group NSG-FrontEnd
}

do_create_vm () {
  myServer="$1"
  az vm create --resource-group $RESOURCEGROUP --name $myServer --image centos --admin-username centos \
    --size Standard_D2s_v3 --ssh-key-value "$SSHKEY" --data-disk-sizes-gb 140 150 --no-wait
  echo "Waiting for VM to be created. Sleep 30..."
  sleep 30
  echo "Configuring disk through vm extension"
  az vm extension set  --resource-group $RESOURCEGROUP --vm-name $myServer --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --settings '{"fileUris": ["https://raw.githubusercontent.com/KarlMSola/safe/master/playbook/driveit.sh"],"commandToExecute": "sh ./driveit.sh"}'
}
while test $# -gt 0; do
  case "$1" in
  -\? | --h | --he | --hel | --help)
    do_help
    ;;
  -g)
    do_create_rg
    ;;
  esac
  shift
done

# Resource group is presumed to have been created, now make the VM
for vm in st-broker11 st-broker12 st-broker13; do
  echo "Creating VM ($vm)"
  do_create_vm $vm
done

