#!/bin/bash

if ! echo "${BASH_SOURCE}" | grep "/" --silent; then
  BB_SCRIPT_DIR=$(readlink -f $PWD)
else
  BB_SCRIPT_DIR=$(readlink -f ${BASH_SOURCE%/*})
fi

while [[ ${#} -gt 0 ]]; do

  key="$1"
  case $key in

      -r|--root-dir)

      if [[ ${#} -lt 2 ]]; then
        echo "[ERROR]: ${1} expected a value."
        exit 1
      fi

      BB_ROOT="$2"
      echo "[OPT]: BB_ROOT=${BB_ROOT}"
      shift # past argument
      ;;

      -?|--help)
echo -e "\t-r|--root-dir <bb manifest root dir> : The directory to use as the"
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

source $BB_SCRIPT_DIR/common.funcs

NAME=$1
if [ -z $NAME ]; then
  echo "Must specify a Name for the new container structure."
  exit 1
fi
ROOT_IT=$2
if [ -z $ROOT_IT ]; then
  echo "Must specify a root image name for the new container structure."
  exit 1
fi
VERS=$3
if [ -z $VERS ]; then
    VERS=default
fi

if bb_check_exists $NAME $ROOT_IT $VERS; then
  echo "Directory for $NAME with version $VERS rooted on $ROOT_IT already exists."
  exit 1
fi

ROOT_IMAGE=${ROOT_IT%%:*}
ROOT_TAG=${ROOT_IT##*:}
if [ "${ROOT_TAG}" = "${ROOT_IMAGE}" ]; then
    ROOT_TAG=latest
fi

mkdir -p $BB_ROOT/$NAME/$VERS/$ROOT_IMAGE/$ROOT_TAG
echo "#!/bin/bash" > $BB_ROOT/$NAME/$VERS/$ROOT_IMAGE/$ROOT_TAG/build.ah
chmod +x $BB_ROOT/$NAME/$VERS/$ROOT_IMAGE/$ROOT_TAG/build.ah
echo "#!/bin/bash" > $BB_ROOT/$NAME/$VERS/$ROOT_IMAGE/$ROOT_TAG/injectin.to
chmod +x $BB_ROOT/$NAME/$VERS/$ROOT_IMAGE/$ROOT_TAG/injectin.to
echo "# [repo/]NAME[:TAG=latest]         ROOT IMAGE[:tag=latest]  [VERSION=default]"  > $BB_ROOT/$NAME/$VERS/$ROOT_IMAGE/$ROOT_TAG/depends.on

if [ ! "${VERS}" = "default" ]; then
  cd $BB_ROOT/$NAME/
  ln -s $VERS default
fi