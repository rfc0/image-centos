#!/bin/bash
#set -o errexit -o pipefail -o xtrace

# These parameters are for test run only
PLAN=x1.small.x86
FAC=any
MODE=install
#

LASTBLD=$(tail -n 1 build.list)
OS=${LASTBLD%:*}
SHA=${LASTBLD#*:}
SSHKEY=$(cat $HOME/.ssh/id_rsa.pub)
HOSTNAME=pb-${OS%_*}-$(echo $PLAN | sed 's/\./-/g')

if [ ${#SHA} -ne 40 ]; then
    echo "Image SHA not found. Aborting device creation!"
    exit 1
fi

echo -e "\nCreating $OS on $PLAN in $FAC..."
DEV=$(packet-cli device create --hostname $HOSTNAME --plan $PLAN --facility $FAC --operating-system $OS --project-id 52a06de9-4bb6-49b3-93f1-28c414e97a45 --userdata="#cloud-config
#image_repo=https://github.com/packethost/packet-images.git
#image_tag=$SHA
ssh_authorized_keys:
  - $SSHKEY" | grep ":" | awk {'print $2'})
echo "Device $DEV is running!"
echo $DEV > device.list

