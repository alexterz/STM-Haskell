module Main where

import           Control.Concurrent
import           Control.Concurrent.STM
import           Control.Monad
import           MVarExample
import           MVarExample2
import           RollBackTransaction
import           System.Random
import           TVarExample

-- MVarExample

main :: IO ()
main = do v <- newMVar 10000
          forkDelay 5 $ updateMoney v
          forkDelay 5 $ readMoney v
          _ <- getLine
          return ()

-- MVarExample2 - Race condition and deadlock example

-- main :: IO ()
-- main = do v <- newMVar 10000
--           s <- newMVar [("a",7)]
--           forkDelay 5 $ updateMoneyAndStock "a" 1000 v s
--           forkDelay 5 $ printMoneyAndStock v s
--           _ <- getLine  -- to wait for completion
--           return ()


-- TVarExample -- random printing, data consistency

-- main :: IO ()
-- main = do v <- newTVarIO 10000
--           s <- newTVarIO [("a",7)]
--           forkDelay 5 $ atomically $ updateMoneyAndStockStm "a" 1000 v s
--           forkDelay 5 $ do (money, stock) <- atomically $ getMoneyAndStockStm v s
--                            putStrLn $ show money ++ ", " ++ show stock
--           _ <- getLine -- to wait for completion
--           return ()

-- TVarExample -- STM composition, sequencial printing (?), data consistency

-- main :: IO ()
-- main = do v <- newTVarIO 10000
--           s <- newTVarIO [("a",7)]
--           forkDelay 5 $ do (money, stock) <- atomically $
--                                                 do updateMoneyAndStockStm "a" 1000 v s
--                                                    getMoneyAndStockStm v s
--                            putStrLn $ show money ++ ", " ++ show stock
--           _ <- getLine -- to wait for completion
--           return ()

-- Roll Back Example -retry

-- main :: IO ()
-- main = do v <- newTVarIO 10000
--           s <- newTVarIO [("a",7)]
--           forkDelay 5 $ do isWorking <- isCardSystemWorking
--                            (money, stock) <- atomically $
--                                                 do payByCard "a" 1000 v s isWorking
--                                                    getMoneyAndStockStm v s
--                            putStrLn $ show money ++ ", " ++ show stock
--           _ <- getLine -- to wait for completion
--           return ()

-- Roll Back Example - Compose transactions with alternatives

-- main :: IO ()
-- main = do v <- newTVarIO 10000
--           s <- newTVarIO [("a",7)]
--           b <- newTVarIO True
--           forkDelay 5 $ do isWorking <- isCardSystemWorking
--                            (money, stock) <- atomically $
--                                                 do orElse (payByCard "a" 1000 v s isWorking) (payWithBitCoinsWithExtraCharge "a" 1000 v s)
--                                                    getMoneyAndStockStm v s
--                            putStrLn $ show money ++ ", " ++ show stock
--           _ <- getLine -- to wait for completion
--           return ()

-- Roll Back Example - Testing retry under mutable condition -- fails, why?

-- main :: IO ()
-- main = do v <- newTVarIO 10000
--           s <- newTVarIO [("a",7)]
--           b <- newTVarIO True
--           forkDelay 5 $ do isWorking <- isCardSystemWorking
--                            (money, stock) <- atomically $
--                                                 do (payByCardWithTVar "a" 1000 v s isWorking b)
--                                                    getMoneyAndStockStm v s
--                            putStrLn $ show money ++ ", " ++ show stock
--           _ <- getLine -- to wait for completion
--           return ()

randomDelay :: IO ()
randomDelay = do r <- randomRIO (3, 15)
                 threadDelay (r * 1000000)

forkDelay :: Int -> IO () -> IO ()
forkDelay n f = replicateM_ n $ forkIO (randomDelay >> f)

-- code to check card system status omitted is substituted by a random Bool Generator
isCardSystemWorking :: IO Bool
isCardSystemWorking = do r <- randomRIO (1, 2)
                         return $ odd (r :: Int)
