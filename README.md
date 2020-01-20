# bashbuildah

Collection of bash scripts for buildah-ing dependent sets of containerized software.

## Top container tip

If being inside a container makes you claustrophobic, you can try pulling
singularities trick of dropping you where you already were (assuming its a
subdir of your home directory) by adding something like this to your
`.bashrc`:

```
function podrun {

  local STRIPPED
  if [ $# -eq 1 ]; then
    local LOC=$(readlink -f .)/
    case ${LOC} in
      $(readlink -f ${HOME})/*)
        local STRIPPED=${LOC##$(readlink -f ${HOME})/}
      ;;
    esac
  fi

  if [ ! -z ${STRIPPED} ]; then
    podman run -itq --rm --volume $(readlink -f ${HOME}):/root \
                        -w /root/${STRIPPED} ${@}
  else
    podman run -itq --rm --volume $(readlink -f ${HOME}):/root $@
  fi

}
```

## Basics

For maximal fragility and ease of scripting, most metadata is purely
directory structure defined.

Containers have 4 bits of metadata:
* Name
* Versions
* Root image name
* Root image tag

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
with a few other helper function in `buildah.funcs`.

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
  -j <ncores>                           : Use <ncores> for builds that
                                          support it.
	-?|--help                             : Print this message.
```

A helper script for generating the directory structure for a new
container build script is also provided `addabui.ld` which responds
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

## Useful user environment variables

* `BB_ROOT`: This points to the root directory of the container build script
             hierarchy. If it is not set, then `pwd` is used.
* `BB_REPO`: This sets the repository prefix on built containers.
* `BB_ROOT_IT`: This sets the root image/tag for all build containers.

## Writing build scripts

```//TODO```

### The package `build.ah` environment

* `BB_SCRIPT_DIR`: The directory containing the currently executing
                 `bashbuild.ah` instance. Used to set up common functions for
                 use in user build scripts.
* `BB_PKG_DIR`: The directory containing the build.ah script being executed
                by `bashbuild.ah` Careful not to rely on this environment variable in `inject.to` scripts as they are designed to be called by other packages `build.ah` scripts.
* `BB_PKG_NAME`: The name of the currently building package
* `BB_PKG_ROOT_IT`: The name of the root package (read OS flavor container) of
                    the currently building dependency tree.
* `BB_PKG_VERS`: The resolved version identifier for the currently building
                 package.
* `BB_PKG_TAG`: The image tag to be used for the currently building package
* `BB_PKG_IMAGE_FQNAME`: The expected full image name for the currently
                         building package, the existence of this image will
                         be checked after the `build.ah` script finishes
                         executing.

### The package `injectin.to` environment

* `BB_INJ_NAME`: The name of the package being injected; *i.e.* the dependent
                 package, as opposed to `BB_PKG_NAME`, which in the
                 environment of the `injectin.to` script will often be the
                 dependee.
* `BB_INJ_VERS`: The version of the package being injected.
