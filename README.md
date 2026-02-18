# csort

A constant-time sorting network. By using SIMD instructions, it achieves 2-5x faster times than Nim's `std/sort` for reasonable sized arrays.

By being in constant-time, no matter what the data is, it makes it immune to timing side-channels. This matters if you need to sort sensitive data in cryptographic contexts.

## Usage

```nim
import csort 

var a = @[3, 2, 5, 1, 4]
a.sort()
echo a

> @[1, 2, 3, 4, 5]
```

## Performance

### AArch64 MacOS Benchmark:

| n | int32 speedup | int64 speedup |
|---|---|---|
| 10,000 | **5.4×** | **3.4×** |
| 100,000 | **4.7×** | **2.8×** |
| 1,000,000 | **4.0×** | **1.7×** |

For sequences bigger than a million, the network scaling `O(n log^2 n)` catches up.

## Prior Art
Based on Ken Batcher's [1968 paper](https://www.cs.kent.edu/~batcher/sort.pdf) and Daniel J. Bernstein's [work](https://sorting.cr.yp.to/).

