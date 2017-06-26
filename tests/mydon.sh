#!/bin/bash

mydon() {
  A=$3/
  dp=${1#$A}
  echo $dp
  dp=${1#$3}
  echo $dp
  dp=${dp%:}
  echo $dp
  dp=${dp:+"$dp/"}
  echo $dp
  echo $dp$2
}
