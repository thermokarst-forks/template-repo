#!/bin/bash

# This script doesn't work with bare git repos. It also assumes the caller
# has push access to the remote repo.

if [ $# -ne 2 ]
  then
    cat <<EOF
Usage: $0 \$LOCAL_REPO \$REMOTE

\$LOCAL_REPO      path to local repo
\$REMOTE          alias for desired remote to push to (defined in \$LOCAL_REPO)
EOF
exit 0
fi

# args & vars
destination_repo=$1
remote=$2
local_branch="master"
issue_templates_dir=ISSUE_TEMPLATE
destination_dir=$destination_repo/.github/$issue_templates_dir

# check if destination repo is in fact a repo. Also ensure no uncommitted work.
is_git_repo="$(cd $destination_repo && git rev-parse --is-inside-work-tree 2>/dev/null)"
if [ "$is_git_repo" == "" ]; then
    echo "directory provided is not a git repo"
    exit 1
fi

# this could be better, but for now...
has_unstaged_changes="$(cd $destination_repo && git diff-index --quiet HEAD || echo "fail")"
if [ "$has_unstaged_changes" == "fail" ]; then
    echo "unstaged changes in local repo"
    exit 1
fi

# Q2D2 author info
name="q2d2"
email="q2d2.noreply@gmail.com"

cd $destination_repo && \
    git checkout $local_branch --quiet && \
    rm -rf $destination_dir && \
    mkdir -p $destination_dir ; \
    cd -

cp -r ./$issue_templates_dir/* $destination_dir

cd $destination_dir && \
    git add $destination_dir && \
    GIT_AUTHOR_NAME=$name \
    GIT_AUTHOR_EMAIL=$email \
    GIT_COMMITTER_NAME=$name \
    GIT_COMMITTER_EMAIL=$email \
    git commit -m 'MAINT: Updating GitHub issue templates' --quiet ;
    cd -

cd $destination_dir && \
    git push $remote $local_branch --quiet ; \
    cd -
