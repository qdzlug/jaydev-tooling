#!/bin/bash


if [ "$1" == '' ]; then
	BADGENAME=$(hostname | awk -F\. '{print $1}')
else
	BADGENAME=$1
fi

printf "\e]1337;SetBadgeFormat=%s\a" \
  $(echo -n "$BADGENAME" | base64)
