
## Set up some shell shortcuts for interacting with clusters created using mozaws.
## This file should be sourced fromthe .bashrc.

## The directory where cluster info will be written.
## If this script is sourced on login, it will get picked up by mozaws.init.R.
MOZAWS_INFO_DIR=~/.mozaws.clus

## Attempt to connect to an AWS EMR cluster whose info has been written
## to the MOZAWS_INFO_DIR by mozaws.
## Currently this does not allow passing other args to ssh.
ssh_mozaws_cluster() {
    CLUSTERS=$(ls -1 "$MOZAWS_INFO_DIR")

    ## Which cluster should we connect to?
    if [[ -n "$1" ]]; then
        ## The cluster ID was passed - use that.
        CLUSTER_ID=$1
    elif [[ -z "$CLUSTERS" ]]; then
        echo "No mozaws clusters are listed."
        return 1
    elif [[ $(echo "$CLUSTERS" | wc -l) -eq 1 ]]; then
        CLUSTER_ID="$CLUSTERS"
    else
        MULT_MSG="Multiple clusters are listed."
        MULT_MSG="$MULT_MSG Specify the ID of the cluster to connect to:"
        echo "$MULT_MSG"
        echo "$CLUSTERS"
        return 1
    fi
    
    CLUSTER_INFO_PATH="$MOZAWS_INFO_DIR/$CLUSTER_ID"
    IP_ADDR=$(cat $CLUSTER_INFO_PATH/dns_name)
    echo "Connecting to cluster $CLUSTER_ID ($IP_ADDR):"
    ssh $IP_ADDR
}

