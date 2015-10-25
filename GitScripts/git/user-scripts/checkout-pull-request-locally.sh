#!/bin/bash

set -e

echo -e 'Hello. This script will scan the current git project for open pull requests...\n'

GIT_ORIGIN_URL=`git config remote.origin.url`
if [[ ! $GIT_ORIGIN_URL == */al/* ]]; then
    echo $GIT_ORIGIN_URL
    echo 'This does not look like a master repo...'
    exit 1
fi

if [[ -n `git status --porcelain` ]]; then
    echo 'Warning - the current git index is dirty and would be wiped!'
    read -p "Please confirm that this is what you want (y/n): " CONFIRM
    if [[ ! ( $CONFIRM == 'y' ) ]]; then
        echo 'phhhhh...'
        exit 1
    fi
    git clean -fdx
fi

echo -e 'Updating repo, cleaning work dir & resetting to master branch...\n'

git fetch --quiet origin
git reset --hard --quiet origin/master

echo -e 'Scanning for pull requests...\n'
IFS=$'\n'
i=0
for line in $(git ls-remote -q | grep '/from$')
    do
        (( ++i ))
        PR_NUMBER=`echo $line | awk -F'/' '{print $3}'`
        echo -e "\t$i..PR:$PR_NUMBER"
        PULLREQUEST[$i]=$line
    done

read -p "Choose request to check out (1..$i): " PULL_REQUEST_INDEX

REF_SHA1=`echo ${PULLREQUEST[$PULL_REQUEST_INDEX]} | awk '{ print $1 }'`
REF_PATH=`echo ${PULLREQUEST[$PULL_REQUEST_INDEX]} | awk '{ print $2 }'`
BRANCH_NAME="pull-request-`echo $REF_PATH | awk -F/ '{ print $3 } '`"

git fetch --quiet origin $REF_PATH
git checkout --quiet -B $BRANCH_NAME $REF_SHA1

echo -e '\nChecked out pull request - here are the last 5 commits:\n'

git --no-pager log -5 --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit 

echo -e '\n\nDo you want to soft reset the HEAD (this will enable highlighting of changes in the IDE)? \n'
read -p "Enter amount of commits to go back (0..5): " SOFT_RESET

git reset --quiet HEAD~$SOFT_RESET
git status

echo 'Finished. Happy reviewing...'
