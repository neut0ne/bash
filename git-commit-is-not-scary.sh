#! /usr/bin/env bash

/*

git status					# check what branch you're at, if there are file changes to commit
git branch					# view existing branches in the current local repo
git checkout master				# switch to master (or confirm that you're already on master)
git checkout -b amend-my-name			# create a new branch with a name you choose
git checkout -b new-branch existing-branch	# create a new branch based on an existing branch - usecase?
git add file-name				# add change to staging area (area for change you want to commit. In Github you commit when you save. In your home directory you can stage several changes in several files and commit all together.)
git commit -m "my message"			# commit staged changes to the branch you're standing on
git push origin amend-my-name			# push branch to master in github
git push					# the next time you push from your branch, you don't have to state origin since the branch already exists in both ends.
git pull 					# 1. Fetches updates from my github fork (origin), and 2. merges them with my local repo
git fetch					# safer option instead of git pull. Fetches updates from origin. Pair with git merge origin/master. 
git merge origin/master				# merge fetched updates to the local masterbranch.
git checkout file-name				# Checks out (abandons) previously-committed version of file. 
git checkout -f amend-my-name			# Force-checkout (abandon) branch (not recommended. Generally, avoid -f since it overrides git warnings. You're gonna invite trouble.)
git push -f					# no no no no no no no no! (will probably ruin all of your colleagues' work day)
git stash					# "stashes away" current changes and lets you continue to work on a clean local repo. Equivalent to git stash push. 
git stash list					# lists stashed changes.
git stash show					# inspect stashed changes
git stash apply					# restore stashed changes
git rebase a-new-branch				# when a branch is behind other commits and there is a merge conflict, you need to rebase to a branch on the front of github master. 

Normal workflow:
git checkout master
git fetch
git merge origin/master
git checkout -b name-of-my-new-branch
{do changes in files and save}
git add file-name
git commit -m "awesome message"
git push origin name-of-my-new-branch
Now there's a merge request in gitlab!

If a lot of people has merged changes to master while you were doing your changes and there are merge conflicts:
{finish changes in file and save}
git rebase try-one-more-time-branch
git add file-name
git commit -m "had to rebase"
git push origin try-one-more-time-branch
Now wait for someone to approve the merge request in gitlab <3

https://dont-be-afraid-to-commit.readthedocs.io/en/latest/git/commandlinegit.html
https://git-scm.com/docs/git-stash
https://git-scm.com/docs/git-rebase

*/
