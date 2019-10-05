# bashbuildah
Collection of bash scripts for buildah-ing dependent sets of containerized software.

## Basics

For maximal fragility and ease of scripting, most metadata is purely 
directory structure defined.

Containers have 4 bits of metadata:
*) Name
*) Versions
*) Root image name
*) Root image tag

e.g. For PKG 1.2.3 based on debian:stretch-slim, you can expect to
find the build scripts in `PKG/1_2_3/debian/stretch-slim`.

A container is then expected to be built by a bash script `build.ah`
which contains the buildah commands used to build and configure the software.

Two other optional scripts are used by the framework: `depends.on`
should contain a ordered, newline delimiter list of containers defined
in the same directory structure that need to be successfully built
before attempting to build this one. If `injectin.to` exists then it
is expected to be an executable shell script that takes two buildah
container ids 'from' and 'to' and then executes relevant buildah
commands to move the built package payload from a build stage into a
runtime container, or a subsequent build step. *N.B.* This may often
include setting up the correct runtime environment in the `to` 
container. Helper functions exist for abstracting the injection of build 
targets from a stage or dependency container into runtime container along
with a few other helper function in `common.funcs`.

## Usage

The steering script: `bashbuild.ah` responds to `--help` like:

```
[RUNLIKE]  -n <pkg> -r <base os:tag> [opts]
	-n <package name>                    : The name of the container 
	                                       package to build.
	-r <package name>                    : The name of the root image 
	                                       to use, this describes the 
	                                       base OS: e.g centos:7
	-v <version>                         : Specify a version of the 
	                                       software to build.
	                                       defaults to "default".
	-D|--root-dir <bb manifest root dir> : The directory to use as the
	                                       root of the container build
	                                       script manifest. This option
	                                       overrides the BB_ROOT env
	                                       var. If BB_ROOT is not set
	                                       then the parent directory of 
	                                       this script will be used.
	-R|--repo <reponame>                 : The registry repo name to
	                                       used.
	                                       this option overrides the
	                                       BB_REPO env var.
	-f|--rebuild-deps                    : This flag will trigger the
	                                       rebuild of all dependent are
	                                       containers. N.B. As 
	                                       containers built by custom 
	                                       scripts, user defined caching
	                                       stages may not be rebuilt. 
	                                       If you mean business, 
	                                       \'buildah rmi --all\'.
	-?|--help                             : Print this message.
```

A helper script for generating the directory structure for a new
container build script is also provided `addabui.ld` which respondes
to `--help` like:

```
./addadabui.ld -?
	-r|--root-dir <bb manifest root dir> : The directory to use as the
	                                       root of the container build
	                                       script manifest. This option
	                                       overrides the BB_ROOT env
	                                       var. If BB_ROOT is not set
	                                       then the parent directory of 
	                                       this script will be used.
	-?|--help                            : Print this message.

```

## Writing build scripts

```//TODO```

### `build.ah` Script environment

Passed a single command line option which is tag expected to be built by this 
invocation.

Available environment variables:

`BB_SCRIPT_DIR`: The directory containing the currently executing bashbuildah instance. Used to set up common functions for use in build scripts.
`BB_REPO_SL`: The repo name with trailing slash if it exists, 
  safe to pre-pend to image name as if no repo was supplied, this will be an 
  empty string.
`ROOT_IT`: The root_image:root_tagname specification.
`BB_PKG_DIR`: The directory containing the build.ah script being executed by 
  `bashbuild.ah` Careful not to rely on this environment variable in `inject.to` 
  scripts as they are designed to be called by `build.ah` scripts from other 
  packages