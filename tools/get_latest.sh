#!/bin/env bash

set -x

usage="Usage: \
    \n\tbash $0 [options] \
    \nOptions:  \
    \n\t-o owner \
    \n\t-r reposition \
    \n\t-n save name \
    \n\t-h help: \
    \nExample: \
    \n\t bash $0 -h
    "

usage() {
    echo -e "$usage" >&2
    exit 1
}

while getopts :o:r:n:h opt
do
    case "$opt" in
        o) 
            owner=${OPTARG}
            ;;
        r)
            repo=${OPTARG}
            ;;
        n)
            fileName=${OPTARG}
            ;;
        h)
            usage
            ;;
        \?)
            usage
            ;;
    esac
done

die() {
     echo -e '\033[40;31m$1 !!!\033[0m' >&2
     exit 1
}
[ -z "$owner" ] && usage
curl -s https://api.github.com/repos/$owner/$repo/releases/latest -o latest.json
oldver=$(cat latest.json| python -c 'import sys; from json import loads as l; print(l(sys.stdin.read())["tag_name"])')
[ -z "$oldver" ] && die "not find $owner/$repo"
downloadUrl=$(jq '.assets|map(.browser_download_url)| map(select(test(".*-'$oldver'-.*.tar.zst"))) | first' latest.json)
downloadUrl=${downloadUrl//\"/}
[[ -z $fileName ]] && fileName=$(basename ${downloadUrl})
curl -sL ${downloadUrl} -o $fileName || die "$owner/$repo downloading failed!"
echo "$owner/$repo: $fileName donwloaded!"

