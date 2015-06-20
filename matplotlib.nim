
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

  Axis = enum
    xAxis, yAxis, zAxis

  Axes = enum
    axesX, axesY, axesZ,
    axesXY, axesXZ, axesYZ,
    axesXYZ

  None = object


proc `$`(n: typedesc[None]): string = "None"





proc letter(axis: Axis): string =
  case axis
  of xAxis: "x"
  of yAxis: "y"
  of zAxis: "z"

iterator items(axes: Axes): Axis =
  case axes:
  of axesX: yield xAxis
  of axesY: yield yAxis
  of axesZ: yield zAxis
  of axesXY: yield xAxis; yield yAxis
  else:
    discard



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

  matplotlib.rc('font', family='sans-serif') 
  matplotlib.rc('font', serif='Ubuntu') 
  matplotlib.rc('text', usetex='false') 
  matplotlib.rcParams.update({'font.size': 22})

  # the convention is to have 'fig' and 'ax'
  # refer to the current figure and axes element.

  fig = plt.figure()

  ax = fig.add_subplot(111)
  """


proc plot*[T](p: var Plot, x: openarray[T], y: openarray[T], format: string, kwargs: varargs[string]) =
  let xData = "[" & x.mapIt(string, $it).join(", ") & "]"
  let yData = "[" & y.mapIt(string, $it).join(", ") & "]"
  let kwargsJoined = kwargs.join(", ")
  p += ifmt"x = $xData"
  p += ifmt"y = $yData"
  p += ifmt"plt.plot(x, y, '$format', $kwargsJoined)"
  # note: python does not mind about kwargsJoined being ""
  echo xData


when false:
  macro plot[T](p: var Plot, x: openarray[T], y: openarray[T], format: string): stmt = #{.immediate.} =
    result = newCall(bindSym"plotVA")
    result.add(p)
    result.add(x)
    result.add(y)
    result.add(format)

  macro plot[T](p: var Plot, x: openarray[T], y: openarray[T], format: string, va: typed): stmt {.immediate.} =
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
        #let value = parseExpr(args[i][1].toStrLit.strVal)
        #echo "value: ", value.treerepr
        let kwarg = args[i][0].toStrLit.strVal & "=" & args[i][1].toStrLit.strVal
        result.add(newStrLitNode(kwarg))
      else:
        echo "unnamed argument", args[i].kind, args[i]
    #var result = newStmtList()

    echo result.treeRepr


discard """
template `->`(k: untyped, v: typed): expr {.immediate.} =
  echo k.repr
  let key = "test" #k #.toStrLit.strVal
  let value = $v
  format("%s = %s", key, value)
"""

proc customToString*[T](x: T): string =
  if T is string:
    "'" & $x & "'"
  else:
    $x

macro `:=`*(k: untyped, v: typed): expr = # {.immediate.} =
  let value = newCall(bindSym"customToString", v)
  let right = newCall(bindSym"&", newStrLitNode("="), value)
  result    = newCall(bindSym"&", k.toStrLit, right)
  #echo result.treerepr
  

dumptree:
  key & "=" & value


# http://stackoverflow.com/a/14971193/1804173
proc setFontSizeAxisLabel*(p: var Plot, axes: Axes, size: int) =
  for axis in axes:
    p += ifmt"""
    ax.${axis.letter}axis.label.set_fontsize($size)
    """

proc setFontSizeTitle*(p: var Plot, size: int) =
  p += ifmt"""
  ax.title.set_fontsize($size)
  """

proc setFontSizeTickLabel*(p: var Plot, axes: Axes, size: int) =
  for axis in axes:
    p += ifmt"""
    for tick in ax.${axis.letter}axis.get_major_ticks():
      tick.label.set_fontsize($size)
    """

proc setAxisLabel*(p: var Plot, axis: Axis, label: string) =
  p += ifmt"""
  ax.set_${axis.letter}label('$label')
  """
  # alternative is plt.${axis.letter}label('$label')

proc setTitle*(p: var Plot, title: string) =
  p += ifmt"""
  ax.set_title('$title')
  """


proc show*(p: var Plot) =
  p += "plt.show()"


proc saveFigure*(p: var Plot, fn: string, kwargs: varargs[string]) =
  let kwargsJoined = kwargs.join(", ")
  p += ifmt"plt.savefig('$fn', $kwargsJoined)"


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
      ys.add(y)
    else:
      ys.add(y.toFloat)
  (xs, ys)

var p = createSinglePlot()


let x = [1,2,3]
let y = [3,1,2]

block:
  var lastY = 0.0
  let (x,y) = newSeqItXY(100, (it, (let y = lastY + random(1.0) - 0.5; lastY = y; y)))
  let lw = 2
  p.plot(x, y, "o-", lw:=lw*2, color:="#111144")

block:
  let (x,y) = newSeqItXY(100, (it, random(1.0)))
  p.plot(x, y, "o-", "lw=2", "color='#881111'")


p.setAxisLabel(xAxis, "x")
p.setAxisLabel(yAxis, "y")
p.setTitle("Test")

p.setFontSizeTickLabel(axesXY, 30)
p.setFontSizeAxisLabel(axesXY, 30)
p.setFontSizeTitle(50)

#p.plot(x, y)
#p.plot(x, y, "-")
#let lw=20
#p.plot(x, y, "-", lw=lw)
#p.plot(x, y, "-", lw=10, color="#111144")


#p.show
p.saveFigure("test.svg", bbox_inches := "tight")


p.debugPrintScript
p.run
