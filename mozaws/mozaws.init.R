library(mozaws)

onhala <- grepl("hala", Sys.info()[["nodename"]])

## Set up the mozaws configuration options.
aws.init(
    ec2key="20161025-dataops-dev",
    localpubkey = if(onhala) "~/.ssh/id_rsa-aws-hala.pub" else "~/.ssh/id_rsa-aws.pub",
    opts = list(
        loguri = "s3://mozilla-metrics/share/logs/",
        s3bucket = "mozilla-metrics/share/bootscriptsAndR",
        timeout = "1440",
        ec2attributes = "InstanceProfile='telemetry-spark-cloudformation-TelemetrySparkInstanceProfile-1SATUBVEXG7E3'",
        configfile="https://s3-us-west-2.amazonaws.com/telemetry-spark-emr-2/configuration/configuration.json",
        user = "dzeber@mozilla.com",
        ## Use Spark 2.0
        releaselabel = "emr-5.2.1"
))

## Install tools not included in standard ATMO environment.
moz.init <- function(cl) {
    aws.step.run(cl,
        script = sprintf('s3://%s/run.user.script.sh',aws.options()$s3bucket),
        args="https://raw.githubusercontent.com/saptarshiguha/mozillametricstools/master/common/mozilla.init.sh",
        name="Reinstall Tools",
        wait=TRUE)
    cat("\n")
}

## Create a new cluster.
## If 'write' is TRUE, information about the cluster will be written
## to files in the dir returned by getClusterInfoDir().
emr.new <- function(mainnodes = 1, spotnodes = 0, runinit = TRUE, write = TRUE) {
    awsOpts <- aws.options()
    cl <- aws.clus.create(
        workers = mainnodes,
        verbose = TRUE,
        applications = c("Spark", "Hive", "Hadoop", "Zeppelin"),
        bsactions = list("setup-telemetry-cluster" = c(
            "s3://telemetry-spark-emr-2/bootstrap/telemetry.sh",
            "--public-key" = awsOpts$localpubkey,
            "--email" = awsOpts$user,
            "--efs-dns" = "fs-d0c30f79.efs.us-west-2.amazonaws.com")))
    if(identical("WAITING", cl$Status$State) && runinit){
        cat("Running the Step to add mozillametricstools code\n")
        moz.init(cl)
    }
    if(spotnodes > 0) cl <- aws.modify.groups(cl, spotnodes, spotPrice=0.8)
    if(write) writeClusterInfo(cl)
    cl
}

## The dir to write info files for the given cluster: <basedir>/<clusterID>.
## Check if <basedir> is set via the env variable MOZAWS_INFO_DIR.
## If not, supply the default value '~/.mozaws.clus'. 
getClusterInfoDir <- function(cl) {
    awsinfodir <- Sys.getenv("MOZAWS_INFO_DIR", unset = "~/.mozaws.clus")
    sprintf("%s/%s", awsinfodir, cl$Id)
}

isClusterTerminated <- function(cl) {
    updated_cl <- aws.clus.info(cl)
    updated_cl$Status$State %in% c("TERMINATING", "TERMINATED")
}


## Write information about the cluster to the MOZAWS_INFO_DIR.
## A subdir for the cluster is created, named using the cluster ID (of the form
## "j-AAAAAAAAAAAAA"). Then, the following information is written to individual
## files:
## - IP address
## - cluster start time
## - cluster name
## - an RData containing the cluster object
## - a .ssh/config-type file that can be used for ssh-ing into the cluster,
##   with the host named using the cluster ID.
writeClusterInfo <- function(cl) {
    clusInfoDir <- getClusterInfoDir(cl)
    dir.create(clusInfoDir, showWarnings = FALSE, recursive = TRUE, mode = "0755")
    cat(cl$MasterPublicDnsName, file = sprintf("%s/dns_name", clusInfoDir))
    cat(as.character(as.POSIXlt(
            cl$Status$Timeline$CreationDateTime, origin="1970-01-01")),
        file = sprintf("%s/creation_time", clusInfoDir))
    cat(cl$Name, file = sprintf("%s/cluster_name", clusInfoDir))
    save(cl, file = sprintf("%s/cl.RData", clusInfoDir))
    sshconf <- paste(sprintf("## %s", cl$Name),
        sprintf("Host %s", cl$Id),
        sprintf("    HostName %s\n", cl$MasterPublicDnsName),
        sep = "\n")
    cat(sshconf, file = sprintf("%s/sshconfig", clusInfoDir))
    cat(sprintf("Wrote cluster info to %s/\n", clusInfoDir))
}

## Delete stored info about the cluster.
deleteClusterInfo <- function(cl) {
    clusInfoDir <- getClusterInfoDir(cl)
    if(dir.exists(clusInfoDir)) {
        unlink(clusInfoDir, recursive = TRUE)
        cat(sprintf("Deleted cluster info at %s/\n", clusInfoDir))
    }
}

emr.kill <- function(cl) {
    aws.kill(cl)
    ## State should be updated pretty quickly.
    ## Check soon after killing for confirmation.
    ## If the cluster didn't report termination status, keep checking for
    ## an additional period of time over longer intervals.
    Sys.sleep(5)
    killed <- isClusterTerminated(cl)
    if(!killed) {
        cat("Cluster did not terminate immediately.\n")
        tries <- 0
        while(!killed && tries < 20) {
            Sys.sleep(15)
            killed <- isClusterTerminated(cl)
            tries <- tries + 1
        }
        if(!killed)
            stop("*** There was a problem shutting down the cluster ***")
    }
    cat("Cluster shut down successfully\n")
    ## Delete cluster details written to disk, if any.
    deleteClusterInfo(cl)
}


