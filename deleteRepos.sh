#!/bin/bash

usage() {
  cat <<EOF
    Usage: $(basename $0) options
    where options can be:
      -i, --image-name                name of the image to search
EOF
  exit -1;
}

while [[ $# -gt 1 ]];do
    key="$1"
    case ${key} in
        -i|--image-name)
        imageName="$2"
        echo "Image name: $imageName"
        shift
        ;;
        *)
        ;;
    esac
    shift
done

if [ -z "$imageName" ];
then
  usage;
fi;



echo "searching for images $imageName"

continuationToken=''

while [ "$continuationToken" != "null" ];
do
  if [ ! -z "$continuationToken" ];
  then
    continuationToken=$(curl -s "https://nexus3.pibenchmark.com/nexus/service/rest/v1/search?repository=docker-test&name=$imageName&continuationToken=$continuationToken" | jq '.continuationToken' | cut -d '"' -f2);
    echo "continuationToken obtained = $continuationToken"
    add="&continuationToken=$continuationToken"
  else
    continuationToken=$(curl -s "https://nexus3.pibenchmark.com/nexus/service/rest/v1/search?repository=docker-test&name=$imageName" | jq '.continuationToken' | cut -d '"' -f2);
    echo "continuationToken obtained = $continuationToken"
    add=""
  fi;

  value=$(curl -s "https://nexus3.pibenchmark.com/nexus/service/rest/v1/search?repository=docker-test&name=${imageName}${add}" );
  echo $value | jq '[.items  | .[] | {id,version}] | (.[0] | keys_unsorted) as $keys | ([$keys] + map([.[ $keys[] ]])) [] | @csv' | sed -e "s/[\"|\\]//g"  >> $imageName.csv
done
echo "Jsonfile with id and version created with name ${imageName}.csv"
#curl -v -u nacho.canon:CuchiPandi13 -X DELETE https://nexus3.pibenchmark.com/nexus/service/rest/v1/components/
