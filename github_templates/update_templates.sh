#!/bin/bash

. ../common/funcs.sh

set -e -x

# This script doesn't work with bare git repos. It also assumes the caller
# has push access to the remote repo.

if [ $# -eq 0 ] || [ $# -gt 4 ];
  then
    cat <<EOF
Usage: $0 \$LOCAL_REPO \$PACKAGE_NAME \$ADDITIONAL_TESTS \$REMOTE

\$LOCAL_REPO          path to local repo
\$PACKAGE_NAME        name to assign to conda package
\$ADDITIONAL_TESTS    additional tests to pass to ci.yml
\$REMOTE              alias for desired remote to push to (defined in \$LOCAL_REPO)
EOF
exit 0
fi

# args & vars
destination_repo=$1
package_name=$2
additional_tests=$3
remote=$4
local_branch="master"
templates_dir="templates"
destination_dir="$destination_repo/.github"
commit_msg="MAINT: Updating GitHub templates"

# actions
validate_repo "$destination_repo"
prep_dest "$destination_repo" "$local_branch" "$destination_dir"
cp -r ./$templates_dir/* $destination_dir
if [ $package_name ]; then
  workflows_dir="$destination_dir/workflows"
  mkdir $workflows_dir
  sed -e "s;%PACKAGE_NAME%;$package_name;g" \
      -e "s;%ADDITIONAL_TESTS%;$additional_tests;g" \
      ./ci.yml.tmpl \
      > "$workflows_dir/ci.yml"
fi

commit_changes "$destination_dir" "$commit_msg"

if [ $remote ]; then
  push_changes "$destination_dir" "$remote" "$local_branch"
fi
