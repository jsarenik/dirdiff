#!/bin/sh

test $# -eq 2 || {
  cat <<-EOF
	Usage: $0 <directory_old> <directory_new>
	EOF
  exit 1
}

DIRA=$1
DIRB=$2
EOFMARK=EOOOFDIRDIFF
TMP=/tmp/dirdiff.$$
trap "rm $TMP" EXIT

mydon() {
  dp=${1#$3/}
  dp=${dp#$3}
  dp=${dp%:}
  dp=${dp:+"$dp/"}
  echo $dp$2
}

mydel() {
  echo "rm -rfv $1"
}

mydiff() {
  diff -u $1 $2 >$TMP
  case $? in
    1)
      echo "patch -Np1 <<$EOFMARK"
      cat $TMP
      echo "$EOFMARK"
      ;;
    2) myblob ${2#*/};;
  esac
}

myblob() {
  echo "base64 -D <<$EOFMARK | tar xv"
  tar c -C $DIRB $1 | base64
  echo "$EOFMARK"
}

diff -qr $DIRA $DIRB | while read a b c d e
do
  case "$a $b $c" in
    Only\ in\ $DIRA*) mydel $(mydon $c $d $DIRA);;
    Only\ in\ $DIRB*) myblob $(mydon $c $d $DIRB);;
    Files\ *) mydiff $b $d;;
    *) echo unknown line $a $b $c $d $e 1>&2; exit 1;;
  esac
done
