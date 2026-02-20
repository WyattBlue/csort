import std/[random, monotimes, times, strformat]
import std/algorithm as std
import csort

const Runs = 10

proc generateData32(n: int): seq[int32] =
  result = newSeq[int32](n)
  for i in 0 ..< n:
    result[i] = rand(1_000_000).int32

proc generateData64(n: int): seq[int64] =
  result = newSeq[int64](n)
  for i in 0 ..< n:
    result[i] = rand(1_000_000).int64

proc bench32(name: string, n: int, sortProc: proc(a: var seq[int32])) =
  var totalNs: int64 = 0
  for _ in 1 .. Runs:
    var data = generateData32(n)
    let start = getMonoTime()
    sortProc(data)
    let elapsed = getMonoTime() - start
    totalNs += elapsed.inNanoseconds
  let avgMs = totalNs.float64 / Runs.float64 / 1_000_000.0
  echo &"  {name}: {avgMs:.3f} ms"

proc bench64(name: string, n: int, sortProc: proc(a: var seq[int64])) =
  var totalNs: int64 = 0
  for _ in 1 .. Runs:
    var data = generateData64(n)
    let start = getMonoTime()
    sortProc(data)
    let elapsed = getMonoTime() - start
    totalNs += elapsed.inNanoseconds
  let avgMs = totalNs.float64 / Runs.float64 / 1_000_000.0
  echo &"  {name}: {avgMs:.3f} ms"

randomize(42)

echo &"Averaged over {Runs} runs\n"

for n in [1000, 10_000, 100_000, 1_000_000]:
  echo &"--- n = {n} ---"
  echo "  [int32]"
  bench32("  std sort  ", n, proc(a: var seq[int32]) = std.sort(a))
  bench32("  SIMD csort", n, proc(a: var seq[int32]) = csort.sort(a))

  echo "  [int64]"
  bench64("  std sort  ", n, proc(a: var seq[int64]) = std.sort(a))
  bench64("  SIMD csort", n, proc(a: var seq[int64]) = csort.sort(a))
  echo ""
