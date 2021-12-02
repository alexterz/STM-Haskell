module RollBackTransaction
    ( payByCard
    , payByCardWithTVar
    , payWithBitCoinsWithExtraCharge
    ) where

import           Control.Concurrent.STM
import           Data.Algebra.Boolean
import           TVarExample

payByCard :: Eq a => a -> Integer -> TVar Integer -> TVar [(a,Integer)] -> Bool -> STM ()
payByCard product price money stock isCardSystemWorking =
    if isCardSystemWorking -- if isCardSystemWorking was a TVar Bool
    then updateMoneyAndStockStm product price money stock
    else retry

-- change the condition triggering the update.
payByCardWithTVar :: Eq a => a -> Integer -> TVar Integer -> TVar [(a,Integer)] -> TVar Bool -> STM ()
payByCardWithTVar product price money stock previousCardRes =
  do prevTrans <- readTVar previousCardRes
     if prevTrans -- if isCardSystemWorking was a TVar Bool
     then updateMoneyAndStockStm product price money stock
     else retry

payWithBitCoinsWithExtraCharge :: Eq a => a -> Integer -> TVar Integer -> TVar [(a,Integer)] -> STM ()
payWithBitCoinsWithExtraCharge product price money stock =
      updateMoneyAndStockStm product (price + 10) money stock
