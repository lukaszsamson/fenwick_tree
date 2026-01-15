# FenwickTree

A Fenwick (Binary Indexed) Tree for efficient prefix-sum queries and point updates.

- `update/3`: **O(log n)**
- `prefix_sum/2`: **O(log n)**
- `range_sum/3`: **O(log n)**
- `from/1` build: **O(n)**

## Installation (Hex)

Add `fenwick_tree` to your dependencies:

```elixir
def deps do
  [
    {:fenwick_tree, "~> 0.1.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Usage

```elixir
ft = FenwickTree.from([1, 2, 3, 4, 5])

FenwickTree.prefix_sum(ft, 3)
#=> 6

ft = FenwickTree.update(ft, 2, 5) # add 5 at index 2
FenwickTree.get(ft, 2)
#=> 7

FenwickTree.range_sum(ft, 2, 4)
#=> 14

ft = FenwickTree.put(ft, 3, 10) # set index 3 to 10
FenwickTree.to_list(ft)
#=> [1, 7, 10, 4, 5]
```

### Indexing

All element indices are **1-based** (as is conventional for Fenwick trees):

- `update/3`, `get/2`, `put/3`, `range_sum/3`: indices `1..n`
- `prefix_sum/2`: accepts `0..n` (where `0` is the empty prefix)

### Order-statistics (`find_prefix/2`)

`find_prefix(ft, target)` returns the smallest index whose prefix sum is **>= target**.

Important: this operation assumes all stored values are **non-negative**. If any element
is negative, prefix sums may not be monotonic and the search is not valid.

## Documentation

When published, docs will be available at:

- https://hexdocs.pm/fenwick_tree

## Development

```bash
mix test
```
