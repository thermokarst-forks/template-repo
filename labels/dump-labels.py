#!/usr/bin/env python

import os
import sys
import getpass
import collections

import yaml
import github

yaml.add_representer(collections.OrderedDict, lambda dumper, data:
                     dumper.represent_dict(data.items()))


def main(repo, auth, filepath):
    gh = github.Github(**auth)
    repo = gh.get_repo(repo_name)

    labels = []
    for label in repo.get_labels():
        labels.append(collections.OrderedDict([
            ('name', label.name),
            ('color', label.color),
            # description lookup is broken on Github API
            # https://github.com/PyGithub/PyGithub/pull/738
            ('description', '')
        ]))

    with open(filepath, 'w') as fh:
        entries = [yaml.dump([label], default_flow_style=False, indent=2)
                   for label in labels]
        fh.write('\n'.join(entries))


def get_user_pass():
    print("Please enter your Github username/password to make these changes.")
    print("(Or set GH_TOKEN to skip this.)")
    user = input('Username: ')
    password = getpass.getpass()
    return user, password


if __name__ == '__main__':
    repo_name = sys.argv[1]
    filepath = sys.argv[2]

    token = os.environ.get('GH_TOKEN')
    if token is None:
        user, password = get_user_pass()
        auth = { 'login_or_token': user, 'password': password }
    else:
        auth = { 'login_or_token': token }

    main(repo_name, auth, filepath)
