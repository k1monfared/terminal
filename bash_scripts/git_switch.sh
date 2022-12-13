#!/bin/bash

account=$1
if [ $account = "l2l" ]
then
    git config user.email "langroudlangford@users.noreply.github.com"
    git config user.name  "l2l"
elif [ $account = "k1monfared" ]
then
    git config user.email "k1monfared@users.noreply.github.com"
    git config user.name  "Keivan"
elif [ $account = "photo" ]
then
    git config user.email "k1monfaredphoto@users.noreply.github.com"
    git config user.name  "Keivan"
else
    echo "The account $1 does not exist!"
fi
