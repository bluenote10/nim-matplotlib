
import matplotlib
import sequtils
import math
import random


proc makeParCoordPlot(N, D: int, fn: string, conds: seq[Cond]) =

  var data = newSeqWith(N, newSeq[float](D))
  for i in 0 ..< N:
    for j in 0 ..< D:
      data[i][j] = rand(1.0)

  var p = createSinglePlot()

  p.parallelCoordinates(D, data, conds)
  p.enableGrid()
  p.saveFigure(fn)
  p.run()

when isMainModule:
  randomize(1)
  makeParCoordPlot(500, 2, "imgs/parCoord_2D.svg", @[(0, 0.1, 0.15)])

  # 4D -- 5% requires 36.8% selection
  makeParCoordPlot(
    500, 4, "imgs/parCoord_4D.svg",
    @[
      (0, 0.02, 0.39),
      (1, 0.60, 0.97),
      (3, 0.22, 0.59)
    ]
  )
