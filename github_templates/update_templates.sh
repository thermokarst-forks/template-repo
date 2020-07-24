#!/bin/bash

. ../common/funcs.sh

set -e -x

# This script doesn't work with bare git repos. It also assumes the caller
# has push access to the remote repo.

if [ $# -eq 0 ] || [ $# -gt 2 ];
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
templates_dir="templates"
destination_dir="$destination_repo/.github"
commit_msg="MAINT: Updating GitHub templates"

# actions
validate_repo "$destination_repo"
prep_dest "$destination_repo" "$local_branch"
cp -r ./$templates_dir/* $destination_dir
commit_changes "$destination_dir" "$commit_msg"

if [ $remote ]; then
	push_changes "$destination_dir" "$remote" "$local_branch"
fi
