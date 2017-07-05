#!/bin/sh

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
    echo $1 | grep -q '/' && echo "mkdir -p ${1%/*}"
    echo "base64 \$BOPT <<$EOFMARK >$1"
    cat $DIRB/$1 | base64
  fi
  echo "$EOFMARK"
  ACCESS=$(busybox stat -c "%a" $DIRB/$1)
  echo "chmod $ACCESS $1"
}

prok() {
    echo "OK: $1 == $2"
}

prfa() {
    echo "FAILED: $1 != $2"
}

expectit() {
  func=$1
  A=$($func $3)
  RET=$?
  if
    test "$A" = "$4"
    test $RET = $2
  then
    prok "$func $3" "$4"
  else
    prfa "$func $3" "$A"
  fi
}

mytest() {
  expectit mydon 0 "loop/bin: dbclient loop" bin/dbclient
  expectit mydon 0 "loop: version loop" "version"
  expectit mydel 0 "ahoj" "rm -rfv ahoj"
  expectit islink 0 "$BINDIR/tests/types/a/symlink my-link" "ln -nsf .. my-link"
  expectit islink 1 "$BINDIR/tests/types/a/text my-link" ""
  expectit istext 0 "$BINDIR/tests/types/a/text"
  expectit istext 1 "$BINDIR/tests/types/a/random"
  exit
}
