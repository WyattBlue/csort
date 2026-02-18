import std/[algorithm, random, strformat]
import csort

randomize(42)

var passed = 0
var failed = 0

proc check(name: string, ok: bool) =
  if ok:
    passed += 1
  else:
    failed += 1
    echo &"  FAIL: {name}"

# -- int32 tests --
echo "=== int32 ==="

block: # empty
  var a: seq[int32]
  csort.sort(a)
  check("empty", a.len == 0)

block: # single element
  var a = @[1'i32]
  csort.sort(a)
  check("single", a == @[1'i32])

block: # two elements
  var a = @[2'i32, 1]
  csort.sort(a)
  check("two", a == @[1'i32, 2])

block: # already sorted
  var a = @[1'i32, 2, 3, 4, 5]
  csort.sort(a)
  check("already sorted", a == @[1'i32, 2, 3, 4, 5])

block: # reverse sorted
  var a = @[5'i32, 4, 3, 2, 1]
  csort.sort(a)
  check("reverse sorted", a == @[1'i32, 2, 3, 4, 5])

block: # all equal
  var a = @[7'i32, 7, 7, 7, 7]
  csort.sort(a)
  check("all equal", a == @[7'i32, 7, 7, 7, 7])

block: # duplicates
  var a = @[3'i32, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5]
  csort.sort(a)
  var expected = @[3'i32, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5]
  expected.sort()
  check("duplicates", a == expected)

block: # negatives
  var a = @[-5'i32, 3, -1, 0, -100, 42, 7]
  csort.sort(a)
  var expected = @[-5'i32, 3, -1, 0, -100, 42, 7]
  expected.sort()
  check("negatives", a == expected)

block: # min/max values
  var a = @[high(int32), low(int32), 0'i32, 1, -1]
  csort.sort(a)
  var expected = @[high(int32), low(int32), 0'i32, 1, -1]
  expected.sort()
  check("min/max int32", a == expected)

# Random lengths from 2 to 1000
for n in 2 .. 1000:
  var a = newSeq[int32](n)
  for i in 0 ..< n:
    a[i] = rand(-1_000_000'i32 .. 1_000_000'i32)
  var expected = a
  expected.sort()
  csort.sort(a)
  check(&"random n={n}", a == expected)

echo &"  int32: {passed} passed, {failed} failed"

# -- int64 tests --
let p32 = passed
let f32 = failed
passed = 0
failed = 0

echo "=== int64 ==="

block:
  var a: seq[int64]
  csort.sort(a)
  check("empty", a.len == 0)

block:
  var a = @[2'i64, 1]
  csort.sort(a)
  check("two", a == @[1'i64, 2])

block:
  var a = @[5'i64, 4, 3, 2, 1]
  csort.sort(a)
  check("reverse sorted", a == @[1'i64, 2, 3, 4, 5])

block:
  var a = @[7'i64, 7, 7, 7, 7]
  csort.sort(a)
  check("all equal", a == @[7'i64, 7, 7, 7, 7])

block:
  var a = @[high(int64), low(int64), 0'i64, 1, -1]
  csort.sort(a)
  var expected = @[high(int64), low(int64), 0'i64, 1, -1]
  expected.sort()
  check("min/max int64", a == expected)

for n in 2 .. 1000:
  var a = newSeq[int64](n)
  for i in 0 ..< n:
    a[i] = rand(-1_000_000_000_000'i64 .. 1_000_000_000_000'i64)
  var expected = a
  expected.sort()
  csort.sort(a)
  check(&"random n={n}", a == expected)

echo &"  int64: {passed} passed, {failed} failed"

# Large sizes
passed = 0
failed = 0
echo "=== large ==="

for n in [10_000, 50_000, 100_000, 123_456]:
  block:
    var a = newSeq[int32](n)
    for i in 0 ..< n:
      a[i] = rand(-1_000_000'i32 .. 1_000_000'i32)
    var expected = a
    expected.sort()
    csort.sort(a)
    check(&"int32 n={n}", a == expected)

  block:
    var a = newSeq[int64](n)
    for i in 0 ..< n:
      a[i] = rand(-1_000_000_000_000'i64 .. 1_000_000_000_000'i64)
    var expected = a
    expected.sort()
    csort.sort(a)
    check(&"int64 n={n}", a == expected)

echo &"  large: {passed} passed, {failed} failed"

let totalPassed = p32 + f32 + passed + failed
echo &"\nTotal: {p32 + passed} passed, {f32 + failed} failed out of {totalPassed}"
