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
issue_templates_dir=.github/ISSUE_TEMPLATE
destination_dir=$destination_repo/$issue_templates_dir

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

# If renaming templates, we should probably script it out here so that they
# are renamed or removed as appropriate.
# Treat this script as the authoritative manifest.

manifest=(
    1-user-need-help.md
    2-dev-need-help.md
    3-found-bug.md
    4-make-better.md
    5-make-new.md
    6-where-to-go.md
)

mkdir -p $destination_dir

for template in "${manifest[@]}"
do
    cp ./$issue_templates_dir/$template $destination_dir
    cd $destination_dir && git checkout $local_branch && git add $destination_dir/$template ; cd -
done

cd $destination_dir && \
    GIT_AUTHOR_NAME=$name \
    GIT_AUTHOR_EMAIL=$email \
    GIT_COMMITTER_NAME=$name \
    GIT_COMMITTER_EMAIL=$email \
    git commit -m 'MAINT: Updating GitHub issue templates' ;
    cd -

cd $destination_dir && git push $remote $local_branch ; cd -
