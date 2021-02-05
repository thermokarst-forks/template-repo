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
local_branch="master"
commit_msg="MAINT: Updating copyright year"

# actions
validate_repo "$1"
prep_dest "$1" "$local_branch"
cd $1
q2lint --update-copyright-year
cd -
commit_changes "$1" "$commit_msg"

if [ $remote ]; then
	push_changes "$1" "$2" "$local_branch"
fi
