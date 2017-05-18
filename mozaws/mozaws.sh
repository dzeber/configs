
## Set up some shell shortcuts for interacting with clusters created using mozaws.
## This file should be sourced from the .bashrc.

## The directory where cluster info will be written.
## If this script is sourced on login, it will get picked up by mozaws.init.R.
MOZAWS_INFO_DIR=~/.mozaws.clus

## Alias for ssh that will pull in the custom config with current mozaws clusters.
## To override this config (or revert to the standard config), use `-F`.
alias ssh='mozaws_ssh_config && ssh -F ~/.ssh/config_mozaws_tmp'

## Patch ssh to recognize clusters started from mozaws.
##
## Generate a modified .ssh/config file that contains listings for any running
## mozaws clusters.
##
## Clusters can be referred to using their cluster ID. If there is only one
## cluster running, it can be referred to using the Host pattern "aws",
## eg. `ssh aws`.
##
## The custom config file is written to ~/.ssh/config_mozaws_tmp.
## To pull in the config, use `ssh -F ~/.ssh/config_mozaws_tmp`
mozaws_ssh_config() {
    NUM_CLUS=$(ls -1 "$MOZAWS_INFO_DIR" | wc -l)
    if [[ $NUM_CLUS -eq 0 ]]; then
        ## If no clusters are listed, just use the standard config file.
        cp ~/.ssh/config ~/.ssh/config_mozaws_tmp
    else
        ## Concatenate the config blocks for each cluster.
        MOZAWS_CONFIG=$(cat $MOZAWS_INFO_DIR/*/sshconfig)
        ## If there is only a single cluster listed, we want to be able to
        ## refer to it using the Host alias "aws".
        ## Append this to the Host line for its config block.
        if [[ $(echo "$MOZAWS_CONFIG" | grep "^Host" | wc -l) -eq 1 ]]; then
            MOZAWS_CONFIG=$(echo "$MOZAWS_CONFIG" | sed '/^Host/ s/$/ aws/')
        fi
        ## Concatenate the cluster config blocks with the standard config file.
        ## Cluster configs come first so as to take precedence over existing
        ## config.
        echo "$MOZAWS_CONFIG" > ~/.ssh/config_mozaws_tmp
        cat ~/.ssh/config >> ~/.ssh/config_mozaws_tmp
    fi
    chmod 600 ~/.ssh/config_mozaws_tmp
}


## Attempt to connect to an AWS EMR cluster whose info has been written
## to the MOZAWS_INFO_DIR by mozaws.
## Currently this does not allow passing other args to ssh.
#ssh_mozaws_cluster() {
#    CLUSTERS=$(ls -1 "$MOZAWS_INFO_DIR")
#
#    ## Which cluster should we connect to?
#    if [[ -n "$1" ]]; then
#        ## The cluster ID was passed - use that.
#        CLUSTER_ID=$1
#    elif [[ -z "$CLUSTERS" ]]; then
#        echo "No mozaws clusters are listed."
#        return 1
#    elif [[ $(echo "$CLUSTERS" | wc -l) -eq 1 ]]; then
#        CLUSTER_ID="$CLUSTERS"
#    else
#        MULT_MSG="Multiple clusters are listed."
#        MULT_MSG="$MULT_MSG Specify the ID of the cluster to connect to:"
#        echo "$MULT_MSG"
#        echo "$CLUSTERS"
#        return 1
#    fi
#
#    CLUSTER_INFO_PATH="$MOZAWS_INFO_DIR/$CLUSTER_ID"
#    IP_ADDR=$(cat $CLUSTER_INFO_PATH/dns_name)
#    echo "Connecting to cluster $CLUSTER_ID ($IP_ADDR):"
#    ssh $IP_ADDR
#}
#
