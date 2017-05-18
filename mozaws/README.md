`mozaws.init.R` should be sourced in R sessions where the `mozaws` [package](https://github.com/saptarshiguha/mozaws) is to be used. It loads the package and sets up the relevant configuration working with Telemetry data using Mozilla's infrastructure.

It also defines convenience functions `emr.new` and `emr.kill` for starting and killing AWS EMR clusters.
