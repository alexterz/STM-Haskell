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

-- change the condition triggering the update. Fails to rerun the transaction, why??
payByCardWithTVar :: Eq a => a -> Integer -> TVar Integer -> TVar [(a,Integer)] -> Bool -> TVar Bool -> STM ()
payByCardWithTVar product price money stock randomBool previousCardRes =
  do prevTrans <- readTVar previousCardRes
     let isCardSystemWorking = xor randomBool prevTrans -- generates a random var using a random generator and the TVar of the previous transaction
     if isCardSystemWorking -- if isCardSystemWorking was a TVar Bool
     then updateMoneyAndStockStm product price money stock
     else do writeTVar previousCardRes isCardSystemWorking
             retry

payWithBitCoinsWithExtraCharge :: Eq a => a -> Integer -> TVar Integer -> TVar [(a,Integer)] -> STM ()
payWithBitCoinsWithExtraCharge product price money stock =
      updateMoneyAndStockStm product (price + 10) money stock
