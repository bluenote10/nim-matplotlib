
import matplotlib
import sequtils
import math


discard """
proc checkDataAgainstConds(data: seq[seq[float]], conds: seq[Cond]): seq[seq[float]] =
  result = newSeq[seq[float]]()
  for obj in data:
    var okay = true
    for cond in conds:
      let val = obj[cond.dim]
      if not (val > cond.l and val <= cond.h):
        okay = false
    if okay:
      result.add(obj)
"""

proc makeParCoordPlot(N, D: int, fn: string, conds: seq[Cond]) =

  var data = newSeqWith(N, newSeq[float](D))
  for i in 0 ..< N:
    for j in 0 ..< D:
      data[i][j] = random(1.0)

  var p = createSinglePlot()

  p.parallelCoordinates(D, data, conds)

  #let dataCond = checkDataAgainstConds(data, conds)
  #p.parallelCoordinates(D, dataCond, "#EE2211")

  p.enableGrid()
  #p.show
  #p.saveFigure("parCoord.svg", bbox_inches := "tight")
  p.saveFigure(fn)

  #p.debugPrintScript
  p.run

randomize(1)



makeParCoordPlot(500, 2, "parCoord_2D.svg", @[(0, 0.1, 0.15)])


# 5D -- 10% requires 56% selection
when false:
  makeParCoordPlot(500, 5, @[(0, 0.02, 0.58),
                             (1, 0.20, 0.78),
                             (2, 0.09, 0.65),
                             (4, 0.40, 0.96)])

# 5D -- 1% requires 31.6% selection, would required N=10000 to look good
when false:
  makeParCoordPlot(500, 5, @[(0, 0.02, 0.33),
                             (1, 0.20, 0.53),
                             (2, 0.09, 0.40),
                             (4, 0.40, 0.71)])

# 4D -- 5% requires 36.8% selection
makeParCoordPlot(500, 4, "parCoord_4D.svg", @[
  (0, 0.02, 0.39),
  (1, 0.60, 0.97),
  (3, 0.22, 0.59)])
