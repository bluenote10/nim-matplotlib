
import stattest
import slicing
import matplotlib
import math
import stringinterpolation

randomize()



proc createPlotFromMarginal(N: int): SeriesXY =
  result = newSeriesXY()
  result += (0,0)
  var cdf = 0.0
  
  for i in 0 ..< N:
    cdf = (i+1).float / N.float
    result += (cdf, cdf)


proc createPlotFromSelection(selection: IndexSelection): SeriesXY =
  let N = selection.getN
  let M = selection.getM
  result = newSeriesXY()
  result += (0,0)
  var cdf = 0.0

  for i in 0 ..< N:
    if selection[i] == true:
      cdf += 1.0 / M.float
    let x = (i+1).float / N.float
    result += (x, cdf)



proc computeDeviationFromSelfSelection(selection: IndexSelection): float =
  ## This function is used internally for the calibration of the KS test.
  ## It does almost the same as the final `computeDeviation` function,
  ## but does not operate on actual data. Instead is considers cases
  ## of "self selection", which only depend on N and M (obtained from the selection)
  ## and not on the data.
  var cumulatedDistOrig = 0.0
  var cumulatedDistTest = 0.0
  var maxDiscrepancy = -Inf

  let N = selection.len
  let M = selection.getM

  for i in 0 ..< N:

    cumulatedDistOrig = (i+1).float / N.float

    if selection[i] == true:
      cumulatedDistTest += 1.0 / M.float

    maxDiscrepancy = max(maxDiscrepancy, abs(cumulatedDistTest - cumulatedDistOrig))

  return maxDiscrepancy


proc createMinDeviationSample(N: int, M: int, iterations: int): seq[float] =
  ## min deviation == case of fully independent selection
  result = newSeq[float](iterations)
  var selection = newIndexSelection(N)
  for iter in 0 ..< iterations:
    selection.selectRandomly(M)
    let dev = computeDeviationFromSelfSelection(selection)
    result[iter] = dev


when isMainModule:

  if true:
    var p = createSinglePlot()

    let N = 1000
    let M = 100
    let iterations = 100

    for iter in 1 .. iterations:
      var selection = newIndexSelection(N)
      selection.selectRandomly(M)
      let plotSel = createPlotFromSelection(selection)
      p.plot(plotSel.dataX, plotSel.dataY, "-", alpha:=0.5) # color:="#666699"

    let plotMar = createPlotFromMarginal(N)
    p.plot(plotMar.dataX, plotMar.dataY, "-", color:="#444444", lw:=2, alpha:=0.8)
    
    #p.setAxisLabel(xAxis, "x")
    p.setAxisLabel(yAxis, "cdf")

    p.setAxisLimits(xAxis, 0, 1)
    p.setAxisLimits(yAxis, 0, 1)

    #p.setFontSizeTickLabel(axesXY, 20)
    p.setFontSizeAxisLabel(axesXY, 20)

    p.enableGrid()
    #p.show
    p.saveFigure(["random.svg", "random.pdf"], bbox_inches := "tight")

    #p.debugPrintScript
    p.run

  if true:
    var p = createSinglePlot()

    let N = 1000
    let M = 100
    let iterations = 10000

    let sample = createMinDeviationSample(N, M, iterations)
    echo sample.mean

    p.hist(sample, color:="#DDDDEE", edgecolor:="#666666", bins:=30, alpha:=0.7)

    p.setAxisLabel(xAxis, "Max Deviation")
    p.setFontSizeAxisLabel(axesXY, 20)

    p.enableGrid()

    #p.debugPrintScript
    p.saveFigure(["randomHist.svg", "randomHist.pdf"], bbox_inches:="tight")
    p.run

  if true:

    let N = 20
    let M = 4

    var selection = newIndexSelection(N)

    for offset in [0,1,2]:
      var p = createSinglePlot()
      selection.selectBlock(M, offset)
      let plotSel = createPlotFromSelection(selection)
      p.plot(plotSel.dataX, plotSel.dataY, "o-", alpha:=0.5) # color:="#666699"
    
      let plotMar = createPlotFromMarginal(N)
      p.plot(plotMar.dataX, plotMar.dataY, "-", color:="#444444", lw:=2, alpha:=0.8)

      #p.setAxisLabel(xAxis, "x")
      p.setAxisLabel(yAxis, "cdf")

      p.setAxisLimits(xAxis, 0, 1)
      p.setAxisLimits(yAxis, 0, 1)

      #p.setFontSizeTickLabel(axesXY, 20)
      p.setFontSizeAxisLabel(axesXY, 20)

      p.enableGrid()
      #p.show
      p.saveFigure([ifmt"block_$offset.svg", ifmt"block_$offset.pdf"], bbox_inches := "tight")

      #p.debugPrintScript
      p.run

  if true:

    let N = 150
    let M = 8

    var selection = newIndexSelection(N)
    let maxOffset = N-M

    var p = createSinglePlot()

    for offset in [0, maxOffset div 2, maxOffset]:
      selection.selectBlock(M, offset)
      let plotSel = createPlotFromSelection(selection)
      p.plot(plotSel.dataX, plotSel.dataY, "o-", alpha:=0.5, ms:=3) # color:="#666699"
    
    let plotMar = createPlotFromMarginal(N)
    p.plot(plotMar.dataX, plotMar.dataY, "-", color:="#444444", lw:=2, alpha:=0.8)

    #p.setAxisLabel(xAxis, "x")
    p.setAxisLabel(yAxis, "cdf")

    p.setAxisLimits(xAxis, 0, 1)
    p.setAxisLimits(yAxis, 0, 1)

    #p.setFontSizeTickLabel(axesXY, 20)
    p.setFontSizeAxisLabel(axesXY, 20)

    p.enableGrid()
    #p.show
    p.saveFigure(["block_dirac.svg", "block_dirac.pdf"], bbox_inches := "tight")

    #p.debugPrintScript
    p.run


