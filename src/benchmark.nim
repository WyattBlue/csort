import std/[random, monotimes, times, strformat]
import std/algorithm as std
import csort

const Runs = 5

proc formatWithCommas(n: int): string =
  let s = $n
  var count = 0
  for i in countdown(s.len - 1, 0):
    if count > 0 and count mod 3 == 0:
      result = ',' & result
    result = s[i] & result
    inc(count)

proc bench[T: int32 | int64](name: string, n: int, sortProc: proc(a: var seq[T])): int =
  var totalNs: int64 = 0
  for _ in 1 .. Runs:
    # Generate data
    var data = newSeq[T](n)
    for i in 0 ..< n:
      data[i] = rand(T.high).T
    # Start timer
    let start = getMonoTime()
    sortProc(data)
    let elapsed = getMonoTime() - start
    totalNs += elapsed.inNanoseconds

  let avgMs = totalNs.float64 / Runs.float64 / 1_000_000.0
  echo &"    {name}: {avgMs:.3f} ms"
  return totalNs div Runs

proc diff(old, new: int) =
  let ret = old / new
  if ret < 1:
    echo &"    result: {ret:.3f}x (slower)"
  else:
    echo &"    result: {ret:.3f}x faster"

proc main =
  randomize(42)
  echo &"Averaged over {Runs} runs\n"

  var old: int
  var new: int
  for n in [100, 1_000, 10_000, 100_000, 1_000_000, 10_000_000]:
    echo &"--- n = {n.formatWithCommas} ---"
    echo "  [int32]"
    old = bench("std sort  ", n, proc(a: var seq[int32]) = std.sort(a))
    new = bench("SIMD csort", n, proc(a: var seq[int32]) = csort.sort(a))
    diff(old, new)

    echo "  [int64]"
    old = bench("std sort  ", n, proc(a: var seq[int64]) = std.sort(a))
    new = bench("SIMD csort", n, proc(a: var seq[int64]) = csort.sort(a))
    diff(old, new)
    echo ""

when isMainModule:
  main()
