#!/bin/bash

# Account email addresses are kept out of this public repo. Define them in a
# git-ignored file sourced from your shell rc (bashrc.private):
#   GIT_EMAIL_L2L, GIT_EMAIL_K1MONFARED, GIT_EMAIL_PHOTO

account=$1

case "$account" in
    l2l)        name="l2l";    email_var="GIT_EMAIL_L2L" ;;
    k1monfared) name="Keivan"; email_var="GIT_EMAIL_K1MONFARED" ;;
    photo)      name="Keivan"; email_var="GIT_EMAIL_PHOTO" ;;
    *)
        echo "The account $1 does not exist!"
        exit 1
        ;;
esac

eval "email=\${$email_var:-}"
if [ -z "$email" ]; then
    echo "Set $email_var (see bashrc.private) before using git_switch." >&2
    exit 1
fi

git config user.email "$email"
git config user.name "$name"
