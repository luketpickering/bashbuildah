#!/bin/bash

PKG_NAME=""
PKG_ROOT_IT=""
PKG_VERS="default"

if ! echo "${BASH_SOURCE}" | grep "/" --silent; then
  BB_SCRIPT_DIR=$(readlink -f $PWD)
else
  BB_SCRIPT_DIR=$(readlink -f ${BASH_SOURCE%/*})
fi

while [[ ${#} -gt 0 ]]; do

  key="$1"
  case $key in

      -n)

      if [[ ${#} -lt 2 ]]; then
        echo "[ERROR]: ${1} expected a value."
        exit 1
      fi

      PKG_NAME="$2"
      echo "[OPT]: Attempting to build package named: \"${PKG_NAME}\""
      shift # past argument
      ;;

      -r)

      if [[ ${#} -lt 2 ]]; then
        echo "[ERROR]: ${1} expected a value."
        exit 1
      fi

      PKG_ROOT_IT="$2"
      echo "[OPT]: Building for root image: \"${PKG_ROOT_IT}\""
      shift # past argument
      ;;

      -v)

      if [[ ${#} -lt 2 ]]; then
        echo "[ERROR]: ${1} expected a value."
        exit 1
      fi

      PKG_VERS="$2"
      echo "[OPT]: Building version: \"${PKG_VERS}\""
      shift # past argument
      ;;


      -D|--root-dir)

      if [[ ${#} -lt 2 ]]; then
        echo "[ERROR]: ${1} expected a value."
        exit 1
      fi

      BB_ROOT="$2"
      echo "[OPT]: BB_ROOT=${BB_ROOT}"
      shift # past argument
      ;;

      -?|--help)
echo "[RUNLIKE] ${SCRIPTNAME} -n <pkg> -r <base os:tag> [opts]"
echo -e "\t-n <package name>                    : The name of the container "
echo -e "\t                                       package to build."
echo -e "\t-r <package name>                    : The name of the root image "
echo -e "\t                                       to use, this describes the "
echo -e "\t                                       base OS: e.g centos:7"
echo -e "\t-v <version>                         : Specify a version of the "
echo -e "\t                                       software to build."
echo -e "\t                                       defaults to \"default\"."
echo -e "\t-D|--root-dir <bb manifest root dir> : The directory to use as the"
echo -e "\t                                       root of the container build"
echo -e "\t                                       script manifest. This option"
echo -e "\t                                       overrides the BB_ROOT env"
echo -e "\t                                       var. If BB_ROOT is not set"
echo -e "\t                                       then the parent directory of "
echo -e "\t                                       this script will be used."
echo -e "\t-?|--help                            : Print this message."
      exit 0
      ;;

      *)
              # unknown option
      echo "Unknown option $1"
      exit 1
      ;;
  esac
  shift # past argument or value
done

if [ -z ${BB_ROOT} ]; then
  BB_ROOT=${BB_SCRIPT_DIR}
fi

export BB_ROOT

source ${BB_SCRIPT_DIR}/framework.funcs

if [ -z $PKG_NAME ]; then
  echo "Must specify a Name for the new container structure."
  exit 1
fi
if [ -z $PKG_ROOT_IT ]; then
  echo "Must specify a root image name for the new container structure."
  exit 1
fi
PKG_VERS=$3
if [ -z $PKG_VERS ]; then
    PKG_VERS=default
fi

if bb_check_dir_structure $PKG_NAME $PKG_ROOT_IT $PKG_VERS; then
  echo "Directory for $PKG_NAME with version $PKG_VERS rooted on $PKG_ROOT_IT already exists."
  exit 1
fi

PKG_ROOT_IMAGE=${PKG_ROOT_IT%%:*}
PKG_ROOT_TAG=${PKG_ROOT_IT##*:}
if [ "${PKG_ROOT_TAG}" = "${PKG_ROOT_IMAGE}" ]; then
    PKG_ROOT_TAG=latest
fi

mkdir -p $BB_ROOT/$PKG_NAME/$PKG_VERS/$PKG_ROOT_IMAGE/$PKG_ROOT_TAG
echo "#!/bin/bash" > $BB_ROOT/$PKG_NAME/$PKG_VERS/$PKG_ROOT_IMAGE/$PKG_ROOT_TAG/build.ah
chmod +x $BB_ROOT/$PKG_NAME/$PKG_VERS/$PKG_ROOT_IMAGE/$PKG_ROOT_TAG/build.ah
echo "#!/bin/bash" > $BB_ROOT/$PKG_NAME/$PKG_VERS/$PKG_ROOT_IMAGE/$PKG_ROOT_TAG/injectin.to
chmod +x $BB_ROOT/$PKG_NAME/$PKG_VERS/$PKG_ROOT_IMAGE/$PKG_ROOT_TAG/injectin.to
echo "# PKG_NAME[@Version=default][:Tag=<ROOT_IMAGE_TAG>] ROOT_IMAGE_NAME[:Tag=latest]"  > $BB_ROOT/$PKG_NAME/$PKG_VERS/$PKG_ROOT_IMAGE/$PKG_ROOT_TAG/depends.on

if [ ! "${PKG_VERS}" = "default" ]; then
  cd $BB_ROOT/$PKG_NAME/
  ln -s $PKG_VERS default
fi
