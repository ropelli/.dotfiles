#!/usr/bin/env bash
set -xe

# this script will add a layer to an existing docker image
# image must be prepulled
# layer is given like a dockerfile command
# but ADD is -a, RUN is -r, ENV is -e, WORKDIR is -w
# if a file is copied into image, it must be provided via stdin
# folder are not supported

# examples:
# echo 'content' | add-docker-layer.sh -a /tmp/file.txt ubuntu:latest  # add file.txt with content to /tmp/file.txt in ubuntu:latest image
# echo 'content' | add-docker-layer.sh -a /tmp/file.txt ubuntu:latest my-image:latest # same as above but tag the image as my-image:latest
# add-docker-layer.sh -r 'apt-get update && apt-get install -y curl' ubuntu:latest  # run apt-get update and install curl in ubuntu:latest image
# add-docker-layer.sh -e MY_VAR=123 ubuntu:latest  # set MY_VAR=123 in ubuntu:latest image
# add-docker-layer.sh -w /tmp ubuntu:latest  # set WORKDIR /tmp in ubuntu:latest image

# parse arguments
should_create_tempfile=false

while getopts ":a:c:r:e:w:" opt; do
    case ${opt} in
        a )
          command="ADD tempfile $OPTARG"
          should_create_tempfile=true
          ;;
        r )
          command="RUN $OPTARG"
          ;;
        e )
          command="ENV $OPTARG"
          ;;
        w )
          command="WORKDIR $OPTARG"
          ;;
        \? )
          echo "Usage: add-docker-layer.sh -a|-c|-r|-e|-w <command> <image> [<tag>]"
          exit 1
          ;;
    esac
done

shift $((OPTIND -1))
image=$1
tag=$2

# check if image exists
if ! docker inspect --type=image "$image" &> /dev/null; then
    echo "Image $image not found, consider pulling it first" >&2
    exit 1
fi

# create a temporary directory
tempdir=$(mktemp -d)
if [ -n "$tempdir" ]; then
    # shellcheck disable=SC2064
    trap "rm -rf $tempdir" EXIT
fi

echo "FROM $image" > "$tempdir/Dockerfile"
echo "$command" >> "$tempdir/Dockerfile"

if [ "$should_create_tempfile" = true ]; then
    tempfile=$tempdir/tempfile
    cat > "$tempfile"
fi

# build the image
if [ -n "$tag" ]; then
    docker build -t "$tag" "$tempdir"
else
    docker build "$tempdir"
fi

