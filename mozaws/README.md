`mozaws.init.R` should be sourced in R sessions where the `mozaws` [package](https://github.com/saptarshiguha/mozaws) is to be used. It loads the package and sets up the relevant configuration working with Telemetry data using Mozilla's infrastructure.

- It also defines convenience functions `emr.new()` and `emr.kill()` for starting and killing AWS EMR clusters.
- To list current clusters started from mozaws (whose information has been written locally by `emr.new()`, use `listCurrentClusters()`.


`mozaws.sh` provides shell support for interacting with mozaws clusters. It patches ssh to automatically recognize AWS EMR clusters started in R via mozaws. Source this script in `.bashrc`.

- To `ssh` into a cluster started from mozaws, use `ssh <clusterID>`. If only one cluster is running, `ssh aws` can be used as a shortcut.
- To list information about currently running clusters, use `mozaws`.
- This file also sets the path to the dir where the cluster information gets written.
