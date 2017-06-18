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
trap "rm -f $TMP" EXIT

BOPT=-D
grep -q Linux /proc/version 2>/dev/null && BOPT=-d

DIRA=${DIRA%/}
DIRB=${DIRB%/}

mydon() {
  dp=${1#$3/}
  dp=${dp#$3}
  dp=${dp%:}
  dp=${dp:+"$dp/"}
  echo $dp$2
}

mydel() {
  test -n "$DD_NAMES" && echo "# mydel $*"
  echo "rm -rfv $1"
}

islink() {
  if
    test -L $1
  then
    TARGET=$(readlink $1)
    echo "ln -nsf $TARGET $2"
  else
    return 1
  fi
}

mydiff() {
  test -n "$DD_NAMES" && echo "# mydiff $*"
  islink $2 ${2#$DIRB/} && return 0
  diff -u $1 $2 >$TMP
  case $? in
    1)
      echo "base64 \$BOPT <<$EOFMARK | patch -Np1"
      cat $TMP | base64
      echo "$EOFMARK"
      ;;
    2) myblob ${2#$DIRB/};;
  esac
}

myblob() {
  test -n "$DD_NAMES" && echo "# myblob $*"
  islink $DIRB/$1 $1 && return 0
  echo "base64 \$BOPT <<$EOFMARK | tar xv"
  tar c -C $DIRB $1 | base64
  echo "$EOFMARK"
}

# Header
#  - use base64 -d on Linux
cat <<EOF
BOPT=-D
grep -q Linux /proc/version && BOPT=-d
EOF

diff -qr $DIRA $DIRB | while read a b c d e
do
  case "$a $b $c" in
    Only\ in\ $DIRA*) mydel $(mydon $c $d $DIRA);;
    Only\ in\ $DIRB*) myblob $(mydon $c $d $DIRB);;
    Files\ *) mydiff $b $d;;
    *) echo unknown line $a $b $c $d $e 1>&2; exit 1;;
  esac
done
