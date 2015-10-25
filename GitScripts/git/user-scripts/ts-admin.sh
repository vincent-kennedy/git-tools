#!/bin/sh
# Git admin script
# Author: Andreas Borglin

VERSION=1.0

# Configuration parameters
SCRIPT_FILE=ts-admin.sh
JAR_DST=/usr/bin/AtlassianIntegration.jar
PROFILE=~/.profile
SSH_CONFIG=~/.ssh/config
FEATURE_PREFIX=feature
RELEASE_PREFIX=release
HOTFIX_PREFIX=hotfix
SUPPORT_PREFIX=support
EXPERIMENTAL_PREFIX=experimental
MERGE_PREFIX=merge
DEVELOP=develop
MASTER=master
ORIGIN=origin
ARCHIVE_REF=refs/archive
ARCHIVE_FEATURES=features
ARCHIVE_RELEASES=releases
ARCHIVE_EXPERIMENTAL=experimental


# Print script usage to user
show_usage() {
    echo ""
    echo " * Git Admin Helper Script *"
    echo "   Version: $VERSION"
    echo ""
    echo "Available commands:"
    echo " -- Features"
    echo "  create-feature         (Create a new remote $FEATURE_PREFIX branch off the remote $DEVELOP branch)"
    echo "  merge-feature-develop  (Merge $FEATURE_PREFIX to $DEVELOP and push to Stash)"
    echo "  archive-feature        (Archive a feature branch via pushing it to a non-branch refspec)"
    echo "  delete-feature         (Delete $FEATURE_PREFIX branch)"
    echo ""
    echo " -- Releases"
    echo "  create-release         (Create a new remote $RELEASE_PREFIX branch off the remote $DEVELOP branch)"
    echo "  merge-release-master   (Merge $RELEASE_PREFIX to $MASTER and push to Stash)"
    echo "  merge-release-develop  (Merge $RELEASE_PREFIX back to $DEVELOP and push to Stash)"
    echo "  archive-release        (Archive a release branch via pushing it to a non-branch refspec)"
    echo "  delete-release         (Delete $RELEASE_PREFIX branch once merged to $MASTER and $DEVELOP)"
    echo "  tag-master             (Tag master after a release)"
    echo ""
    echo " -- Hotfixes"
    echo "  create-hotfix          (Create a new remote $HOTFIX_PREFIX branch off the remote $MASTER branch)"
    echo "  merge-hotfix-master    (Merge $HOTFIX_PREFIX to $MASTER and push to Stash)"
    echo "  merge-hotfix-develop   (Merge $HOTFIX_PREFIX back to $DEVELOP and push to Stash)"
    echo "  delete-hotfix          (Delete $HOTFIX_PREFIX branch once merged to $MASTER and $DEVELOP)"
    echo ""
    echo " -- Other"
    echo "  create-support         (Create a $SUPPORT_PREFIX branch from $MASTER)"
    echo "  create-experimental    (Create a new remote $EXPERIMENTAL_PREFIX branch)"
    echo "  archive-experimental   (Archive an experimental feature branch via pushing it to a non-branch refspec)"
    echo "  delete-branch          (Delete any type of remote branch)"
    echo ""
    echo "NOTE: These actions are for the master repo only - not your fork!"
    echo ""
}

# Parse the user provided command
parse_command() {
    if [ "$1" = "copy" ]
    then
        copy
    elif [ "$1" = "create-feature" ]
    then
        create_feature
    elif [ "$1" = "merge-feature-develop" ]
    then
        merge_feature_develop $2
    elif [ "$1" = "delete-feature" ]
    then
        delete_feature $2
    elif [ "$1" = "create-release" ]
    then
        create_release
    elif [ "$1" = "delete-release" ]
    then
        delete_release $2
    elif [ "$1" = "merge-release-master" ]
    then
        merge_release_master
    elif [ "$1" = "merge-release-develop" ]
    then
        merge_release_develop
    elif [ "$1" = "create-hotfix" ]
    then
        create_hotfix
    elif [ "$1" = "merge-hotfix-master" ]
    then
        merge_hotfix_master
    elif [ "$1" = "merge-hotfix-develop" ]
    then
        merge_hotfix_develop
    elif [ "$1" = "delete-hotfix" ]
    then
        delete_hotfix
    elif [ "$1" = "tag-master" ]
    then
        tag_master
    elif [ "$1" = "create-support" ]
    then
        create_support
    elif [ "$1" = "create-experimental" ]
    then
        create_experimental
    elif [ "$1" = "delete-branch" ]
    then
        delete_any_branch
    elif [ "$1" = "archive-feature" ]
    then
        archive_feature
    elif [ "$1" = "archive-release" ]
    then
        archive_release
    elif [ "$1" = "archive-experimental" ]
    then
        archive_experimental
    else
        echo "Unknown command."
        show_usage
    fi

}

# Utility function for allowing user to select a remote branch
# Result is stored in input parameter variable via eval
read_remote_branch() {
    local _RESULTVAR=$1
    local filter=$2
    local BRANCHES
    i=0
    for key in $(git branch -r | tail -n +2)
    do
        if [[ "$key" == *$filter* ]]
        then
            (( ++i ))
            branch=${key/$ORIGIN\//}
            echo "$i - $branch"
            BRANCHES[$i]=$branch
        fi
    done

    read -p "Entry (1..$i): " REMOTE_BRANCH_INDEX

    die_if_empty "remote branch" $REMOTE_BRANCH_INDEX

    if [[ $REMOTE_BRANCH_INDEX != *[!0-9]* ]] && [ $REMOTE_BRANCH_INDEX -ge 1 ] && [ $REMOTE_BRANCH_INDEX -le $i ]
    then
        REMOTE_BRANCH_1=${BRANCHES[$REMOTE_BRANCH_INDEX]}
    else
        die "Entry out of range."
    fi

    eval $_RESULTVAR="'$REMOTE_BRANCH_1'"
}

# Finish feature - merge to develop
merge_feature_develop() {
    merge_branch $FEATURE_PREFIX $DEVELOP "true"
}

# Delete feature branch
delete_feature() {
    delete_branch "$FEATURE_PREFIX" "my-great-feature"
}

# Creates a feature branch off develop
create_feature() {
    create_branch "$DEVELOP" "$FEATURE_PREFIX" "Branch for a coherent piece of functionality. Name example: my-great-feature"
}

# Merge release branch to master
merge_release_master() {
    merge_branch $RELEASE_PREFIX $MASTER "false"
}

# Merge release back to develop
merge_release_develop() {
    merge_branch $RELEASE_PREFIX $DEVELOP "true"
}

# Delete release branch
delete_release() {
    delete_branch "$RELEASE_PREFIX" "1.2"
}

#Creates a release branch
create_release() {
    create_branch "$DEVELOP" "$RELEASE_PREFIX" "Example: 1.2"
}

# Tag master
tag_master() {
    tag_branch $MASTER "1.2"
}

create_hotfix() {
    create_branch "$MASTER" "$HOTFIX_PREFIX" "Hotfix branch"
}

merge_hotfix_master() {
    merge_branch "$HOTFIX_PREFIX" "$MASTER" "false"
}

merge_hotfix_develop() {
    merge_branch "$HOTFIX_PREFIX" "$DEVELOP" "true"
}

delete_hotfix() {
    delete_branch "$HOTFIX_PREFIX" "hotfix"
}

# Create support branch
create_support() {
    create_branch "$MASTER" "$SUPPORT_PREFIX" "Example: 1.2.1.1"
}

# Create experimental branch
create_experimental() {
    echo "Which branch do you want to base off?"
    read BRANCH_ORIGIN

    die_if_empty "origin branch" $BRANCH_ORIGIN
    
    create_branch "$BRANCH_ORIGIN" "$EXPERIMENTAL_PREFIX" "Example: grid-prototype"
}

delete_any_branch() {
    echo "What type of branch do you want to delete? Ex: feature, release, experimental."
    read BRANCH_TYPE
    die_if_empty "branch type" $BRANCH_TYPE
    delete_branch "$BRANCH_TYPE" "..."
}

# Tag a branch
tag_branch() {
    local BRANCH=$1
    local EXAMPLE=$2

    echo "What should the tag be named? Example: $EXAMPLE"
    read TAG_NAME

    die_if_empty "tag name" $TAG_NAME

    git checkout $BRANCH
    git pull
    git tag -a $TAG_NAME
    git push --tags

}

push_for_review() {

	# Fetch the local branch name
    local LOCALBRANCH=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
	# Fetch the remote (origin) branch name and strip of origin/
    local REMOTEBRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} | sed ' s/origin\/// ')

	# Push the local branch to remote
	git push $ORIGIN $LOCALBRANCH || die "Failed to push local branch to Stash"

	# Now, only create a pull request if we are tracking the destination branch
	if [ "$LOCALBRANCH" != "$REMOTEBRANCH" ]
    then
		# Get the commit message title (first line)
		local COMMIT_TITLE=$(git log -1 --pretty=format:%s)
		local REPO_NAME=$(basename $(git remote show -n origin | grep Push | cut -d: -f2- | sed 's/.git$//'))

		echo "Creating pull request from $LOCALBRANCH to $REMOTEBRANCH..."

        java -jar $JAR_DST pullRequest --repo="$REPO_NAME" --srcBranch="$LOCALBRANCH" --destBranch="$REMOTEBRANCH" --commitTitle="$COMMIT_TITLE" --fromUserRepo=false --debug=true

		# Now, track the pushed branch instead so that we can push updates
		git branch -u $ORIGIN/$LOCALBRANCH

	else
		echo "Pull request has been updated with new commit"
	fi

}

# Perform a merge from one branch to another
merge_branch() {
    
    local BRANCH_TYPE=$1
    local TARGET_BRANCH=$2 # Should be develop or master
    local PUSH_DIRECTLY=$3

    echo "What $BRANCH_TYPE branch do you want to merge from?"
    read_remote_branch FROM_BRANCH $BRANCH_TYPE

    die_if_empty "branch name" $FROM_BRANCH

    echo "Preparing merge..."
    git fetch
    # Create a local merge branch as develop/master are downstream branches only
    git checkout --track -b $MERGE_PREFIX/$FROM_BRANCH $ORIGIN/$TARGET_BRANCH || die "Branch already exists? Delete first"
    git pull # Make sure it's up to date

    # Do a merge into a merge branch (force merge commit via --no-ff)
    git merge --no-ff -m "Merge $FROM_BRANCH into $TARGET_BRANCH" $ORIGIN/$FROM_BRANCH || die "Failed to merge automatically. Resolve conflicts, commit, run tests and push to Stash."
    # Now, let user edit commit msg if required.
    git commit --amend

    # As we're still here, we can assume that there was no conflict and we should check whether we should push directly
    if [ "$PUSH_DIRECTLY" == "true" ]
    then
        git push "$ORIGIN" "$MERGE_PREFIX/$FROM_BRANCH:$TARGET_BRANCH" || die "Push failed"
        # Now, we know the merge is all done and pushed, so let's delete the merge branch
        echo "Switching to develop and deleting merge branch.."
        git checkout $DEVELOP
        git branch -D $MERGE_PREFIX/$FROM_BRANCH
        echo "Merge completed and pushed."
    else
        echo "The merge was completed without conflicts. Do what you need to and then push it to origin"
        echo "You can delete the merge branch once the merge has been pushed."
    fi

}

# Delete branch
delete_branch() {

    local BRANCH_TYPE=$1
    local BRANCH_NAME_HINT=$2

    echo "Which branch do you want to delete?"
    read_remote_branch BRANCH_NAME $BRANCH_TYPE

    die_if_empty "branch name" $BRANCH_NAME
   
    echo "This will delete $ORIGIN/$BRANCH_NAME permanently!"
    echo "This should only be done after it's been merged and archived, or to discard the work!"
    continue_or_abort
    echo "Deleting branch..."

    git push $ORIGIN :refs/heads/$BRANCH_NAME || die "Failed to delete $ORIGIN/$BRANCH_NAME remotely. Sure it exists?"
    echo "Branch $ORIGIN/$BRANCH_NAME deleted!"

}

# Create branch
create_branch(){
    local BRANCH_ORIGIN=$1
    local BRANCH_TYPE=$2
    local BRANCH_FORMAT_HINT=$3

    # Fetch the remote repo name
    local REPO=$(git config --get remote.origin.url | sed ' s!.*/!! ')
    echo "What should the $BRANCH_TYPE branch be named? $BRANCH_FORMAT_HINT"
    read BRANCH_NAME

    die_if_empty "branch name" $BRANCH_NAME
    
    local NEW_BRANCH=$BRANCH_TYPE/$BRANCH_NAME

    echo "The following branch will be created: $NEW_BRANCH [off the $BRANCH_ORIGIN branch]"
    continue_or_abort

    echo "Pushing branch to Stash... "
    git push $ORIGIN $ORIGIN/$BRANCH_ORIGIN:refs/heads/$NEW_BRANCH || die "Failed to create branch $NEW_BRANCH"
    echo "Branch created: $NEW_BRANCH"
    
}

archive_feature() {

    echo "Which feature branch do you want to archive?"
    read_remote_branch REMOTE_BRANCH $FEATURE_PREFIX

    echo "Which version does the feature belong to (e.g 4.1)"
    read VERSION

    echo "What do you want to name the archived branch as? Leave empty to keep name as is."
    read BRANCH_NAME

    if [ -z "$BRANCH_NAME" ]
    then
        BRANCH_NAME=${REMOTE_BRANCH/$FEATURE_PREFIX\//}
    fi

    echo "$REMOTE_BRANCH will be archived to $ARCHIVE_REF/$ARCHIVE_FEATURES/$VERSION/$BRANCH_NAME"
    continue_or_abort

    echo "Pushing to Stash..."
    git push $ORIGIN $ORIGIN/$REMOTE_BRANCH:$ARCHIVE_REF/$ARCHIVE_FEATURES/$VERSION/$BRANCH_NAME
}

archive_release() {

    echo "Which release branch do you want to archive?"
    read_remote_branch REMOTE_BRANCH $RELEASE_PREFIX

    VERSION=${REMOTE_BRANCH/$RELEASE_PREFIX\//}

    echo "$REMOTE_BRANCH will be archived to $ARCHIVE_REF/$ARCHIVE_RELEASES/$VERSION"
    continue_or_abort

    echo "Pushing to Stash..."
    git push $ORIGIN $ORIGIN/$REMOTE_BRANCH:$ARCHIVE_REF/$ARCHIVE_RELEASES/$VERSION
}


archive_experimental() {
    echo "Which experimental feature branch do you want to archive?"
    read_remote_branch REMOTE_BRANCH $EXPERIMENTAL_PREFIX

    echo "What do you want to name the archived branch as? Leave empty to keep name as is."
    read BRANCH_NAME

    if [ -z "$BRANCH_NAME" ]
    then
        BRANCH_NAME=${REMOTE_BRANCH/$EXPERIMENTAL_PREFIX\//}
    fi

    echo "$REMOTE_BRANCH will be archived to $ARCHIVE_REF/$ARCHIVE_EXPERIMENTAL/$BRANCH_NAME"
    continue_or_abort

    echo "Pushing to Stash..."
    git push $ORIGIN $ORIGIN/$REMOTE_BRANCH:$ARCHIVE_REF/$ARCHIVE_EXPERIMENTAL/$BRANCH_NAME
}


# Copy script to Git path
copy() {
    echo "Installing script on git path"

    local GIT_PATH=$(which git)
    local SUDO_AVAILABLE=$(which sudo)
 
    if [ -z $SUDO_AVAILABLE ]
    then 
        cp $SCRIPT_FILE "$GIT_PATH-tsadmin"
    else
        echo "Requires sudo and hence your password"
        sudo cp $SCRIPT_FILE "$GIT_PATH-tsadmin"
    fi

    echo "Script successfully installed to $GIT_PATH-tsadmin"
    echo "You can now use git tsadmin <command> to perform admin tasks"
}

# Print error message and exit
die() {
    echo "$1"
    exit 1
}

die_if_empty() {
    if [ "$2" == "" ]
    then 
       die "No $1 supplied. Aborting"
    fi
}

continue_or_abort() {
    echo "Do you want to continue (y/n)?"
    read CONTINUE

    if [ $CONTINUE != "y" ]
    then 
       die "Aborted"
    fi
}

# Check number of commands
if [ $# -ge 1 ]
then
    parse_command $@
else
    show_usage
fi