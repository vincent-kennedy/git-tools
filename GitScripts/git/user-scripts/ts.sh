#!/bin/bash
# Author: Andreas Borglin

VERSION=0#=DEPLOY.VERSION
DEPLOYED=0#=DEPLOY.DATE

ORIGIN=origin
PROFILE=~/.profile
SCRIPT_FILE=ts.sh
UTILS=utils
JAR_SRC=$UTILS/AtlassianIntegration.jar
JAR_DST=/usr/bin/AtlassianIntegration.jar
STASH_HOST=ssh://git@YOUR_STASH_HOST
PROJECT_KEY=al

JIRA_START_REVIEW="startReview"
JIRA_COMPLETED="completed"

# Print script usage to user
show_usage() {
    echo ""
    echo " * Git Helper Script *"
    echo "   Version: $VERSION"
	echo "   Created: $DEPLOYED"
    echo ""
    echo " -- Repository"
    echo "  clone               (Clones repo from the master repo)"
    echo "  clone-fork          (Clones repo from your fork)"
    echo ""
    echo " -- Topic Branches"
    echo "  start-topic  || st  (Start a new topic branch for implementation or bug fixes)"
    echo "  finish-topic || ft  (Resolves JIRA tasks and deletes topic branch)"
    echo "  delete-topic || dt  (Delete topic branch locally and remotely. Only use when pull request has been merged!)"
    echo ""
    echo " -- Create pull request"
    echo "  review              (Pushes branch to Stash and creates pull request. Args: [nojira] [debug])"
    echo ""
    echo " -- Utils"
    echo "  lbm                 (List which remote branches your local branches are tracking)"
    echo "  rm-deleted          (Remove all deleted files from repo)"
    echo "  prune               (Prune stale branches)"
    echo ""
    echo " -- Setup / Install"
	echo "  setup               (Set up your Git environment)"
	echo "  install             (Install script on your path)"
	echo "  set-auth-details    (Set/Update and persist auth details for API comms)"
}

# Parse the user provided command
parse_command() {
	if [ "$1" = "setup" ]
    then
        setup
    elif [ "$1" = "clone" ]
    then
        clone $2
    elif [ "$1" = "clone-fork" ]
    then
        clone_fork $2
	elif [ "$1" = "copy" ] || [ "$1" = "install" ]
    then
        copy
    elif [ "$1" = "review" ]
    then
        review $2
    elif [ "$1" = "start-topic" ] || [ "$1" = "st" ]
    then
        start_topic $2 $3
    elif [ "$1" = "finish-topic" ] || [ "$1" = "ft" ]
    then
        finish_topic $2
    elif [ "$1" = "delete-topic" ] || [ "$1" = "dt" ]
    then
        delete_topic $2
    elif [ "$1" = "lbm" ]
    then
        list_branch_mapping
    elif [ "$1" = "rm-deleted" ]
    then
        remove_deleted
    elif [ "$1" = "prune" ]
    then
        prune
    elif [ "$1" = "set-auth-details" ]
    then
        set_auth_details
    else
        echo "Unknown command."
        show_usage
    fi

}

# Clone a repository from Stash
clone() {
    if [ -z $1 ]
    then
        echo "Which repo would you like to clone?"
        read REPO_NAME

        die_if_empty "repo name" $REPO_NAME
    else
        REPO_NAME=$1
    fi

    git clone $STASH_HOST/$PROJECT_KEY/$REPO_NAME.git || die "Failed to clone repo $REPO_NAME"

    echo "Repository $REPO_NAME cloned!"
}

# Clone a user fork from Stash
clone_fork() {
    if [ -z $1 ]
    then
        echo "Which repo would you like to clone?"
        read REPO_NAME

        die_if_empty "repo name" $REPO_NAME
    else
        REPO_NAME=$1
    fi

    echo "What is your Stash user name?"
    read USER_NAME

    die_if_empty "user name" $USER_NAME

    git clone $STASH_HOST/~$USER_NAME/$REPO_NAME.git || die "Failed to fork - Have you created your fork in Stash?"

}
# Utility function for allowing user to select a remote branch
# Result is stored in input parameter variable via eval
read_remote_branch() {
    local _RESULTVAR=$1
    local BRANCHES
    i=0
    for KEY in $(git branch -r | tail -n +2)
    do
        BRANCH=${KEY/$ORIGIN\//}
        if [ "$BRANCH" == "master" ] || [ "$BRANCH" == "develop" ] || [[ $BRANCH == */* ]]
        then
            (( ++i ))
            echo "$i - $BRANCH"
            BRANCHES[$i]=$BRANCH
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

read_topic_branch() {
    local _RESULTVAR=$1
    local BRANCHES
    i=0
    for key in $(git for-each-ref --format='%(refname:short)' refs/heads)
    do
        if [ "$key" != "master" ] && [ "$key" != "develop" ]
        then
            (( ++i ))
            branch=$key
            echo "$i - $branch"
            BRANCHES[$i]=$branch
        fi
    done

    read -p "Entry (1..$i): " TOPIC_BRANCH_INDEX

    die_if_empty "topic branch" $TOPIC_BRANCH_INDEX

    if [[ $TOPIC_BRANCH_INDEX != *[!0-9]* ]] && [ $TOPIC_BRANCH_INDEX -ge 1 ] && [ $TOPIC_BRANCH_INDEX -le $i ]
    then
        TOPIC_BRANCH=${BRANCHES[$TOPIC_BRANCH_INDEX]}
    else
        die "Entry out of range."
    fi

    eval $_RESULTVAR="'$TOPIC_BRANCH'"

}

read_jira_task() {
    local _RESULTVAR=$1
    echo "Which JIRA task is this topic for? (All uppercase: JIRA-123)"
    read -p "JIRA task: " JIRA_TASK
    eval $_RESULTVAR="'$JIRA_TASK'"
}

start_topic() {
    local TOPIC_BRANCH

    if [ -z $2 ]
    then
        echo "Which remote branch should this be based off? (If the desired branch is not on the list, run 'git fetch' first)"

        read_remote_branch REMOTE_BRANCH

        echo ""
        echo "What should the topic branch be named?"
        read TOPIC_BRANCH

        die_if_empty "branch name" $TOPIC_BRANCH
    else
        REMOTE_BRANCH=$1
        die_if_empty "remote branch" $REMOTE_BRANCH

        TOPIC_BRANCH=$2
        die_if_empty "branch name" $TOPIC_BRANCH
    fi

    echo "$TOPIC_BRANCH will be created based off $REMOTE_BRANCH"
    continue_or_abort
    echo ""
    echo "Creating branch..."

    # Create local topic branch off destination branch
    git checkout -b $TOPIC_BRANCH $ORIGIN/$REMOTE_BRANCH || die "Failed to create topic off remote branch $REMOTE_BRANCH. Sure it exists?"

    # Push topic to fork and start tracking it
    git push -u $ORIGIN $TOPIC_BRANCH || die "Failed to push branch to fork."

    # Add destination and base commit to branch config
    git config --add branch.$TOPIC_BRANCH.destination $REMOTE_BRANCH
    local BASE_COMMIT=$(git rev-parse HEAD)
    git config --add branch.$TOPIC_BRANCH.basecommit $BASE_COMMIT

    echo ""
    echo "Do not forget to start progress on the corresponding JIRA task/issue."
}

force_delete() {
    echo "$1 has not been merged and can't be safely deleted."
    echo "Do you want to force-delete it locally and in your fork?"
    echo "WARNING: You will lose any changes done here so be sure!"
    continue_or_abort
    echo ""
    git branch -D $1 || die "Failed to force delete branch"
    git push origin :$1
    echo "Branch $1 deleted"
}

finish_topic() {

    if [ -z $1 ]
    then
        echo "Which topic branch do you want to finish?"
        echo "NOTE: This will complete JIRA tasks and then delete the topic!"

        read_topic_branch TOPIC_BRANCH
    else
        TOPIC_BRANCH=$1
    fi

    echo "Updating JIRA issues..."
    local BASECOMMIT=$(git config branch.$TOPIC_BRANCH.basecommit)
    java -jar $JAR_DST transitionIssue --topicBranch="$TOPIC_BRANCH" --baseCommit="$BASECOMMIT" --transition="$JIRA_COMPLETED" --debug="false" || echo "Failed to update JIRA issues"

    delete_topic $TOPIC_BRANCH
}

delete_topic() {
    if [ -z $1 ]
    then
        echo "Which topic branch do you want to delete?"
        echo "NOTE: This will delete your local branch and the remote branch in your fork!"

        read_topic_branch TOPIC_BRANCH
    else
        TOPIC_BRANCH=$1
    fi
    echo "Deleting topic branch..."
    git fetch
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$CURRENT_BRANCH" == "$TOPIC_BRANCH" ]]
    then
        git checkout master
    fi
    git branch -d $TOPIC_BRANCH || force_delete $TOPIC_BRANCH
    git push origin :$TOPIC_BRANCH
    git remote prune origin
    echo "Branch $TOPIC_BRANCH deleted"
}


review() {

    # Check Java version
    JAVA_VER=$(java -version 2>&1 | sed 's/java version "\(.*\)\.\(.*\)\..*"/\1\2/; 1q')
    if [ "$JAVA_VER" -lt 17 ]
    then
        die "You need at least Java 7 installed to run this command. Please install Java 7 JDK"
    fi
	
	# Fetch the local branch name
    local LOCALBRANCH=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
	# Fetch the remote (origin) branch name and strip of origin/
    local REMOTEBRANCH=$(git config branch.$LOCALBRANCH.destination)

	local PR_EXISTS=$(git config branch.$LOCALBRANCH.pr-created)

	# Ensure all the changes on the branch have been pushed
	echo "Pushing local changes..."
	git push || die "Failed to push to Stash. Perhaps you need to force push?"

	# Now, only create a pull request if we haven't created one already
	if [ -z $PR_EXISTS ]
    then
		# Get the commit message title (first line)
		local COMMIT_TITLE=$(git log -1 --pretty=format:%s)
		local REPO_NAME=$(basename $(git remote show -n origin | grep Push | cut -d: -f2- | sed 's/.git$//'))
		
		echo "Creating pull request from $LOCALBRANCH to $REMOTEBRANCH..."

        # This is a retarded way of checking params, but good enough for now...
		local DEBUG=false
		local DOJIRA=true
		if [ -n $1 ] && [ "$1" = "debug" ]
		then
		    DEBUG=true
		fi

        if [ -n $1 ] && [ "$1" = "nojira" ]
        then
		    DOJIRA=false
		fi

		if [ -n $2 ] && [ "$2" = "debug" ]
		then
			DEBUG=true
		fi
	
		# Call Java app to create pull request
        java -jar $JAR_DST pullRequest --repo="$REPO_NAME" --srcBranch="$LOCALBRANCH" --destBranch="$REMOTEBRANCH" --commitTitle="$COMMIT_TITLE" --debug="$DEBUG" || die "Failed to create PR"
		git config --add branch.$LOCALBRANCH.pr-created true

        if [ "$DOJIRA" = true ]
        then
		    # Update any JIRA issues associated with this
		    echo "Updating JIRA issues..."
		    local BASECOMMIT=$(git config branch.$LOCALBRANCH.basecommit)
		    echo "baseCommit: $BASECOMMIT"
		    java -jar $JAR_DST transitionIssue --topicBranch="$LOCALBRANCH" --destBranch="origin/$REMOTEBRANCH" --baseCommit="$BASECOMMIT" --transition="$JIRA_START_REVIEW" --debug="$DEBUG" || echo "Failed to update JIRA issues"
        fi

	else
		echo "Pull request has been updated with new commit"
	fi

}

list_branch_mapping() {
    git for-each-ref --format='%(refname:short) <- %(upstream:short)' refs/heads
}

remove_deleted() {
    git ls-files -z --deleted | xargs -0 git rm
}

prune() {
    git remote prune origin
}

set_auth_details() {
    echo ""
    echo "Do you want to persist username and password (encrypted) or just username and enter password for each pull request?"
    echo "1: Persist username and password"
    echo "2. Persist username only"
    read -p "1 or 2: " CHOICE
    if [[ "$CHOICE" == "1" ]]
    then
        FLAG="--persistDetails"
    else
        FLAG="--persistUserName"
    fi
    java -jar $JAR_DST authDetails $FLAG
}

# Copy script to Git path
copy() {
    echo "Installing script on git path..."

    local GIT_PATH=$(which git)
    local SUDO_AVAILABLE=$(which sudo 2> /dev/null)
 
    if [ -z $SUDO_AVAILABLE ]
    then 
        cp $SCRIPT_FILE "$GIT_PATH-ts" || die "Failed to copy script!"
		cp $JAR_SRC $JAR_DST || die "Failed to copy jar"
    else
        echo "This operation might require admin access and might ask for your password."
        sudo cp $SCRIPT_FILE "$GIT_PATH-ts" || die "Failed to copy script!"
		sudo cp $JAR_SRC $JAR_DST || die "Failed to copy jar"
    fi

    echo "Script installed successfully at $GIT_PATH-ts."
    echo "You can now use: git ts <command> to call the script from anywhere."
}

# Setup the Git environment
setup() {
    clear

    # Users full name
    echo "What is your full name? Example: John Doe"
    read NAME
    die_if_empty "name" $NAME
    git config --global user.name "$NAME"
    
    # Users email
    echo ""
    echo "What is your e-mail? Example: john.doe@mail.com.au"
    read EMAIL
    die_if_empty "email" $EMAIL
    git config --global user.email $EMAIL

    # Preferred editor
    echo ""
    echo "Which editor would you like to use for Git commit messages? Examples: vi, vim, emacs, nano"
    read EDITOR
    die_if_empty "editor" $EDITOR
    git config --global core.editor $EDITOR

    # Set the color scheme for Git output
    git config --global color.ui auto

    # Set default push to tracking branches
    git config --global push.default tracking

    # Setup git completion
    echo ""
    echo "Installing git completion script..."
    cp $UTILS/git-completion.bash ~/.git-completion.bash
    echo "source ~/.git-completion.bash" >> "$PROFILE"

    # Setup Git branch info in terminal
    echo ""
    echo "Installing git console branch highlighting..."
    cp $UTILS/console_git_branch.bash ~/.console_git_branch.bash
    echo "source ~/.console_git_branch.bash" >> "$PROFILE"

    # Setup ssh-agent if running on msysgit (enabled by default for Mac/Linux)
    SYSTEM=$(uname)
    if [[ "$SYSTEM" == *MINGW* ]]
    then
        curl $FILE_SERVER/ms-ssh.bash -OL
        mv ms-ssh.bash ~/.ms-ssh.bash
        echo "source ~/.ms-ssh.bash" >> "$PROFILE"
        echo "Setting up ssh-agent...you need to restart Git Bash after this!"
    fi

    # Load the new profile
    source "$PROFILE"

    # Copy the script to Git path
    echo ""
    copy

    set_auth_details

    echo ""
    echo "Setup done!"
    echo "You can now use 'git ts <command>'!"

}

die() {
    echo "$1"
    exit 1
}

die_if_empty() {
    if [ -z "$2" ]
    then 
       die "No $1 supplied. Aborting."
    fi
}

continue_or_abort() {
    echo "Do you want to continue (y/n)?"
    read CONTINUE

    if [ "$CONTINUE" != "y" ]
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