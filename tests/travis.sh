#!/bin/bash
modified_files=$(git --no-pager diff --name-only ${TRAVIS_COMMIT_RANGE})
benchmark_name=${DH_REPO#*/}
tag_name=$IMG_TAG
if [ -z "$modified_files" ]
then
    echo "No Modifications required."
else
    echo "Checking against modified files"
fi
if ( grep -q "$benchmark_name/$tag_name" <<<$modified_files ) ||
   ( grep -q "$benchmark_name" <<<$modified_files && [ $tag_name = "latest" ] ) ||
   ( grep -q "travis.sh" <<<$modified_files ) ||
   ( grep -q ".travis.yml" <<<$modified_files )
then
    travis_wait 40 docker build -t $DH_REPO:$IMG_TAG $DF_PATH
    result=$?
    if [ $result -eq "1" ]
    then
        return 1
    fi
    if [ "${TRAVIS_PULL_REQUEST}" = "false" ] && [ "${TRAVIS_BRANCH}" = "master" ]
    then
        docker login -e="$DOCKER_EMAIL" -u="$DOCKER_USER" -p="$DOCKER_PASS"
        result=$?
        if [ $result -eq "1" ]
        then
            return 1
        fi
  	    travis_wait 40 docker push $DH_REPO
        result=$?
        if [ $result -eq "1" ]
        then
            return 1
        fi
    else
        echo "No push command executed"
  	fi
else
    echo "No Modifications to this image"
fi
