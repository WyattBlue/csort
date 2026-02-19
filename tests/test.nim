import std/[random, strformat]
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

let p64 = passed
let f64 = failed
passed = 0
failed = 0

# -- int tests --
echo "=== int ==="

block: # empty
  var a: seq[int]
  csort.sort(a)
  check("empty", a.len == 0)

block: # single
  var a = @[1]
  csort.sort(a)
  check("single", a == @[1])

block: # two elements
  var a = @[2, 1]
  csort.sort(a)
  check("two", a == @[1, 2])

block: # reverse sorted
  var a = @[5, 4, 3, 2, 1]
  csort.sort(a)
  check("reverse sorted", a == @[1, 2, 3, 4, 5])

block: # all equal
  var a = @[7, 7, 7, 7, 7]
  csort.sort(a)
  check("all equal", a == @[7, 7, 7, 7, 7])

block: # negatives
  var a = @[-5, 3, -1, 0, -100, 42, 7]
  csort.sort(a)
  check("negatives", a == @[-100, -5, -1, 0, 3, 7, 42])

block: # min/max
  var a = @[high(int), low(int), 0, 1, -1]
  csort.sort(a)
  check("min/max", a[0] == low(int) and a[4] == high(int))

for n in 2 .. 1000:
  var a = newSeq[int](n)
  for i in 0 ..< n:
    a[i] = rand(-1_000_000 .. 1_000_000)
  var expected = a
  expected.sort()
  csort.sort(a)
  check(&"random n={n}", a == expected)

echo &"  int: {passed} passed, {failed} failed"

let pInt = passed
let fInt = failed

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

let pLarge = passed
let fLarge = failed
passed = 0
failed = 0

# -- float32 tests --
echo "=== float32 ==="

block: # empty
  var a: seq[float32]
  csort.sort(a)
  check("empty", a.len == 0)

block: # single
  var a = @[1.0'f32]
  csort.sort(a)
  check("single", a == @[1.0'f32])

block: # two elements
  var a = @[2.0'f32, 1.0'f32]
  csort.sort(a)
  check("two", a == @[1.0'f32, 2.0'f32])

block: # already sorted
  var a = @[1.0'f32, 2.0, 3.0, 4.0, 5.0]
  csort.sort(a)
  check("already sorted", a == @[1.0'f32, 2.0, 3.0, 4.0, 5.0])

block: # reverse sorted
  var a = @[5.0'f32, 4.0, 3.0, 2.0, 1.0]
  csort.sort(a)
  check("reverse sorted", a == @[1.0'f32, 2.0, 3.0, 4.0, 5.0])

block: # all equal
  var a = @[7.0'f32, 7.0, 7.0, 7.0, 7.0]
  csort.sort(a)
  check("all equal", a == @[7.0'f32, 7.0, 7.0, 7.0, 7.0])

block: # negatives
  var a = @[-5.0'f32, 3.0, -1.0, 0.0, -100.0, 42.0, 7.0]
  csort.sort(a)
  var expected = @[-5.0'f32, 3.0, -1.0, 0.0, -100.0, 42.0, 7.0]
  expected.sort()
  check("negatives", a == expected)

block: # infinities sort at the ends
  let posInf = float32(1.0 / 0.0)
  let negInf = float32(-1.0 / 0.0)
  var a = @[posInf, 1.0'f32, -1.0'f32, negInf, 0.0'f32]
  csort.sort(a)
  check("inf: -Inf first", a[0] == negInf)
  check("inf: +Inf last",  a[4] == posInf)
  check("inf: middle ordered", a[1] < a[2] and a[2] < a[3])

block: # -0.0 sorts before +0.0 (distinct bit patterns)
  var a = @[0.0'f32, -0.0'f32]
  csort.sort(a)
  check("-0.0 before +0.0", cast[int32](a[0]) < 0) # -0.0 has sign bit set

# Random lengths 2..1000
for n in 2 .. 1000:
  var a = newSeq[float32](n)
  for i in 0 ..< n:
    a[i] = float32(rand(-1_000.0 .. 1_000.0))
  var expected = a
  expected.sort()
  csort.sort(a)
  check(&"random n={n}", a == expected)

echo &"  float32: {passed} passed, {failed} failed"

let pF32 = passed
let fF32 = failed
passed = 0
failed = 0

# -- float64 tests --
echo "=== float64 ==="

block: # empty
  var a: seq[float64]
  csort.sort(a)
  check("empty", a.len == 0)

block: # single
  var a = @[1.0]
  csort.sort(a)
  check("single", a == @[1.0])

block: # two elements
  var a = @[2.0, 1.0]
  csort.sort(a)
  check("two", a == @[1.0, 2.0])

block: # reverse sorted
  var a = @[5.0, 4.0, 3.0, 2.0, 1.0]
  csort.sort(a)
  check("reverse sorted", a == @[1.0, 2.0, 3.0, 4.0, 5.0])

block: # all equal
  var a = @[7.0, 7.0, 7.0, 7.0, 7.0]
  csort.sort(a)
  check("all equal", a == @[7.0, 7.0, 7.0, 7.0, 7.0])

block: # negatives
  var a = @[-5.0, 3.0, -1.0, 0.0, -100.0, 42.0, 7.0]
  csort.sort(a)
  var expected = @[-5.0, 3.0, -1.0, 0.0, -100.0, 42.0, 7.0]
  expected.sort()
  check("negatives", a == expected)

block: # infinities sort at the ends
  let posInf = 1.0 / 0.0
  let negInf = -1.0 / 0.0
  var a = @[posInf, 1.0, -1.0, negInf, 0.0]
  csort.sort(a)
  check("inf: -Inf first", a[0] == negInf)
  check("inf: +Inf last",  a[4] == posInf)
  check("inf: middle ordered", a[1] < a[2] and a[2] < a[3])

block: # -0.0 sorts before +0.0
  var a = @[0.0, -0.0]
  csort.sort(a)
  check("-0.0 before +0.0", cast[int64](a[0]) < 0)

# Random lengths 2..1000
for n in 2 .. 1000:
  var a = newSeq[float64](n)
  for i in 0 ..< n:
    a[i] = rand(-1_000.0 .. 1_000.0)
  var expected = a
  expected.sort()
  csort.sort(a)
  check(&"random n={n}", a == expected)

echo &"  float64: {passed} passed, {failed} failed"

let pF64 = passed
let fF64 = failed
passed = 0
failed = 0

# -- uint32 tests --
echo "=== uint32 ==="

block:
  var a: seq[uint32]
  csort.sort(a)
  check("empty", a.len == 0)

block:
  var a = @[2'u32, 1'u32]
  csort.sort(a)
  check("two", a == @[1'u32, 2'u32])

block:
  var a = @[5'u32, 4, 3, 2, 1]
  csort.sort(a)
  check("reverse sorted", a == @[1'u32, 2, 3, 4, 5])

block:
  var a = @[7'u32, 7, 7, 7, 7]
  csort.sort(a)
  check("all equal", a == @[7'u32, 7, 7, 7, 7])

block:
  var a = @[high(uint32), 0'u32, 1'u32]
  csort.sort(a)
  check("min/max uint32", a == @[0'u32, 1'u32, high(uint32)])

for n in 2 .. 1000:
  var a = newSeq[uint32](n)
  for i in 0 ..< n:
    a[i] = uint32(rand(0 .. 2_000_000))
  var expected = a
  expected.sort()
  csort.sort(a)
  check(&"random n={n}", a == expected)

echo &"  uint32: {passed} passed, {failed} failed"

let pU32 = passed
let fU32 = failed
passed = 0
failed = 0

# -- uint64 tests --
echo "=== uint64 ==="

block:
  var a: seq[uint64]
  csort.sort(a)
  check("empty", a.len == 0)

block:
  var a = @[2'u64, 1'u64]
  csort.sort(a)
  check("two", a == @[1'u64, 2'u64])

block:
  var a = @[5'u64, 4, 3, 2, 1]
  csort.sort(a)
  check("reverse sorted", a == @[1'u64, 2, 3, 4, 5])

block:
  var a = @[7'u64, 7, 7, 7, 7]
  csort.sort(a)
  check("all equal", a == @[7'u64, 7, 7, 7, 7])

block:
  var a = @[high(uint64), 0'u64, 1'u64]
  csort.sort(a)
  check("min/max uint64", a == @[0'u64, 1'u64, high(uint64)])

for n in 2 .. 1000:
  var a = newSeq[uint64](n)
  for i in 0 ..< n:
    a[i] = uint64(rand(0'i64 .. 2_000_000_000_000'i64))
  var expected = a
  expected.sort()
  csort.sort(a)
  check(&"random n={n}", a == expected)

echo &"  uint64: {passed} passed, {failed} failed"

let pU64 = passed
let fU64 = failed
passed = 0
failed = 0

# -- uint tests --
echo "=== uint ==="

block:
  var a: seq[uint]
  csort.sort(a)
  check("empty", a.len == 0)

block:
  var a = @[2'u, 1'u]
  csort.sort(a)
  check("two", a == @[1'u, 2'u])

block:
  var a = @[5'u, 4, 3, 2, 1]
  csort.sort(a)
  check("reverse sorted", a == @[1'u, 2, 3, 4, 5])

block:
  var a = @[7'u, 7, 7, 7, 7]
  csort.sort(a)
  check("all equal", a == @[7'u, 7, 7, 7, 7])

block:
  var a = @[high(uint), 0'u, 1'u]
  csort.sort(a)
  check("min/max uint", a == @[0'u, 1'u, high(uint)])

for n in 2 .. 1000:
  var a = newSeq[uint](n)
  for i in 0 ..< n:
    a[i] = uint(rand(0 .. 1_000_000))
  var expected = a
  expected.sort()
  csort.sort(a)
  check(&"random n={n}", a == expected)

echo &"  uint: {passed} passed, {failed} failed"

let pUInt = passed
let fUInt = failed

let totalTests = p32 + f32 + p64 + f64 + pInt + fInt + pLarge + fLarge + pF32 + fF32 + pF64 + fF64 + pU32 + fU32 + pU64 + fU64 + pUInt + fUInt
let totalPass  = p32 + p64 + pInt + pLarge + pF32 + pF64 + pU32 + pU64 + pUInt
let totalFail  = f32 + f64 + fInt + fLarge + fF32 + fF64 + fU32 + fU64 + fUInt
echo &"\nTotal: {totalPass} passed, {totalFail} failed out of {totalTests}"
