#!/bin/bash

backup(){
	echo Backing up user information to $1...
	cp /etc/passwd /etc/shadow /etc/group $1 2>tmp
  if [ -s "tmp" ]
  then
    echo Error backing up files to $1!
  else
	  echo Successfully backed up files to $1!
  fi
  rm tmp
}

restore(){
	users=(`cat "$1/passwd" | cut -d: -f1`)
	echo Select user to restore:
	for user in  ${users[@]}; do echo "[$((i++))] $user"; done
	read option
	selected=${users[$option]}
	guid=`cat "$1/passwd" | grep $selected | cut -d: -f4`
	olduid=`cat "$1/passwd" | grep $selected | cut -d: -f3`
	lastuid=`tail -1 "/etc/passwd" | cut -d: -f3`
	if [ $olduid > $lastuid  ]
	then
		lastuid=$olduid
	fi
	lastuid=$((lastuid + 1))
	guids=(`cat "$1/group" | grep $selected | cut -d: -f3`)
	groups=(`cat "$1/group" | grep $selected | cut -d: -f1`)
	if [ `grep $selected /etc/shadow | wc -c` == 0 ]
	then
		grep $selected $1/shadow >> /etc/shadow
	fi
	i=0
	for group in ${guids[@]}; do groupadd -g $group ${groups[$((i++))]}; done
	if ((`grep $selected /etc/passwd | wc -c` != 0))
	then
		echo Creating old user...
		useradd -m -g $guid -u $olduid $selected
	else
		echo Creating new user...
		useradd -m -g $guid -u $lastuid $selected
	fi
	for group in ${guids[@]}; do usermod -aG $group $selected; done
}

case $1 in
  --help)
	  echo "Usage: $0 [Option] [Directory]
    Options:
      --backup: Backup user information to specified directory
      --restore: Restores user information from backup
      --help: Show this"
    ;;
  --backup)
    backup $2
    ;;
  --restore)
    restore $2
    ;;
  *)
    echo "Unrecognized option '$1'"
    echo "Try '$0 --help' for more information"
    ;;
esac
