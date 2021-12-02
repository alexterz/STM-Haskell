module MVarExample2
    ( updateMoneyAndStock
    , printMoneyAndStock
    ) where

{-- Concurrent senarios:

        1) updateMoneyAndStock threads takes the stock variable and then printMoneyAndStock threads get access to the money variable.
           At this point, the whole execution is blocked; the updater thread must be blocked because it cannot get the ownership of the money variable,
           and the printer thread cannot continue because of denial of access to stock. This is an archetypical instance of deadlocking.

        2) Two updater threads, U1 and U2, and one reader thread called R. It is possible that U1 updates the money variable and
           immediately afterward R reads that variable, obtaining the money after selling the item in U1.
           However, afterwards U1 can proceed, and the whole U2 is executed as well.
           By that time, the stock variable will contain the changes of both U1 and U2,
           and R will get stock information that is not consistent with the value it got from money.
           In this case, the problem is that a thread can get an inconsistent view of the world.
--}

import           Control.Concurrent

updateMoneyAndStock :: Eq a
                    => a
                    -> Integer
                    -> MVar Integer -- the money the Store has earned
                    -> MVar [(a,Integer)]  -- the current stock: a list of (item, quantity) tuples
                    -> IO ()
updateMoneyAndStock product price money stock = do s <- takeMVar stock
                                                   let Just productNo = lookup product s
                                                   if productNo > 0
                                                   then do m <- takeMVar money
                                                           let newS = map (\(k,v) -> if k == product
                                                                                     then (k,v-1)
                                                                                     else (k,v)) s
                                                           putMVar money (m + price) >> putMVar stock newS
                                                   else putMVar stock s


printMoneyAndStock :: Show a => MVar Integer -> MVar [(a,Integer)] -> IO ()
printMoneyAndStock money stock = do m <- readMVar money
                                    s <- readMVar stock
                                    putStrLn $ show m ++ "\n" ++ show s
