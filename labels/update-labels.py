#!/usr/bin/env python

import os
import sys
import json
import getpass
import collections

import yaml
import github

WHITE = 'ffffff'
UPDATED = 'updated'
SKIPPED = 'skipped'
CREATED = 'created'
Template = collections.namedtuple(
    'Template', ['name', 'color', 'description', 'old'])


def get_expected_labels():
    with open('labels.yaml', 'r') as fh:
        return [Template(name=kwargs['name'],
                         color=kwargs['color'],
                         description=kwargs.get('description', ''),
                         old=set(kwargs.get('old', [])))
                for kwargs in yaml.load(fh)]


def sync_label(target, template):
    added = {}
    removed = {}
    target_description = target.description or ''
    if target.name != template.name:
        removed['name'] = target.name
        added['name'] = template.name
    if target.color != template.color:
        removed['color'] = target.color
        added['color'] = template.color
    if target_description != template.description:
        removed['description'] = target_description
        added['description'] = template.description

    if added:
        target.edit(template.name, template.color, template.description)
        return changes(target.name, UPDATED, removed, added)
    else:
        return changes(target.name, SKIPPED, {}, {})


def color_label(target, color):
    current_color = target.color
    description = target.description or ''
    if current_color != color:
        target.edit(target.name, color, description)
        return changes(target.name, UPDATED,
                       {'color': current_color}, {'color': color})
    return changes(target.name, SKIPPED, {}, {})


def create_label(repo, template):
    repo.create_label(template.name, template.color, template.description)
    return changes(template.name, CREATED, {},
                   {'name': template.name,
                    'color': template.color,
                    'description': template.description})


def changes(name, status, removed, added):
    c = collections.OrderedDict()
    c['name'] = name
    c['status'] = status
    c['removed'] = collections.OrderedDict(sorted(removed.items()))
    c['added'] = collections.OrderedDict(sorted(added.items()))
    return c


def find_match(label, to_search):
    remaining = []
    iterator = iter(to_search)
    for possible in iterator:
        if label.name == possible.name or label.name in possible.old:
            return possible, remaining + list(iterator)
        else:
            remaining.append(possible)

    return None, remaining


def main(repo_name, auth):
    gh = github.Github(**auth)
    repo = gh.get_repo(repo_name)
    changes_made = []
    remaining_labels = get_expected_labels()

    for exist_label in repo.get_labels():
        matched_label, remaining_labels = find_match(exist_label,
                                                     remaining_labels)
        if matched_label is not None:
            yield sync_label(exist_label, matched_label)
        else:
            yield color_label(exist_label, color=WHITE)

    for exp_label in remaining_labels:
        yield create_label(repo, exp_label)


def get_user_pass():
    print("Please enter your Github username/password to make these changes.")
    print("(Or set GH_TOKEN to skip this.)")
    user = input('Username: ')
    password = getpass.getpass()
    return user, password


def print_change(change):
    status = change['status']
    formatted = json.dumps(change)

    if status == UPDATED or status == CREATED:
        text = colorize(formatted, 'yellow')
    elif status == SKIPPED:
        text = colorize(formatted, 'green')
    else:
        text = colorize(formatted, 'red')

    print(text)


def colorize(text, color):
    prefix = {
        'red': '\033[91m',
        'yellow': '\033[93m',
        'green': '\033[92m'
    }[color]
    return ''.join([prefix, text, '\033[0m'])


if __name__ == '__main__':
    repo_name = sys.argv[1]

    token = os.environ.get('GH_TOKEN')
    if token is None:
        user, password = get_user_pass()
        auth = { 'login_or_token': user, 'password': password }
    else:
        auth = { 'login_or_token': token }

    for change in main(repo_name, auth):
        print_change(change)
