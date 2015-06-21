
import os
import strutils except format
import tables
import sequtils
import stringinterpolation
import macros

import math

type
  SeriesXY* = object
    dataXY*: seq[tuple[x, y: float]]

proc newSeriesXY*(): SeriesXY =
  result = SeriesXY(dataXY: newSeq[tuple[x, y: float]]())

proc `+=`*[T](s: var SeriesXY, xy: tuple[x, y: T]) =
  #when T is float:
  #  s.dataXY.add((xy.x, xy.y))
  #else:
  s.dataXY.add((xy.x.float, xy.y.float))


proc dataX*(s: SeriesXY): seq[float] =
  result = newSeq[float](s.dataXY.len)
  for i in 0 ..< s.dataXY.len:
    result[i] = s.dataXY[i].x

proc dataY*(s: SeriesXY): seq[float] =
  result = newSeq[float](s.dataXY.len)
  for i in 0 ..< s.dataXY.len:
    result[i] = s.dataXY[i].y


type
  Plot* = object
    script: string

  Axis* = enum
    xAxis, yAxis, zAxis

  Axes* = enum
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

  # print matplotlib.rcParams
  # print [f.name for f in matplotlib.font_manager.fontManager.ttflist]

  matplotlib.rcParams['font.family'] = 'Ubuntu'
  matplotlib.rcParams['font.size'] = 14

  better_black = '#444444'
  # affects the figure frame
  matplotlib.rcParams['axes.edgecolor'] = better_black

  # no longer needed since tick_params sets both tick and ticklabel color
  matplotlib.rcParams['xtick.color'] = better_black
  matplotlib.rcParams['ytick.color'] = better_black

  # from palettable.colorbrewer.qualitative import Set1_9
  matplotlib.rcParams['axes.color_cycle'] = ['#E41A1C',
                                             '#377EB8',
                                             '#4DAF4A',
                                             '#984EA3',
                                             '#FF7F00',
                                             '#FFFF33',
                                             '#A65628',
                                             '#F781BF',
                                             '#999999']
  # improve grid
  matplotlib.rcParams['grid.color'] = '#999999'

  import matplotlib.pyplot as plt
  
  # the convention is to have 'fig' and 'ax'
  # refer to the current figure and axes element.

  fig = plt.figure()

  ax = fig.add_subplot(111)
  # axis labels
  ax.xaxis.label.set_color(better_black)
  ax.yaxis.label.set_color(better_black)
  
  # this sets the color of both ticks and ticklabels
  ax.tick_params(axis='x', colors=better_black)

  # better padding to avoid x/y tick label overlap
  ax.tick_params(axis='x', pad=10)
  ax.tick_params(axis='y', pad=10)

  """


proc plot*[T](p: var Plot, x: openarray[T], y: openarray[T], format: string, kwargs: varargs[string]) =
  let xData = "[" & x.mapIt(string, $it).join(", ") & "]"
  let yData = "[" & y.mapIt(string, $it).join(", ") & "]"
  let kwargsJoined = kwargs.join(", ")
  p += ifmt"x = $xData"
  p += ifmt"y = $yData"
  p += ifmt"plt.plot(x, y, '$format', $kwargsJoined)"
  # note: python does not mind about kwargsJoined being ""


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
  when T is string:
    "'" & $x & "'"
  elif T is bool:
    if x:
      "True"
    else:
      "False"
  else:
    $x

macro `:=`*(k: untyped, v: typed): expr = # {.immediate.} =
  let value = newCall(bindSym"customToString", v)
  let right = newCall(bindSym"&", newStrLitNode("="), value)
  result    = newCall(bindSym"&", k.toStrLit, right)
  #echo result.treerepr
  


proc hist*[T](p: var Plot, data: openarray[T], kwargs: varargs[string]) =
  # TODO: hist apparently don't use the color cycle.
  # What we could do is to use a variable which stores the cycled color,
  # and manually cycle like here http://stackoverflow.com/a/3593695/1804173
  # But, requires to check if there is a "color" kwargs, repeated
  # kwargs produce an error.
  let data = "[" & data.mapIt(string, $it).join(", ") & "]"
  let kwargsJoined = kwargs.join(", ")
  p += ifmt"data = $data"
  p += ifmt"plt.hist(data, $kwargsJoined)"



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


proc setAxisLimits*(p: var Plot, axis: Axis, minVal, maxVal: float) =
  p += ifmt"""
  ax.set_${axis.letter}lim([$minVal, $maxVal])
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

proc enableGrid*(p: var Plot) =
  # TODO: implement grids only for a specified axis
  # possible via ax.xaxis.grid()
  p += ifmt"""
  ax.grid()
  ax.set_axisbelow(True) # to draw grid below plots
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



when isMainModule:
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
