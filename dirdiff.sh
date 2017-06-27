#!/bin/sh

test $# -eq 2 || {
  cat <<-EOF
	Usage: $0 <directory_old> <directory_new>
	EOF
  exit 1
}

# Export DD_ALLBLOB=1 in order to get all blob no diff
# Export DD_NAMES=1 in order to print all file names
DIRA=$1
DIRB=$2
EOFMARK=EOOOFDIRDIFF
TMP=/tmp/dirdiff.$$
trap "rm -f $TMP" EXIT

BOPT=-D
grep -q Linux /proc/version 2>/dev/null && BOPT=-d

DIRA=${DIRA%/}
DIRB=${DIRB%/}

# mydon loop/bin: dbclient loop
# bin:
# bin:
# bin
# bin/
# bin/dbclient

# mydon loop: version loop
# loop:
# :
# 
# 
# version

mydon() {
  A=$3/
  dp=${1#$A}
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

istext() {
  test -n "$DD_ALLBLOB" && return 1
  for f in $*
  do
    M1=$(strings $f | md5sum | cut -b-32)
    M2=$(md5sum $f | cut -b-32)
    test "$M1" = "$M2" || return 1
  done
}

mydiff() {
  test -n "$DD_NAMES" && echo "# mydiff $*"
  islink $2 ${2#$DIRB/} && return 0
  if
    istext $1 $2
  then
    echo "base64 \$BOPT <<$EOFMARK | patch -Np1"
    diff --no-dereference -u $1 $2 >$TMP
    cat $TMP | base64
    echo "$EOFMARK"
  else
    myblob ${2#$DIRB/}
  fi
}

myblob() {
  test -n "$DD_NAMES" && echo "# myblob $*"
  islink $DIRB/$1 $1 && return 0
  if
    test -d $DIRA/$1 -o -d $DIRB/$1
  then
    echo "base64 \$BOPT <<$EOFMARK | tar xv"
    tar c --numeric-owner -C $DIRB $1 | base64
  else
    echo "base64 \$BOPT <<$EOFMARK >$1"
    cat $DIRB/$1 | base64
  fi
  echo "$EOFMARK"
}

# Header
#  - use base64 -d on Linux
header() {
  cat <<-EOF
	BOPT=-D
	grep -q Linux /proc/version && BOPT=-d
	EOF
}

diff --no-dereference -qr $DIRA $DIRB | while read a b c d e
do
  test -z "$H" && { header; H=1; }
  echo "# $a $b $c $d $e"
  case "$a $b $c" in
    Only\ in\ $DIRA*) mydel $(mydon $c $d $DIRA);;
    Only\ in\ $DIRB*) myblob $(mydon $c $d $DIRB);;
    Files\ *) mydiff $b $d;;
    Symbolic\ *) mydiff $c $e;;
    *) echo unknown line $a $b $c $d $e 1>&2; exit 1;;
  esac
done | grep .
