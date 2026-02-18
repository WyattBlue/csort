# Batcher's odd-even mergesort with SIMD, handles arbitrary lengths.

when defined(arm64) or defined(aarch64):
  const HasSimd = true

  # -- int32: 4-wide NEON --
  const VecLen32 = 4
  type Vec32 {.importc: "int32x4_t", header: "<arm_neon.h>".} = object
  proc neonLoad32(p: ptr int32): Vec32 {.importc: "vld1q_s32", header: "<arm_neon.h>".}
  proc neonStore32(p: ptr int32, v: Vec32) {.importc: "vst1q_s32", header: "<arm_neon.h>".}
  proc neonMin32(a, b: Vec32): Vec32 {.importc: "vminq_s32", header: "<arm_neon.h>".}
  proc neonMax32(a, b: Vec32): Vec32 {.importc: "vmaxq_s32", header: "<arm_neon.h>".}

  # -- int64: 2-wide NEON (compare + bitselect) --
  const VecLen64 = 2
  type Vec64 {.importc: "int64x2_t", header: "<arm_neon.h>".} = object
  type VecU64 {.importc: "uint64x2_t", header: "<arm_neon.h>".} = object
  proc neonLoad64(p: ptr int64): Vec64 {.importc: "vld1q_s64", header: "<arm_neon.h>".}
  proc neonStore64(p: ptr int64, v: Vec64) {.importc: "vst1q_s64", header: "<arm_neon.h>".}
  proc neonCgtS64(a, b: Vec64): VecU64 {.importc: "vcgtq_s64", header: "<arm_neon.h>".}
  proc neonBslS64(mask: VecU64, a, b: Vec64): Vec64 {.importc: "vbslq_s64", header: "<arm_neon.h>".}

  proc neonMin64(a, b: Vec64): Vec64 {.inline.} =
    let mask = neonCgtS64(a, b) # true where a > b
    neonBslS64(mask, b, a)      # pick b where a>b, else a

  proc neonMax64(a, b: Vec64): Vec64 {.inline.} =
    let mask = neonCgtS64(a, b)
    neonBslS64(mask, a, b)      # pick a where a>b, else b

elif defined(amd64):
  const HasSimd = true
  {.passC: "-msse4.2".}

  # -- int32: 4-wide SSE4.1 --
  const VecLen32 = 4
  type Vec32 {.importc: "__m128i", header: "<smmintrin.h>".} = object
  proc sseLoad(p: ptr Vec32): Vec32 {.importc: "_mm_loadu_si128", header: "<smmintrin.h>".}
  proc sseStore(p: ptr Vec32, v: Vec32) {.importc: "_mm_storeu_si128", header: "<smmintrin.h>".}
  proc sseMin32(a, b: Vec32): Vec32 {.importc: "_mm_min_epi32", header: "<smmintrin.h>".}
  proc sseMax32(a, b: Vec32): Vec32 {.importc: "_mm_max_epi32", header: "<smmintrin.h>".}

  proc neonLoad32(p: ptr int32): Vec32 {.inline.} = sseLoad(cast[ptr Vec32](p))
  proc neonStore32(p: ptr int32, v: Vec32) {.inline.} = sseStore(cast[ptr Vec32](p), v)
  proc neonMin32(a, b: Vec32): Vec32 {.inline.} = sseMin32(a, b)
  proc neonMax32(a, b: Vec32): Vec32 {.inline.} = sseMax32(a, b)

  # -- int64: 2-wide SSE4.2 --
  const VecLen64 = 2
  type Vec64 = Vec32 # same __m128i type
  proc sseCmpGt64(a, b: Vec64): Vec64 {.importc: "_mm_cmpgt_epi64", header: "<nmmintrin.h>".}
  proc sseBlendv(a, b, mask: Vec64): Vec64 {.importc: "_mm_blendv_epi8", header: "<smmintrin.h>".}

  proc neonLoad64(p: ptr int64): Vec64 {.inline.} = sseLoad(cast[ptr Vec32](p))
  proc neonStore64(p: ptr int64, v: Vec64) {.inline.} = sseStore(cast[ptr Vec32](p), v)

  proc neonMin64(a, b: Vec64): Vec64 {.inline.} =
    let mask = sseCmpGt64(a, b)
    sseBlendv(a, b, mask) # pick b where a>b, else a

  proc neonMax64(a, b: Vec64): Vec64 {.inline.} =
    let mask = sseCmpGt64(a, b)
    sseBlendv(b, a, mask) # pick a where a>b, else b

else:
  const HasSimd = false
  const VecLen32 = 0
  const VecLen64 = 0

# Constant-time scalar minmax using XOR-masked swap.
# Widens to a larger signed type to compute (b - a), extracts the sign bit
# to build an all-ones or all-zeros mask, then XOR-swaps conditionally.
# An asm barrier prevents the compiler from converting this to branches.

proc asmBarrier32(x: var uint32) {.inline.} =
  {.emit: ["__asm__ volatile(\"\" : \"+r\"(", x, "));"].}

proc asmBarrier64(x: var uint64) {.inline.} =
  {.emit: ["__asm__ volatile(\"\" : \"+r\"(", x, "));"].}

proc minmax(a, b: var int32) {.inline.} =
  # Widen to 64-bit to avoid overflow on subtraction
  let diff = b.int64 - a.int64
  let signBit = cast[uint64](diff) shr 63  # 1 if a > b, 0 otherwise
  var mask = cast[uint32](0'i32 - signBit.int32) # all 1s if a > b
  asmBarrier32(mask)
  let d = cast[uint32](a) xor cast[uint32](b)
  let masked = d and mask
  a = a xor cast[int32](masked)
  b = b xor cast[int32](masked)

proc minmax(a, b: var int64) {.inline.} =
  # On aarch64/x86_64, `a > b` compiles to cmp + cset/setcc (constant-time).
  # The asm barrier prevents the compiler from converting the XOR swap back
  # into a conditional branch.
  let swap = uint64(ord(a > b))     # 0 or 1, branchless on aarch64/x86_64
  var mask = not (swap - 1'u64)     # all 1s if a > b, all 0s otherwise
  asmBarrier64(mask)
  let d = cast[uint64](a) xor cast[uint64](b)
  let masked = d and mask
  a = a xor cast[int64](masked)
  b = b xor cast[int64](masked)

# Maps IEEE 754 float bit-patterns to an integer sort key that preserves
# the natural float ordering under signed integer comparison:
#   - positive floats (sign=0): key = bits unchanged (already ordered)
#   - negative floats (sign=1): key = bits ^ 0x7FFFFFFF (flip lower bits,
#     inverting the order so more-negative floats get smaller keys)
# The function is its own inverse, so applying it again restores the original.

proc floatSortKey(s: int32): int32 {.inline.} =
  let sign = cast[uint32](s) shr 31    # 1 if negative, 0 if positive
  let mask = cast[int32](0'u32 - sign) # all 1s if negative, 0 if positive
  s xor (mask and high(int32))

proc floatSortKey(s: int64): int64 {.inline.} =
  let sign = cast[uint64](s) shr 63
  let mask = cast[int64](0'u64 - sign)
  s xor (mask and high(int64))

proc cascade[T: int32 | int64](data: ptr UncheckedArray[T], j, p, q: int) {.inline.} =
  var a = data[j + p]
  var r = q
  while r > p:
    minmax(a, data[j + r])
    r = r shr 1
  data[j + p] = a

# Core sorting network, templated over element type and SIMD width.
# Operates directly on a raw pointer + length so float sorts can reuse it
# after transforming their data in place via floatSortKey.
proc cSortCore[T: int32 | int64](data: ptr UncheckedArray[T], n: int) =
  if n < 2: return

  const vecLen = when T is int32: VecLen32 else: VecLen64

  var top = 1
  while top < n - top:
    top += top

  var p = top
  while p >= 1:
    # Loop 1: main minmax pairs
    var i = 0
    while i + 2 * p <= n:
      var k = 0
      when HasSimd and vecLen > 0:
        while k + vecLen <= p:
          when T is int32:
            let aVec = neonLoad32(addr data[i + k])
            let bVec = neonLoad32(addr data[i + k + p])
            neonStore32(addr data[i + k], neonMin32(aVec, bVec))
            neonStore32(addr data[i + k + p], neonMax32(aVec, bVec))
          else:
            let aVec = neonLoad64(addr data[i + k])
            let bVec = neonLoad64(addr data[i + k + p])
            neonStore64(addr data[i + k], neonMin64(aVec, bVec))
            neonStore64(addr data[i + k + p], neonMax64(aVec, bVec))
          k += vecLen
      while k < p:
        minmax(data[i + k], data[i + k + p])
        k += 1
      i += 2 * p

    # Loop 2: residual minmax
    var j = i
    when HasSimd and vecLen > 0:
      while j + vecLen + p <= n:
        when T is int32:
          let aVec = neonLoad32(addr data[j])
          let bVec = neonLoad32(addr data[j + p])
          neonStore32(addr data[j], neonMin32(aVec, bVec))
          neonStore32(addr data[j + p], neonMax32(aVec, bVec))
        else:
          let aVec = neonLoad64(addr data[j])
          let bVec = neonLoad64(addr data[j + p])
          neonStore64(addr data[j], neonMin64(aVec, bVec))
          neonStore64(addr data[j + p], neonMax64(aVec, bVec))
        j += vecLen
    while j + p < n:
      minmax(data[j], data[j + p])
      j += 1

    # Cascade loops
    i = 0
    j = 0
    var q = top
    while q > p:
      block qBody:
        if j != i:
          while true:
            if j + q == n:
              break qBody
            cascade(data, j, p, q)
            j += 1
            if j == i + p:
              i += 2 * p
              break

        # Loop 3: cascade groups with SIMD
        while i + p + q <= n:
          var k = 0
          when HasSimd and vecLen > 0:
            while k + vecLen <= p:
              when T is int32:
                var aVec = neonLoad32(addr data[i + k + p])
                var r = q
                while r > p:
                  let cVec = neonLoad32(addr data[i + k + r])
                  let hi = neonMax32(aVec, cVec)
                  aVec = neonMin32(aVec, cVec)
                  neonStore32(addr data[i + k + r], hi)
                  r = r shr 1
                neonStore32(addr data[i + k + p], aVec)
              else:
                var aVec = neonLoad64(addr data[i + k + p])
                var r = q
                while r > p:
                  let cVec = neonLoad64(addr data[i + k + r])
                  let hi = neonMax64(aVec, cVec)
                  aVec = neonMin64(aVec, cVec)
                  neonStore64(addr data[i + k + r], hi)
                  r = r shr 1
                neonStore64(addr data[i + k + p], aVec)
              k += vecLen
          while k < p:
            cascade(data, i + k, p, q)
            k += 1
          i += 2 * p

        # Loop 4: residual cascades
        j = i
        when HasSimd and vecLen > 0:
          if p >= vecLen:
            while j + vecLen + q <= n:
              when T is int32:
                var aVec = neonLoad32(addr data[j + p])
                var r = q
                while r > p:
                  let cVec = neonLoad32(addr data[j + r])
                  let hi = neonMax32(aVec, cVec)
                  aVec = neonMin32(aVec, cVec)
                  neonStore32(addr data[j + r], hi)
                  r = r shr 1
                neonStore32(addr data[j + p], aVec)
              else:
                var aVec = neonLoad64(addr data[j + p])
                var r = q
                while r > p:
                  let cVec = neonLoad64(addr data[j + r])
                  let hi = neonMax64(aVec, cVec)
                  aVec = neonMin64(aVec, cVec)
                  neonStore64(addr data[j + r], hi)
                  r = r shr 1
                neonStore64(addr data[j + p], aVec)
              j += vecLen
        while j + q < n:
          cascade(data, j, p, q)
          j += 1

      q = q shr 1

    p = p shr 1

proc cSortImpl[T: int32 | int64](items: var openArray[T]) =
  if items.len < 2: return
  cSortCore(cast[ptr UncheckedArray[T]](addr items[0]), items.len)

proc sort*(items: var openArray[int32]) = cSortImpl(items)
proc sort*(items: var openArray[int64]) = cSortImpl(items)

# Float sort: transform bit-patterns to sort keys, sort as integers, untransform.
# Resulting order: -NaN < -INF < ... < -0.0 < +0.0 < ... < +INF < +NaN

proc sort*(items: var openArray[float32]) =
  let n = items.len
  if n < 2: return
  let idata = cast[ptr UncheckedArray[int32]](addr items[0])
  for i in 0 ..< n: idata[i] = floatSortKey(idata[i])
  cSortCore(idata, n)
  for i in 0 ..< n: idata[i] = floatSortKey(idata[i])

proc sort*(items: var openArray[float64]) =
  let n = items.len
  if n < 2: return
  let idata = cast[ptr UncheckedArray[int64]](addr items[0])
  for i in 0 ..< n: idata[i] = floatSortKey(idata[i])
  cSortCore(idata, n)
  for i in 0 ..< n: idata[i] = floatSortKey(idata[i])

when isMainModule:
  block:
    var data = @[10'i32, 3, 15, 1, 8, 12, 6, 16, 9, 2, 14, 4, 7, 11, 5, 13]
    echo "int32 before: ", data
    sort(data)
    echo "int32 after:  ", data

  block:
    var data = @[10'i64, 3, 15, 1, 8, 12, 6, 16, 9, 2, 14, 4, 7, 11, 5, 13]
    echo "int64 before: ", data
    sort(data)
    echo "int64 after:  ", data

  block:
    var odd = @[5'i32, 2, 8, 1, 9, 3, 7]
    sort(odd)
    echo "int32 odd:    ", odd

  block:
    var odd = @[5'i64, 2, 8, 1, 9, 3, 7]
    sort(odd)
    echo "int64 odd:    ", odd

  block:
    var data = @[-3.0'f32, 1.5, -0.0, 0.0, 2.5, -1.0]
    sort(data)
    echo "float32:      ", data

  block:
    var data = @[-3.0'f64, 1.5, -0.0, 0.0, 2.5, -1.0]
    sort(data)
    echo "float64:      ", data
