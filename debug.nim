
import macros

# commenting either of these => it compiles
import stringinterpolation
import sequtils
import math

type
  MyObject = object

# commenting this proc => it compiles
proc needed*[T](o: var MyObject) =
  discard


# this is the macro I'm actually calling
macro call[T](o: var MyObject): stmt = #{.immediate.} =
  result = newStmtList()

# commenting this => it compiles
macro call[T](o: var MyObject, va: untyped): stmt = # {.immediate.} =
  result = newStmtList()


# commenting this => it compiles
let asfd = 1.toFloat

# and even these two are required to make it fail
let x = [1,2,3]
let y = [1,2,3]

# now the actual code
var o = MyObject()
o.call()

