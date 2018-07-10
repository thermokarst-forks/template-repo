#!/bin/bash

. ../common/funcs.sh

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
commit_msg=MAINT: Updating GitHub issue templates

# actions
validate_repo "$destination_repo"
prep_dest_dir "$destination_repo" "$local_branch" "$destination_dir"
cp -r ./$issue_templates_dir/* $destination_dir
commit_changes "$destination_dir" "$commit_msg"
push_changes "$destination_dir" "$remote" "$local_branch"
