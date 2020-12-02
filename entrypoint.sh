#!/bin/sh
set -e

# Add the UID to /etc/passwd if it is not already there
if ! grep -q "^[^:]*:[^:]*:${UID}:" /etc/passwd; then
    # Originally we made /etc/passwd group writable and modified it directly, per older
    # k8s advice. This is no longer considered safe, per this article:
    # https://access.redhat.com/articles/4859371
    cp /etc/passwd /tmp/passwd
    GID=$(id -g)
    echo "uid${UID}:x:${UID}:${GID}:User:/home/user:/bin/false" >> /tmp/passwd
    export LD_PRELOAD=/usr/lib64/libnss_wrapper.so
    export NSS_WRAPPER_PASSWD=/tmp/passwd
    export NSS_WRAPPER_GROUP=/etc/group
fi
id

# Quick exit for no command or simple echo
if [ $# -eq 0 ]; then
    echo "No command to execute; exiting"
    exit 0
fi
if [ $1 = "echo" ]; then
    exec $@
fi

# Give WORKDIR, HOME, USER sensible values
[ $WORKDIR ] || WORKDIR=$PWD
[ $HOME ] || HOME=$PWD
# We don't want HOME to be the root directory, and /home/user
# should be writable by group 0, so let's use that
[ $HOME = '/' ] && HOME=/home/user
USER=$(id -un)
export WORKDIR HOME USER

# Activate the conda environment
source /usr/local/bin/activate base

# Print some helpful things
echo "USER=$USER WORKDIR=$WORKDIR HOME=$HOME CONDA_PREFIX=$CONDA_PREFIX"

# Execute the command
echo "Executing: $@"
echo "--------"

exec "$@"
