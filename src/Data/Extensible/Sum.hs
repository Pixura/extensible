{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Data.Extensible.Sum
-- Copyright   :  (c) Fumiaki Kinoshita 2015
-- License     :  BSD3
--
-- Maintainer  :  Fumiaki Kinoshita <fumiexcel@gmail.com>
-- Stability   :  experimental
-- Portability :  non-portable
--
------------------------------------------------------------------------
module Data.Extensible.Sum (
   (:|)(..)
  , hoist
  , embed
  , strike
  , strikeAt
  , (<:|)
  , exhaust
  , picked
  ) where

import Data.Extensible.Internal
import Control.Applicative
import Data.Typeable

-- | The extensible sum type
data (h :: k -> *) :| (s :: [k]) where
  UnionAt :: !(Membership xs x) -> h x -> h :| xs
deriving instance Typeable (:|)

-- | Change the wrapper.
hoist :: (forall x. g x -> h x) -> g :| xs -> h :| xs
hoist f (UnionAt pos h) = UnionAt pos (f h)
{-# INLINE hoist #-}

-- | /O(1)/ lift a value.
embed :: (x ∈ xs) => h x -> h :| xs
embed = UnionAt membership
{-# INLINE embed #-}

strike :: forall h x xs. (x ∈ xs) => h :| xs -> Maybe (h x)
strike = strikeAt membership
{-# INLINE strike #-}

strikeAt :: forall h x xs. Membership xs x -> h :| xs -> Maybe (h x)
strikeAt q (UnionAt p h) = case compareMembership p q of
  Right Refl -> Just h
  _ -> Nothing
{-# INLINE strikeAt #-}

-- | /O(1)/ Naive pattern match
(<:|) :: (h x -> r) -> (h :| xs -> r) -> h :| (x ': xs) -> r
(<:|) r c = \(UnionAt pos h) -> runMembership pos
  (\Refl -> r h)
  (\pos' -> c (UnionAt pos' h))
infixr 1 <:|
{-# INLINE (<:|) #-}

-- | There is no empty union.
exhaust :: h :| '[] -> r
exhaust _ = error "Impossible"

-- | A traversal that tries to point a specific element.
picked :: forall f h x xs. (x ∈ xs, Applicative f) => (h x -> f (h x)) -> h :| xs -> f (h :| xs)
picked f u@(UnionAt pos h) = case compareMembership (membership :: Membership xs x) pos of
  Right Refl -> fmap (UnionAt pos) (f h)
  _ -> pure u
{-# INLINE picked #-}
