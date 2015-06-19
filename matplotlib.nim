
import os
import strutils except format
import tables
import sequtils
import stringinterpolation
import macros

import math


type
  Plot = object
    script: string


proc `+=`*(p: var Plot, code: string) =
  ## adds code to the plot script. For convenience
  ## the code is unindented and a trailing newline
  ## is added.
  p.script.add(code.unindent & "\n")

proc addRaw*(p: var Plot, code: string) =
  ## without unident and newline
  p.script.add(code)


proc createSinglePlot*(): Plot =
  result = Plot(script: "")
  result += """
  import matplotlib
  import matplotlib.pyplot as plt
  """


proc plotVA*[T](p: var Plot, x: openarray[T], y: openarray[T], format: string, kwargs: varargs[string]) =
  let xData = "[" & x.mapIt(string, $it).join(", ") & "]"
  let yData = "[" & y.mapIt(string, $it).join(", ") & "]"
  let kwargsJoined = kwargs.join(", ")
  p += ifmt"x = $xData"
  p += ifmt"y = $yData"
  p += ifmt"plt.plot(x, y, '$format', $kwargsJoined)"
  # note: python does not mind about kwargsJoined being ""
  echo xData


#proc plot[T](p: var Plot, x: openarray[float], y: openarray[T], format = "-") =
#  plotVA(p, x, y, format)

macro plot[T](p: var Plot, x: openarray[float], y: openarray[T], format: string): stmt {.immediate.} =
  result = newCall(bindSym"plotVA")
  result.add(p)
  result.add(x)
  result.add(y)
  result.add(format)

macro plot[T](p: var Plot, x: openarray[float], y: openarray[T], format: string, va: untyped): stmt {.immediate.} =
  result = newCall(bindSym"plotVA")
  result.add(p)
  result.add(x)
  result.add(y)
  result.add(format)

  let args = callsite()
  for i in 5..<args.len:
    if args[i].kind == nnkExprEqExpr:
      echo "key=value pair" #, args[i].kind, args[i]
      echo args[i].treerepr
      echo args[i][0].toStrLit.strVal
      echo args[i][1].toStrLit.strVal
      let kwarg = args[i][0].toStrLit.strVal & "=" & args[i][1].toStrLit.strVal
      result.add(newStrLitNode(kwarg))
    else:
      echo "unnamed argument", args[i].kind, args[i]
  #var result = newStmtList()

  echo result.treeRepr



proc show*(p: var Plot) =
  p += "plt.show()"


proc saveFigure*(p: var Plot, fn: string) =
  p += ifmt"plt.savefig('$fn')"


proc saveScript*(p: Plot, fn: string) =
  writeFile(fn, p.script)


proc run*(p: Plot, ignoreError = true) =
  var fn = getTempDir() / ".nim-matplotlib.py"
  writeFile(fn, p.script)
  var ret = execShellCmd("python \"" & fn & "\"")
  if ret != 0 and not ignoreError:
    raise newException(IOError, "failed to run plot script")
  

proc debugPrintScript*(p: Plot) =
  echo "-------------------------"
  echo p.script
  echo "-------------------------"


discard """
template newSeqItXY(N: int, op: expr): expr =
  var xs = newSeq[float](N)
  var ys = newSeq[float](N)
  for it {.inject.} in 0 ..< N:
    let (x,y) = op
    when x is float:
      xs.add(x)
    else:
      xs.add(x.toFloat)
    when y is float:
      xs.add(y)
    else:
      ys.add(y.toFloat)
  (xs, ys)
"""

#let asfd = 1.toFloat

var p = createSinglePlot()

let x = [1,2,3]
let y = [3,1,2]


#let (x,y) = newSeqItXY(10, (it, random(1.0)))

echo x.repr
echo y.repr

#p.plotVAl(x, y, "-", "lw=20", "color='#111144'")

#p.plot(x, y)
p.plot(x, y, "-")
#p.plot(x, y, "-", lw=10, color="#111144")


#p.show
p.saveFigure("test.png")


p.debugPrintScript
p.run
