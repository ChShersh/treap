# treap

![Treap: tree logo](https://user-images.githubusercontent.com/4276606/56883228-9f32f180-6a98-11e9-9554-13735ff1ed30.png)
[![Hackage](https://img.shields.io/hackage/v/treap.svg)](https://hackage.haskell.org/package/treap)
[![Build status](https://secure.travis-ci.org/chshersh/treap.svg)](https://travis-ci.org/chshersh/treap)
[![MPL-2.0 license](https://img.shields.io/badge/license-MPL--2.0-blue.svg)](LICENSE)

Efficient implementation of the implicit treap data structure.

## What does this package provide?

This package implements a tree-like data structure called _implicit treap_. This
data structure implements interface similar to random-access arrays, but with
fast (logarithmic time complexity)
`insert`/`delete`/`split`/`merge`/`take`/`drop`/`rotate` operations. In addition,
_treap_ allows you to specify and measure values of any monoids on a segment,
like a sum of elements or minimal element on some contiguous part of the array.

## When to use this package?

Use this package when you want the following operations to be fast:

1. Access elements by index.
2. Insert elements by index.
3. Delete elements by index.
4. Calculate monoidal operation (like sum, product, min, etc.) of all elements
   between two indices.
5. Call slicing operations like `take` or `drop` or `split`.

Below you can find the table of time complexity for all operations (where `n` is
the size of the treap):

| Operation | Time complexity | Description                          |
|-----------|-----------------|--------------------------------------|
| `size`    | `O(1)`          | Get number of elements in the treap  |
| `at`      | `O(log n)`      | Access by index                      |
| `insert`  | `O(log n)`      | Insert by index                      |
| `delete`  | `O(log n)`      | Delete by index                      |
| `query`   | `O(log n)`      | Measure monoid on the segment        |
| `splitAt` | `O(log n)`      | Split treap by index into two treaps |
| `merge`   | `O(log n)`      | Merge two treaps into a single one   |
| `take`    | `O(log n)`      | Take first `i` elements of the treap |
| `drop`    | `O(log n)`      | Drop first `i` elements of the treap |
| `rotate`  | `O(log n)`      | Put first `i` elements to the end    |

The package also comes with nice pretty-printing!

```haskell
ghci> t = fromList [1..5] :: RTreap (Sum Int) Int
ghci> prettyPrint t
   5,15:2
      ╱╲
     ╱  ╲
    ╱    ╲
   ╱      ╲
1,1:1   3,12:4
          ╱╲
         ╱  ╲
        ╱    ╲
      1,3:3 1,5:5

```

## Alternatives

If you don't need to calculate monoidal operations, you may alternatively use
[`Seq`](https://hackage.haskell.org/package/containers-0.6.0.1/docs/Data-Sequence.html#t:Seq)
from the `containers` package as it provides more extended interface but doesn't
allow to measure monoidal values on segments.

## Acknowledgement

Icons made by [Freepik](http://www.freepik.com) from [www.flaticon.com](https://www.flaticon.com/) is licensed by [CC 3.0 BY](http://creativecommons.org/licenses/by/3.0/).
