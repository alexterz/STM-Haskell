module TVarExample
    ( updateMoneyAndStockStm
    , getMoneyAndStockStm
    ) where

import           Control.Concurrent.STM


updateMoneyAndStockStm :: Eq a
                       => a
                       -> Integer
                       -> TVar Integer -- the money the Store has earned
                       -> TVar [(a,Integer)]  -- the current stock: a list of (item, quantity) tuples
                       -> STM ()
updateMoneyAndStockStm product price money stock = do s <- readTVar stock
                                                      let Just productNo = lookup product s
                                                      if productNo > 0
                                                      then do m <- readTVar money
                                                              let newS = map (\(k,v) -> if k == product
                                                                                          then (k,v-1)
                                                                                          else (k,v)) s
                                                              writeTVar money (m + price) >> writeTVar stock newS
                                                      else return ()

getMoneyAndStockStm :: Show a => TVar Integer -> TVar [(a,Integer)] -> STM (Integer , [(a,Integer)])
getMoneyAndStockStm money stock = do m <- readTVar money
                                     s <- readTVar stock
                                     return (m, s)
