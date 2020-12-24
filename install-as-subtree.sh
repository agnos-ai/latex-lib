#!/usr/bin/env bash
#
# Installs this repo (latex-lib) as a "git subtree" repo into your own
# LaTeX documentation project repo.
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

github_org="agnos-ai"
remote_name="latex-lib"
remote_branch="main"
github_repo="${github_org}/${remote_name}"
github_url_https="https://github.com/${github_repo}.git"
github_url_ssh="git@github.com:${github_repo}.git"
prefer_ssh=1
subtree_dir="${remote_name}" # the directory into which the subtree repo will appear in your repo

function checkGit() {

  if ! command -v git >/dev/null 2>&1 ; then
    echo "ERROR: You don't have git in your PATH" >&2
    return 1
  fi
  if [[ ! -f .git/config ]] ; then
    echo "ERROR: You're not in the root directory of your git repo" >&2
    return 1
  fi
  #
  # TODO: Add more checks, right git version?
  #
  return 0
}

function getRemoteUrl() {

  git remote get-url "${remote_name}" 2>/dev/null
}

function checkGitRemote() {

  local -r remoteUrl="$1"

  [[ "${remoteUrl}" == "${github_url_https}" ]] && return 0
  [[ "${remoteUrl}" == "${github_url_ssh}" ]] && return 0

  return 1
}

function addGitRemote() {

  echo "Add git remote" >&2

  if ((prefer_ssh)) ; then
    git remote add -f "${remote_name}" "${github_url_ssh}"
  else
    git remote add -f "${remote_name}" "${github_url_https}"
  fi
  checkGitRemote "$(getRemoteUrl)"
}

function getSubTrees() {
  git log | grep git-subtree-dir | tr -d ' ' | cut -d ":" -f2 | sort | uniq
}

function addSubtree() {

  if getSubTrees | grep -q "${subtree_dir}" ; then
    echo "Subtree ${subtree_dir} has already been installed" >&2
    return 0
  fi

  echo "Add subtree" >&2

  git subtree add --prefix="${subtree_dir}" --squash "${remote_name}/${remote_branch}"
}

function pullLatest() {

  echo "Pull Latest" >&2

  git fetch latex-lib || return $?
  git subtree pull --prefix "${remote_name}" "${remote_name}" "$remote_branch" --squash
}

function main() {

  checkGit || return $?

  local -r remoteUrl="$(getRemoteUrl)"

  if ! checkGitRemote "${remoteUrl}" ; then
    addGitRemote || return $?
  fi
  addSubtree || return $?
  pullLatest || return $?

  return 0
}

main $@
exit $?
