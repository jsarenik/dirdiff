#!/bin/sh

a="/$0"; a=${a%/*}; a=${a:-.}; a=${a#/}/; BINDIR=$(cd $a; pwd)
. $BINDIR/include/dirdiff.inc.sh

test "$1" = "-t" && mytest
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
