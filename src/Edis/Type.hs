{-# LANGUAGE DeriveGeneric, DeriveDataTypeable
    , GADTs, RankNTypes
    , DataKinds, PolyKinds
    , TypeFamilies #-}

module Edis.Type where

import           Edis.Serialize
import           GHC.TypeLits

import           Database.Redis (Reply(..), Redis)
import qualified Database.Redis as Redis

--------------------------------------------------------------------------------
--  Maybe
--------------------------------------------------------------------------------

--  FromJust : (Maybe k) -> k
type family FromJust (x :: Maybe k) :: k where
    FromJust (Just k) = k

--------------------------------------------------------------------------------
--  Dictionary Membership
--------------------------------------------------------------------------------

-- Member :: Key -> [ (Key, Type) ] -> Bool
type family Member (xs :: [ (Symbol, *) ]) (s :: Symbol) :: Bool where
    Member '[]             s = False
    Member ('(s, x) ': xs) s = True
    Member ('(t, x) ': xs) s = Member xs s

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
type family Get (xs :: [ (Symbol, *) ]) (s :: Symbol) :: Maybe * where
    Get '[]             s = Nothing
    Get ('(s, x) ': xs) s = Just x
    Get ('(t, x) ': xs) s = Get xs s


-- getEx0 :: (Get "A" '[ '("A", Char), '("B", Int) ] ~ Just Char) => ()
-- getEx0 = ()
--
-- getEx1 :: (Get "C" '[ '("A", Char), '("B", Int) ] ~ Nothing) => ()
-- getEx1 = ()


--------------------------------------------------------------------------------
--  Dictionary Set
--------------------------------------------------------------------------------

-- Set :: Key -> Type -> [ (Key, Type) ] -> [ (Key, Type) ]
type family Set (xs :: [ (Symbol, *) ]) (s :: Symbol) (x :: *) :: [ (Symbol, *) ] where
    Set '[]             s x = '[ '(s, x) ]
    Set ('(s, y) ': xs) s x = ('(s, x) ': xs)
    Set ('(t, y) ': xs) s x = '(t, y) ': (Set xs s x)

-- setEx0 :: (Set "A" Char '[] ~ '[ '("A", Char) ]) => ()
-- setEx0 = ()
--
-- setEx1 :: (Set "A" Bool '[ '("A", Char) ] ~ '[ '("A", Bool) ]) => ()
-- setEx1 = ()

--------------------------------------------------------------------------------
--  Dictionary Deletion
--------------------------------------------------------------------------------

-- Del :: Key -> [ (Key, Type) ] -> [ (Key, Type) ]
type family Del (xs :: [ (Symbol, *) ]) (s :: Symbol) :: [ (Symbol, *) ] where
    Del '[] s             = '[]
    Del ('(s, y) ': xs) s = xs
    Del ('(t, y) ': xs) s = '(t, y) ': (Del xs s)

-- delEx0 :: (Del "A" '[ '("A", Char) ] ~ '[]) => ()
-- delEx0 = ()
--
-- delEx1 :: (Del "A" '[ '("B", Int), '("A", Char) ] ~ '[ '("B", Int) ]) => ()
-- delEx1 = ()

--------------------------------------------------------------------------------
--  P
--------------------------------------------------------------------------------

class PMonad m where
    unit :: a -> m p p a
    bind :: m p q a -> (a -> m q r b) -> m p r b

data P p q a = P { unP :: Redis a }

instance PMonad P where
    unit = P . return
    bind m f = P (unP m >>= unP . f )

infixl 1 >>>

-- Kleisli arrow
(>>>) :: PMonad m => m p q a -> m q r b -> m p r b
a >>> b = bind a (const b)

--------------------------------------------------------------------------------
--  Redis Data Types (and Kinds)
--------------------------------------------------------------------------------

data NoneK :: * -> *
data StringK :: * -> *
data HashK :: [ (Symbol, *) ] -> *
data ListK :: * -> *
data SetK :: * -> *
data ZSetK :: * -> *


--------------------------------------------------------------------------------
--  Redis Data Type
--------------------------------------------------------------------------------

type family RType (x :: *) :: Redis.RedisType where
    RType (HashK n) = Redis.Hash
    RType (ListK n) = Redis.List
    RType (SetK n) = Redis.Set
    RType (ZSetK n) = Redis.ZSet
    RType x = Redis.String

type family IsHash (x :: *) :: Bool where
    IsHash (HashK n) = True
    IsHash x         = False

type family IsList (x :: *) :: Bool where
    IsList (ListK n) = True
    IsList x         = False

type family IsSet (x :: *) :: Bool where
    IsSet (SetK n) = True
    IsSet x        = False

type family IsZSet (x :: *) :: Bool where
    IsZSet (ZSetK n) = True
    IsZSet x         = False


type family HGet (xs :: *) (s :: Symbol) :: Maybe * where
    HGet (HashK xs) s = Get xs s
--
-- type HGET xs k f = HGet (FromJust (Get xs k)) f

-- type family HSet (xs :: *) (s :: Symbol) (x :: *) :: * where
--     HSet (HashK xs) s x = HashK (Set xs s x)

type family GetHash (xs :: [ (Symbol, *) ]) (k :: Symbol) (f :: Symbol) :: Maybe * where
    GetHash '[]                    k f = Nothing
    GetHash ('(k, HashK hs) ': xs) k f = Get hs f
    GetHash ('(k, x       ) ': xs) k f = Nothing
    GetHash ('(l, y       ) ': xs) k f = GetHash xs k f

type family SetHash (xs :: [ (Symbol, *) ]) (k :: Symbol) (f :: Symbol) (x :: *) :: [ (Symbol, *) ] where
    SetHash '[]                    k f x = '(k, HashK (Set '[] f x)) ': '[]
    SetHash ('(k, HashK hs) ': xs) k f x = '(k, HashK (Set hs  f x)) ': xs
    SetHash ('(l, y       ) ': xs) k f x = '(l, y                  ) ': SetHash xs k f x

type family DelHash (xs :: [ (Symbol, *) ]) (k :: Symbol) (f :: Symbol) :: [ (Symbol, *) ] where
    DelHash '[]                    k f = '[]
    DelHash ('(k, HashK hs) ': xs) k f = '(k, HashK (Del hs f )) ': xs
    DelHash ('(l, y       ) ': xs) k f = '(l, y                ) ': DelHash xs k f

type family MemHash (xs :: [ (Symbol, *) ]) (k :: Symbol) (f :: Symbol) :: Bool where
    MemHash '[]                    k f = False
    MemHash ('(k, HashK hs) ': xs) k f = Member hs f
    MemHash ('(k, x       ) ': xs) k f = False
    MemHash ('(l, y       ) ': xs) k f = MemHash xs k f

-- type family HDel (xs :: *) (s :: Symbol) :: * where
--     HDel (HashK xs) s = HashK (Del xs s)
