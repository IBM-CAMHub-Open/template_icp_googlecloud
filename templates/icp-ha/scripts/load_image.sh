#!/bin/bash

while getopts ":i:u:" arg; do
    case "${arg}" in
      i)
        package_location=${OPTARG}
        ;;
      u)
        user_name=${OPTARG}
        ;;
        
    esac
done

if [ -z "${package_location}" ]; then

 echo " no image file, do nothing"
  exit 0
fi

sourcedir="/tmp/icpimages"
# Get package from remote location if needed

# This must be uploaded from local file, terraform should have copied it to /tmp
image_file="$sourcedir/$(basename ${package_location})"
  
echo "local package_location ${package_location}" >&2

echo "Unpacking ${image_file} ..."
chmod +x ${image_file}
tar -xf  ${image_file} -O | sudo docker load
#${image_file} | tar zxf - -O | sudo docker load

sudo mkdir -p /opt/ibm/cluster/images
sudo mv ${image_file} /opt/ibm/cluster/images/

sudo chown ${user_name} -R /opt/ibm/cluster/images
