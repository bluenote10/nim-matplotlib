#!/bin/bash

#file=debug.nim
#file=matplotlib.nim
file=test.nim

fileAbs=`readlink -m $file`
traceback=false

nim c -o:matplotlib --parallelBuild:1 --usecolors $file

compiler_exit=$?

echo "Compiler exit: $compiler_exit"

if [ "$compiler_exit" -eq 0 ]; then  # compile success
  ./matplotlib
  exit $?
fi

if [ "$traceback" = true ] ; then
  echo -e "\nRunning ./koch temp c $fileAbs"
  cd ~/bin/nim-repo
  ./koch temp c `readlink -m $fileAbs`
fi

