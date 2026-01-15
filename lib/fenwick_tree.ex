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
  @spec from(nonempty_list(number())) :: t()
  def from(list = [_ | _]) when is_list(list) do
    n = length(list)

    # Initialise an array with a dummy element at index 0
    tmp = :array.from_list([0 | list])

    # Convert the raw values into a proper Fenwick tree (O(n))
    tree =
      Enum.reduce(1..n, tmp, fn i, acc ->
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
  def to_list(%FenwickTree{size: n, tree: arr}) do
    # 1.  Undo the build step: for every node i, subtract its value from
    #     the parent j = i + lowbit(i) (when that parent exists).
    tmp =
      Enum.reduce(n..1//-1, arr, fn i, a ->
        parent = i + lowbit(i)

        if parent <= n do
          v_parent = :array.get(parent, a)
          v_i = :array.get(i, a)
          :array.set(parent, v_parent - v_i, a)
        else
          a
        end
      end)

    # 2.  What’s left in each cell is the raw element.
    Enum.map(1..n, fn i -> :array.get(i, tmp) end)
  end

  @doc """
  Replace the element at `index` with `value`.

  Internally converts the assignment into a `delta` and delegates to
  `update/3`, so it is still **O(log n)**.
  """
  @spec put(t(), pos_integer(), number) :: t()
  def put(tree, index, value) do
    delta = value - get(tree, index)
    update(tree, index, delta)
  end

  @doc """
  **Order-statistics query** – smallest index whose prefix sum is **≥ `target`**.

  ## Important constraint

  This operation assumes all stored values are **non-negative**.
  If any element is negative, prefix sums are not guaranteed to be monotonic and
  the binary-lifting search is invalid.

  * Returns `nil` if `target` exceeds the total sum.
  * Runs in **O(log n)** by binary-lifting through the implicit tree.
  """
  @spec find_prefix(t(), number()) :: pos_integer() | nil
  def find_prefix(%FenwickTree{size: size, tree: arr} = tree, target)
      when is_number(target) do
    cond do
      target <= 0 ->
        1

      target > prefix_sum(tree, size) ->
        nil

      true ->
        # Start with the highest power of two ≤ size
        bit = highest_bit(size)
        find_prefix_inner(0, 0, bit, size, arr, target)
    end
  end

  # recursion terminates when bit reaches zero; idx holds the answer
  defp find_prefix_inner(idx, _sum, 0, _size, _arr, _target), do: idx + 1

  defp find_prefix_inner(idx, sum, bit, size, arr, target) do
    next = idx + bit

    {idx, sum} =
      if next <= size and sum + :array.get(next, arr) < target do
        {next, sum + :array.get(next, arr)}
      else
        {idx, sum}
      end

    find_prefix_inner(idx, sum, bit >>> 1, size, arr, target)
  end

  # ----------------------------------------------------------------------
  # Private helper
  # ----------------------------------------------------------------------
  @compile {:inline, lowbit: 1}
  defp lowbit(i), do: i &&& -i

  # Highest power of two ≤ n
  defp highest_bit(n), do: highest_bit(n, 1)

  defp highest_bit(n, bit) do
    next = bit <<< 1
    if next <= n, do: highest_bit(n, next), else: bit
  end
end
