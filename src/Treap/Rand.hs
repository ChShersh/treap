{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies      #-}

{- | Fair implementation of the 'Treap' data structure that uses random
generator for priorities.
-}

module Treap.Rand
       ( -- * Data structure
         RTreap (..)

         -- * Smart constructors
       , emptyWithGen
       , oneWithGen
       , empty
       , one

         -- * Query functions
       , size
       , at
       , query

       -- * Cuts and joins
       , splitAt
       , merge
       , take
       , drop
       , rotate

       -- * Modification functions
       , insert
       , delete

         -- * General purpose functions
       , withTreap
       , overTreap

         -- * Pretty printing functions
       , prettyPrint
       ) where

import Prelude hiding (drop, lookup, splitAt, take)

import Control.DeepSeq (NFData (..))
import Data.Coerce (Coercible)
import Data.Foldable (foldl')
import GHC.Exts (IsList (..))
import GHC.Generics (Generic)

import Treap.Measured (Measured (..))
import Treap.Pure (Priority (..), Size (..), Treap)

import qualified System.Random.Mersenne.Pure64 as Random
import qualified Treap.Pretty as Treap
import qualified Treap.Pure as Treap

-- $setup
-- >>> import Data.Monoid

----------------------------------------------------------------------------
-- Data structure and instances
----------------------------------------------------------------------------

{- | Specialized version of 'Treap' where priority is
generated by the stored random generator.
-}
data RTreap m a = RTreap
    { rTreapGen  :: !Random.PureMT
    , rTreapTree :: !(Treap m a)
    } deriving stock (Show, Generic, Foldable)

{- | (<>) is implemented via 'merge'.
-}
instance Measured m a => Semigroup (RTreap m a) where
    (<>) = merge

{- | mempty is implemented via 'empty'.
-}
instance Measured m a => Monoid (RTreap m a) where
    mempty = empty

-- | \( O(n) \). This instance doesn't compare random generators inside trees.
instance (Eq m, Eq a) => Eq (RTreap m a) where
    (==) :: RTreap m a -> RTreap m a -> Bool
    RTreap _ t1 == RTreap _ t2 = t1 == t2

-- | \( O(1) \). Takes cached value from the root.
instance Monoid m => Measured m (RTreap m a) where
    measure :: RTreap m a -> m
    measure = withTreap measure
    {-# INLINE measure #-}

{- | Pure implementation of 'RTreap' construction functions. Uses
@'empty' :: RTreap k a@ as a starting point. Functions have the following
time complexity:

1. 'fromList': \( O(n\ \log \ n) \)
2. 'toList': \( O(n) \)

>>> prettyPrint $ fromList @(RTreap (Sum Int) Int) [1..5]
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
-}
instance Measured m a => IsList (RTreap m a) where
    type Item (RTreap m a) = a

    fromList :: [a] -> RTreap m a
    fromList = foldl' (\t (i, a) -> insert i a t) empty . zip [0..]
    {-# INLINE fromList #-}

    toList :: RTreap m a -> [a]
    toList = map snd . toList . rTreapTree
    {-# INLINE toList #-}

instance (NFData m, NFData a) => NFData (RTreap m a) where
    rnf RTreap{..} = rnf rTreapTree `seq` ()

----------------------------------------------------------------------------
-- Smart constructors
----------------------------------------------------------------------------

defaultRandomGenerator :: Random.PureMT
defaultRandomGenerator = Random.pureMT 0

-- | \( O(1) \). Create empty 'RTreap' with given random generator.
emptyWithGen :: Random.PureMT -> RTreap m a
emptyWithGen gen = RTreap gen Treap.Empty
{-# INLINE emptyWithGen #-}

-- | \( O(1) \). Create empty 'RTreap' using random generator with seed @0@.
empty :: RTreap m a
empty = emptyWithGen defaultRandomGenerator
{-# INLINE empty #-}

-- | \( O(1) \). Create singleton 'RTreap' with given random generator.
oneWithGen :: Measured m a => Random.PureMT -> a -> RTreap m a
oneWithGen gen a =
    let (priority, newGen) = Random.randomWord64 gen
    in RTreap newGen $ Treap.one (Priority priority) a
{-# INLINE oneWithGen #-}

-- | \( O(1) \). Create singleton 'RTreap' using random generator with seed @0@.
one :: Measured m a => a -> RTreap m a
one = oneWithGen defaultRandomGenerator
{-# INLINE one #-}

----------------------------------------------------------------------------
-- Query functions
----------------------------------------------------------------------------

{- | \( O(1) \). Returns the size of the 'RTreap'.

__Properties:__

* \( \forall (t\ ::\ \mathrm{Treap}\ m\ a)\ .\ \mathrm{size}\ t \geqslant 0 \)
-}
size :: RTreap m a -> Int
size = unSize . withTreap Treap.size
{-# INLINE size #-}

-- | \( O(\log \ n) \). Lookup a value by a given key inside 'RTreap'.
at :: Int -> RTreap m a -> Maybe a
at i = withTreap $ Treap.at i
{-# INLINE at #-}

-- | \( O(\log \ n) \). Return value of monoidal accumulator on a segment @[l, r)@.
query :: forall m a . Measured m a => Int -> Int -> RTreap m a -> m
query l r = withTreap (Treap.query l r)
{-# INLINE query #-}

----------------------------------------------------------------------------
-- Cuts and joins
----------------------------------------------------------------------------

-- | \( O(\log \ n) \). Lifted to 'RTreap' version of 'Treap.splitAt'.
splitAt :: forall m a . Measured m a => Int -> RTreap m a -> (RTreap m a, RTreap m a)
splitAt i (RTreap gen t) = let (l, r) = Treap.splitAt i t in (RTreap gen l, RTreap gen r)
{-# INLINE splitAt #-}

-- | \( O(\log \ n) \). Lifted to 'RTreap' version of 'Treap.merge'.
merge :: Measured m a => RTreap m a -> RTreap m a -> RTreap m a
merge (RTreap gen t1) (RTreap _ t2) = RTreap gen (Treap.merge t1 t2)
{-# INLINE merge #-}

-- | \( O(\log \ n) \). Lifted to 'RTreap' version of 'Treap.take'.
take :: forall m a . Measured m a => Int -> RTreap m a -> RTreap m a
take n = overTreap (Treap.take n)
{-# INLINE take #-}

-- | \( O(\log \ n) \). Lifted to 'RTreap' version of 'Treap.drop'.
drop :: forall m a . Measured m a => Int -> RTreap m a -> RTreap m a
drop n = overTreap (Treap.drop n)
{-# INLINE drop #-}

-- | \( O(\log \ n) \). Lifted to 'RTreap' version of 'Treap.rotate'.
rotate :: forall m a . Measured m a => Int -> RTreap m a -> RTreap m a
rotate n = overTreap (Treap.rotate n)
{-# INLINE rotate #-}

----------------------------------------------------------------------------
-- Modification functions
----------------------------------------------------------------------------

-- | \( O(\log \ n) \). Insert a value into 'RTreap' by given key.
insert :: forall m a . Measured m a => Int -> a -> RTreap m a -> RTreap m a
insert i a (RTreap gen t) =
    let (priority, newGen) = Random.randomWord64 gen
    in RTreap newGen $ Treap.insert i (Priority priority) a t
{-# INLINE insert #-}

{- | \( O(\log \ n) \). Delete 'RTreap' node that contains given key. If there is no
such key, 'RTreap' remains unchanged.
-}
delete :: forall m a . Measured m a => Int -> RTreap m a -> RTreap m a
delete i (RTreap gen t) = RTreap gen $ Treap.delete i t
{-# INLINE delete #-}

----------------------------------------------------------------------------
-- Generic functions
----------------------------------------------------------------------------

-- | Lift a function that works with 'Treap' to 'RTreap'.
withTreap :: (Treap m a -> r) -> (RTreap m a -> r)
withTreap f = f . rTreapTree
{-# INLINE withTreap #-}

-- | Lift a function that works with 'Treap' to 'RTreap'.
overTreap :: (Treap m a -> Treap m a) -> (RTreap m a -> RTreap m a)
overTreap set t = t { rTreapTree = set $ rTreapTree t }
{-# INLINE overTreap #-}

----------------------------------------------------------------------------
-- Pretty printing functions
----------------------------------------------------------------------------

-- | Pretty prints 'RTreap' without printing random generator.
prettyPrint :: forall m a . (Coercible m a, Show a) => RTreap m a -> IO ()
prettyPrint = withTreap Treap.prettyPrint
