{-# LANGUAGE DataKinds, PolyKinds
    , TypeFamilies, TypeOperators
    , GADTs
    , FlexibleInstances, FlexibleContexts #-} --, KindSignatures, ConstraintKinds #-}

module Edis.Dict where

import GHC.TypeLits
import Data.Proxy

--------------------------------------------------------------------------------
--  Maybe
--------------------------------------------------------------------------------

--  FromJust : (Maybe k) -> k
type family FromJust (x :: Maybe k) :: k where
    FromJust (Just k) = k

-- fromJustEx0 :: (FromJust (Just Int) ~ Int) => ()
-- fromJustEx0 = ()
--
-- fromJustEx1 :: (FromJust Nothing ~ Int) => ()
-- fromJustEx1 = ()

--------------------------------------------------------------------------------
--  Dictionary Membership
--------------------------------------------------------------------------------

-- Member :: Key -> [ (Key, Type) ] -> Bool
type family Member (s :: Symbol) (xs :: [ (Symbol, *) ]) :: Bool where
    Member s '[]             = False
    Member s ('(s, x) ': xs) = True
    Member s ('(t, x) ': xs) = Member s xs

-- memberEx0 :: (Member "C" '[] ~ False) => ()
-- memberEx0 = ()
--
-- memberEx1 :: (Member "A" '[ '("A", Char), '("B", Int) ] ~ True) => ()
-- memberEx1 = ()
--
-- memberEx2 :: (Member "C" '[ '("A", Char), '("B", Int) ] ~ False) => ()
-- memberEx2 = ()

--------------------------------------------------------------------------------
--  Dictionary Lookup
--------------------------------------------------------------------------------

-- type family Get' (s :: Symbol) (xs :: [ (Symbol, *) ]) :: * where
--     Get' s ('(s, x) ': xs) = x
--     Get' s ('(t, x) ': xs) = Get' s xs
--
-- getEx0' :: (Get' "A" '[ '("A", Char), '("B", Int) ] ~ Char) => ()
-- getEx0' = ()
--
-- getEx1' :: (Get' "C" '[ '("A", Char), '("B", Int) ] ~ Char) => ()
-- getEx1' = ()

-- Get :: Key -> [ (Key, Type) ] -> Maybe Type
type family Get (s :: Symbol) (xs :: [ (Symbol, *) ]) :: Maybe * where
    Get s '[]             = Nothing
    Get s ('(s, x) ': xs) = Just x
    Get s ('(t, x) ': xs) = Get s xs

-- getEx0 :: (Get "A" '[ '("A", Char), '("B", Int) ] ~ Just Char) => ()
-- getEx0 = ()
--
-- getEx1 :: (Get "C" '[ '("A", Char), '("B", Int) ] ~ Nothing) => ()
-- getEx1 = ()


--------------------------------------------------------------------------------
--  Dictionary Set
--------------------------------------------------------------------------------

-- Set :: Key -> Type -> [ (Key, Type) ] -> [ (Key, Type) ]
type family Set (s :: Symbol) (x :: *) (xs :: [ (Symbol, *) ]) :: [ (Symbol, *) ] where
    Set s x '[]             = '[ '(s, x) ]
    Set s x ('(s, y) ': xs) = ('(s, x) ': xs)
    Set s x ('(t, y) ': xs) = '(t, y) ': (Set s x xs)

-- setEx0 :: (Set "A" Char '[] ~ '[ '("A", Char) ]) => ()
-- setEx0 = ()
--
-- setEx1 :: (Set "A" Bool '[ '("A", Char) ] ~ '[ '("A", Bool) ]) => ()
-- setEx1 = ()

--------------------------------------------------------------------------------
--  Dictionary Deletion
--------------------------------------------------------------------------------

-- Del :: Key -> [ (Key, Type) ] -> [ (Key, Type) ]
type family Del (s :: Symbol) (xs :: [ (Symbol, *) ]) :: [ (Symbol, *) ] where
    Del s ('(s, y) ': xs) = xs
    Del s ('(t, y) ': xs) = '(t, y) ': (Del s xs)

-- delEx0 :: (Del "A" '[ '("A", Char) ] ~ '[]) => ()
-- delEx0 = ()
--
-- delEx1 :: (Del "A" '[ '("B", Int), '("A", Char) ] ~ '[ '("B", Int) ]) => ()
-- delEx1 = ()
