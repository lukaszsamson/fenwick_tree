defmodule FenwickTree do
  @moduledoc """
  A Fenwick (Binary Indexed) Tree for efficient prefix‑sum queries
  and point updates.

  ## Complexity

  * `update/3` – **O(log n)**
  * `prefix_sum/2` – **O(log n)**
  * `range_sum/3` – **O(log n)** (two prefix sums)

  The tree works with *1‑based* indices, which is the conventional
  formulation for Fenwick Trees.  A tiny wrapper `get/2` is provided
  to read a single element (via a difference of two prefix sums).

  ## Example

      iex> ft = FenwickTree.from([1, 2, 3, 4, 5])
      iex> FenwickTree.prefix_sum(ft, 3)
      6
      iex> ft = FenwickTree.update(ft, 2, 5)   # add 5 to element at index 2
      iex> FenwickTree.prefix_sum(ft, 3)
      11
      iex> FenwickTree.range_sum(ft, 2, 4)
      14
      iex> FenwickTree.get(ft, 2)
      7
  """

  # Enable the bitwise operators &&& , >>> , etc.
  import Bitwise

  # Public struct – `tree` holds the underlying Erlang array.
  defstruct size: 0, tree: nil

  @type t :: %FenwickTree{
          size: pos_integer(),
          tree: :array.array()
        }

  @spec new(pos_integer()) :: t()
  def new(size) when is_integer(size) and size > 0 do
    %FenwickTree{
      size: size,
      # index 0 is unused
      tree: :array.new(size + 1, default: 0)
    }
  end

  @doc """
  Build a Fenwick tree from a plain list.

  The list is interpreted as a 1‑based array of values.
  """
  @spec from([number]) :: t()
  def from(list) when is_list(list) do
    n = length(list)

    # Initialise an array with a dummy element at index 0
    arr = :array.new(n + 1, default: 0)

    # Load the raw values at positions 1..n
    arr =
      Enum.reduce(Enum.with_index(list, 1), arr, fn {val, idx}, acc ->
        :array.set(idx, val, acc)
      end)

    # Convert the raw values into a proper Fenwick tree (O(n))
    tree =
      Enum.reduce(1..n, arr, fn i, acc ->
        j = i + lowbit(i)

        if j <= n do
          val_i = :array.get(i, acc)
          val_j = :array.get(j, acc)
          :array.set(j, val_i + val_j, acc)
        else
          acc
        end
      end)

    %FenwickTree{size: n, tree: tree}
  end

  @doc """
  Add `delta` to the element at `index` (1‑based).

  Returns a new `%FenwickTree{}` where the internal array reflects the update.
  """
  @spec update(t(), pos_integer(), number) :: t()
  def update(%FenwickTree{size: size, tree: arr} = ft, index, delta)
      when is_integer(index) and index >= 1 and index <= size do
    new_arr = do_update(arr, index, delta, size)
    %FenwickTree{ft | tree: new_arr}
  end

  # Recursive helper for the point‑update
  defp do_update(arr, i, delta, size) do
    current = :array.get(i, arr)
    arr = :array.set(i, current + delta, arr)
    next = i + lowbit(i)

    if next <= size do
      do_update(arr, next, delta, size)
    else
      arr
    end
  end

  @doc """
  Returns the sum of the first `index` elements (i.e. a prefix sum).

  `index` may be `0` (the empty prefix) and must not exceed the size of the tree.
  """
  @spec prefix_sum(t(), non_neg_integer()) :: number()
  def prefix_sum(%FenwickTree{size: size, tree: arr}, index)
      when is_integer(index) and index >= 0 and index <= size do
    do_prefix_sum(arr, index, 0)
  end

  defp do_prefix_sum(_arr, 0, acc), do: acc

  defp do_prefix_sum(arr, i, acc) do
    acc = acc + :array.get(i, arr)
    i = i - lowbit(i)
    do_prefix_sum(arr, i, acc)
  end

  @doc """
  Sum of the slice `[left, right]` (both inclusive).

  Requires `1 ≤ left ≤ right ≤ size`.
  """
  @spec range_sum(t(), pos_integer(), pos_integer()) :: number()
  def range_sum(tree, left, right)
      when is_integer(left) and is_integer(right) and left >= 1 and right <= tree.size and
             left <= right do
    prefix_sum(tree, right) - prefix_sum(tree, left - 1)
  end

  @doc """
  Retrieve the original value stored at `index`.

  It is implemented as the difference of two prefix sums,
  therefore it also runs in **O(log n)**.
  """
  @spec get(t(), pos_integer()) :: number()
  def get(tree, index) when is_integer(index) and index >= 1 and index <= tree.size do
    prefix_sum(tree, index) - prefix_sum(tree, index - 1)
  end

  @doc """
  Returns the original list of values stored in the Fenwick tree.
  """
  @spec to_list(t()) :: [number()]
  def to_list(%FenwickTree{size: size, tree: _arr} = tree) do
    {values_reversed, _} =
      1..size
      |> Enum.reduce({[], 0}, fn index, {acc, last_prefix_sum} ->
        prefix_sum = prefix_sum(tree, index)
        value = prefix_sum - last_prefix_sum
        {[value | acc], prefix_sum}
      end)

    Enum.reverse(values_reversed)
  end

  # ----------------------------------------------------------------------
  # Private helper
  # ----------------------------------------------------------------------
  defp lowbit(i), do: i &&& -i
end
