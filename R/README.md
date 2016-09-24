
My R setup is as follows:

- There is a common init file (`Rprofile-main`) to be sourced at the start of every session. It sets display options and tweaks for interactive sessions, and does not contain anything that would affect the output of a script.

- Code that scripts rely on, such as package loading or convenience functions, should be included in the scripts themselves. However, for convenience, useful packages and personal functions are collected in a separate init file (`Rprofile-shared`). If the path to this file is stored in the environment variable `R_PROFILE_SHARED` (eg. set in a `.Renviron` file), it will get sourced automatically from the common init file at the start of interactive sessions.

- Each main machine that I run R on also has its own tailored init file with more specific config code. I let `~/.Rprofile` point to this file, and source the common init files from there.

- `Rconsole-win` defines a custom colour scheme for use with `Rterm.exe` on Windows.

