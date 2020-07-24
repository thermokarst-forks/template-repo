#!/bin/bash

is_dir_a_repo() {
    is_git_repo="$(cd $1 && git rev-parse --is-inside-work-tree 2>/dev/null)"
    if [ "$is_git_repo" == "" ]; then
        echo "directory $1 is not a git repo"
        exit 1
    fi
}

uncommitted_changes_in_repo() {
    has_unstaged_changes="$(cd $1 && git diff-index --quiet HEAD || echo "fail")"
    if [ "$has_unstaged_changes" == "fail" ]; then
        echo "unstaged changes in directory $1"
        exit 1
    fi
}

validate_repo() {
    is_dir_a_repo "$1"
    uncommitted_changes_in_repo "$1"
}

prep_dest() {
    cd $1 && \
        git checkout $2 --quiet && \
        cd - > /dev/null
}

commit_changes() {
    cd $1
    if [[ `git status --porcelain` ]]; then
        git add $1 && \
           GIT_AUTHOR_NAME="q2d2" \
           GIT_AUTHOR_EMAIL="q2d2.noreply@gmail.com" \
           GIT_COMMITTER_NAME="q2d2" \
           GIT_COMMITTER_EMAIL="q2d2.noreply@gmail.com" \
           git commit -m "$2" --quiet
    else
        echo "No changes"
    fi
    cd -
}

push_changes() {
    cd $1 && git push $2 $3 --quiet ; cd - > /dev/null
}
