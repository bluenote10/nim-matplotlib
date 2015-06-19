
import os
import strutils except format
import tables
import sequtils
import stringinterpolation

type
  Plot = object
    script: string


proc addCustomCode*(p: var Plot, code: string) =
  p.script.add(code.unindent)


proc createSinglePlot*(): Plot =
  var p = Plot(script: "")
  p.addCustomCode """
  import matplotlib
  import matplotlib.pyplot as plt
  print "Hello World"

  for i in range(10):
    print i
  """
  p


proc plotInternal*[T](p: var Plot, x: openarray[T], y: openarray[T], format = "-", kwargs: varargs[string]) =
  let xData = "[" & x.mapIt(string, $it).join(", ") & "]"
  let yData = "[" & y.mapIt(string, $it).join(", ") & "]"
  let kwargsJoined = kwargs.join(", ")
  #let code: string = ifmt"plt.plot($xData, $yData, $format, $kwargsJoined)"
  #let code = format("plt.plot(%s, %s, %s, %s)", xData, yData, format, kwargsJoined)
  #p.addCustomCode(code)
  p.addCustomCode("plt.plot(")
  p.addCustomCode(xData & ", ")
  p.addCustomCode(yData & ", ")
  p.addCustomCode("'" & format & "'")
  if kwargsJoined.len > 0:
    p.addCustomCode(", " & kwargsJoined)
  p.addCustomCode(")\n")
  echo xData


proc show*(p: var Plot) =
  p.addCustomCode("plt.show()")


proc run*(p: Plot) =
  var fn = getTempDir() / ".nim-matplotlib.py"
  writeFile(fn, p.script)
  var x = execShellCmd("python \"" & fn & "\"")
  echo "ret = ", x
  


var p = createSinglePlot()
let x = [1,2,3]
let y = [3,1,2]
#p.plotInternal(x, y, "-", "lw=20", "color='#111144'")




when true:
  import macros

  dumpTree:
    plotInternal(p, x, y, "-", "lw=20", "color='#111144'")

  macro plot[T](p: var Plot, x: openarray[float], y: openarray[T], format = "-", va: untyped): stmt {.immediate} =
    result = newCall(bindSym"plotInternal")
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


  var data = [1,2,3]
  p.plot(x, y, "-", lw=10, color="#111144")
  #immediateM(data, keyA="foo", keyB="bar", lw=80)



p.show

echo p.script
#p.run
