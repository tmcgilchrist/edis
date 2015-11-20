module Edis (
        module Edis.Promoted
    ,   Proxy(..)
    ,   Edis(..)
    ,   IMonad(..)
    ,   ListOf(..)
    ,   SetOf(..)
    ,   HashOf(..)
    ,   (>>>)

    -- ,   Status(..)
    ,   Redis.Reply
    ,   Redis.runRedis
    ,   Redis.connect
    ,   Redis.defaultConnectInfo
    ) where

import qualified Database.Redis as Redis
import Data.Proxy
import Edis.Type
import Edis.Promoted
