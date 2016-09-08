#!/bin/sh

test $# -ne 2 && {
  cat <<EOF
Usage: $0 <directory_old> <directory_new>
EOF
  exit 1
}

DIRA=$1
DIRB=$2

diff -qr $DIRA $DIRB | while read a b c d e
do
  case $a in
    Only)
      unset dirpart
      if
        echo $c | grep -q /
      then
        dirpart=$(echo $c | tr -d : | cut -d/ -f2-)/
      fi
      if
        echo $c | grep -q $DIRA
      then
        echo "rm -rfv $dirpart$d"
      else
	echo "base64 -D <<EOOOFDIRDIFF | tar xv"
        tar c -C $DIRB $dirpart$d | base64
        echo EOOOFDIRDIFF
      fi
      ;;
    Files) echo 'patch -Np1 <<EOOOFDIRDIFF'
      diff -du $b $d
      echo EOOOFDIRDIFF
      ;;
    *) echo unknown;;
  esac
done
