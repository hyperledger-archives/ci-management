#! /bin/bash -e

#
# 'An auth token is required to fetch a token'
#   Means neutron cannot connect to Openstack
#

usage() {
    echo "Usage $0: IMAGE [RESEAL_DIR]"
    echo
    echo " IMAGE      - An image name listed in 'glance image-list'"
    echo " RESEAL_DIR - One of the subdirectories that contain a 'Vagrantfile'"
}

# If IMAGE is not set, set it to first argument
export IMAGE="${IMAGE:-$1}"

[[ -z "$IMAGE" && $# -ne 2 ]] && usage && exit 1

# If RESEAL_DIR not passed as second arg, set it to basebuild
export RESEAL_DIR=${2:-"basebuild"}
export RESEAL=true

if [ -z "$NETID" ]; then
  [[ -z "$(command -v neutron)" ]] && echo "neutron: command not found" && exit 1
  export NETID="$(neutron net-list | awk '/hyp/ {print $2}')"
fi

SNAPSHOT="$(echo $IMAGE | cut -d' ' -f1-2)"

pushd "$RESEAL_DIR" > /dev/null
echo "Creating Snapshot of \"$IMAGE\" for \"$RESEAL_DIR\""
vagrant up --provider=openstack && \
  nova image-create --poll vagrant-hostname "${SNAPSHOT} - ${RESEAL_DIR} - $(date +%Y%m%d)" \
  && vagrant destroy
popd > /dev/null
