#! /bin/bash

# read -p "Enter the hostname you would like to delete: " hostname
hostname=uhn7kl4r2rbwk004.rmnkiba.local
echo "Your host is set to: "$hostname

./robin host set-maintenance $hostname
# sleep 1

host_role1=`./robin host list  | grep -i $hostname | awk -F '|' '{print $8}' | awk -F ',' '{print $1}'`
echo $host_role1
host_role2=`./robin host list  | grep -i $hostname | awk -F '|' '{print $8}' | awk -F ',' '{print $2}'`
echo $host_role2

if [ $host_role1 = "C" ] || [ $host_role2 = "C" ]; then
    if [[ $(./robin instance list --host $hostname --headers Container) ]]; then
        output=$(./robin instance list --host $hostname --headers Container | awk '{printf "%s,", $1}' | sed 's/, $//')
        echo "Relocating drives!"
        for i in $(./robin instance list --host $hostname --headers Container); do
            echo "Relocating Instance :"$i
            ./robin instance relocate $i --wait --yes
        done
        ./robin instance list --host $hostname
    else
        echo "No instances present on :"$hostname
    fi
else
    echo "No Compute role"
fi

if [ $host_role1 = "S"  ] || [ $host_role2 = "S" ]; then
    if [[ $(./robin drive list --host $hostname --headers WWN) ]]; then
        output=$(./robin drive list --host $hostname --headers WWN | awk '{printf "%s,", $1}' | sed 's/, $//')
        echo "Evaciating drives!"
        for i in $(./robin drive list --host $hostname --headers WWN); do
            echo "Evacuating Drive :"$i
            ./robin drive evacuate $i  --exclude-disks $output --wait --yes
        done
        ./robin drive list --host $hostname
    else
        echo "No drives present on :"$hostname
    fi
else
    echo "No Storage role"
fi

./robin host remove-role $hostname $host_role1,$host_role2 --yes --wait
./robin host remove $hostname --wait --yes
./robin host list --headers Hostname | grep -i $hostname

./robin k8s get-kube-config --save-as-file --dest-dir ~/.kube
## Running k8s cleanup scripts
./k8s-script-el7.sh cleanup --force -y

kubectl delete node $hostname
kubectl get nodes $hostname

retcd get-members
retcd remove-member <member ID>
retcd remove-member --member-id=b839707ae1e0a0ab
retcd get-members <member ID>

## Running node cleanup script
./host-script-el7.sh uninstall  -y
