#!/bin/bash

devlistfile=./device.list
devids=$(cat $devlistfile)
sshopts="-o ConnectTimeout=2 -o StrictHostKeyChecking=no -o PreferredAuthentications=publickey -o PubkeyAuthentication=yes -o UserKnownHostsFile=/dev/null"

echo -e "\nBegin polling with mode $MODE"

function testssh () { 
	ssh_attempt_counter=0
	ssh_max_attempts=3600

	echo "Polling for SSH reachability..."
	until $(ssh $sshopts "$1"@"$2" w &>/dev/null); do
	    if [ ${ssh_attempt_counter} -eq ${ssh_max_attempts} ];then
	      echo "Device failed to become reachable over SSH in time"
	      exit 1
	    fi

	    printf '.'
	    ssh_attempt_counter=$(($ssh_attempt_counter+1))
	    sleep 1
	done

	echo "SSH is up!"

}

function runtests () {
	# Setup bats and copy the test file
	scp -r $sshopts ../testing root@$ip:/root/
	ssh $sshopts $ip "/root/testing/install-bats.sh"

	echo "++++++++++++++++++++++++++++TESTING++++++++++++++++++++++++++++"
	##TODO run all tests instead of just pkg
	#result=$(ssh $sshopts $ip "bats /root/testing" 2>&1)
	result=$(ssh $sshopts $ip "bats /root/testing/pkg.bats" 2>&1)

	echo "RESULT:$result"

	if [[ "$result" == *"failed"* ]]; then
		echo -e "\nTests failed! See output from bats core!"
		exit 1
	else
		echo -e "\nAll tests OK"
	fi
}

if [ -e $devlistfile ]; then
	for dev in `cat $devlistfile`; do
		echo "Device: $dev"

		state_attempt_counter=0
		state_max_attempts=20

		echo "Polling for device activation..."
		until $(packet-cli device get --id $dev -j | jq -r '.state' | grep active >/dev/null); do
		    if [ ${state_attempt_counter} -eq ${state_max_attempts} ];then
		      echo "Device failed to become active in time"
		      exit 1
		    fi

		    printf '.'
		    state_attempt_counter=$(($state_attempt_counter+1))
		    sleep 30
		done


		ip=$(packet-cli device get --id $dev -j | jq -r '.ip_addresses[0].address')
		echo "Device $dev ACTIVE with IP $ip"	
		testssh root "$ip"
		runtests "$ip"
		packet-cli device delete -f --id $dev

	done
else
	echo "ERROR: Couldn't get list of devices to poll!"
	exit 1
fi


if [[ ${MODE} == "customize" ]]; then
	echo -e "\nRunning customization step..."
	echo "SCPing the customization script..."
	scp $sshopts ./scripts/customize.sh root@$ip:/root/

	echo "Running customization script..."
	ssh $sshopts root@$ip "/root/customize.sh"

	echo "SCPing custom initrd to local directory..."
	scp $sshopts root@$ip:/root/packet-images/initrd.tar.gz-CUSTOM .
	echo "Customized initrd: ./initrd.tar.gz-CUSTOM"
else
	echo -e "\nNo customization ran. This image will be generic default."
fi
