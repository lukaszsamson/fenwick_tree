defmodule FenwickTreeTest do
  use ExUnit.Case
  alias FenwickTree

  test "new/1 creates a Fenwick tree with the correct size" do
    ft = FenwickTree.new(5)
    assert ft.size == 5
    # includes dummy index 0
    assert :array.size(ft.tree) == 6
  end

  test "building and basic queries" do
    ft = FenwickTree.from([1, 2, 3, 4, 5])

    assert FenwickTree.prefix_sum(ft, 1) == 1
    assert FenwickTree.prefix_sum(ft, 3) == 6
    assert FenwickTree.prefix_sum(ft, 5) == 15

    assert FenwickTree.range_sum(ft, 2, 4) == 2 + 3 + 4
    assert FenwickTree.get(ft, 4) == 4
  end

  test "updates affect subsequent queries" do
    ft = FenwickTree.from([1, 2, 3, 4, 5])
    # element 2 becomes 7
    ft = FenwickTree.update(ft, 2, 5)

    assert FenwickTree.get(ft, 2) == 7
    assert FenwickTree.prefix_sum(ft, 2) == 1 + 7
    assert FenwickTree.range_sum(ft, 2, 4) == 7 + 3 + 4
  end

  test "to_list/1 converts the Fenwick tree back to a list" do
    ft = FenwickTree.from([1, 2, 3, 4, 5])
    assert FenwickTree.to_list(ft) == [1, 2, 3, 4, 5]

    ft = FenwickTree.update(ft, 2, 5)
    assert FenwickTree.to_list(ft) == [1, 7, 3, 4, 5]
  end
end
