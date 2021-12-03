# STM-Haskell
## 1. Introduction

### 1.1 Problem description - Concurrency

When several threads are executing asynchronously using shared resources, the order in which they do this affects the observable outcome. In contrast, in pure code the order in which functions are evaluated is irrelevant because the result will be the same. [3]

Concurrent access and independence of processes lead to the well-known problems of conflicting memory use and thus requires protection of critical sections to ensure mutual exclusion. Over the years several programming primitives like locks, semaphores, monitors, etc. have been introduced and used to ensure this atomicity of memory operations in a concurrent setting. However, the explicit use of locking mechanisms is error-prone – the programmer may omit to set or release a lock resulting in deadlocks or race conditions – and it is also often inefficient, since setting too many locks may sequentialise program execution and prohibit concurrent evaluation. Another obstacle of lock-based concurrency is that composing larger programs from smaller ones is usually impossible. [2]

### 1.2 STM Introduction

STM provides a safe way of accessing shared variables among concurrently running threads through the use of monads, allowing only I/O actions in the IO monad and STM actions in the STM monad. 

Programming using distinct STM and I/O actions ensures that only STM actions and pure computation can be performed within a memory transaction (which makes it possible to re-execute transactions transparently), whereas only I/O actions and pure computations, and not STM actions, can be performed outside a transaction. 

This guarantees that `TVars` cannot be modified without the protection of `atomically`, and thus separates the computations that have side-effects from the ones that are effect-free. [1]

STM guarantees:

- Atomicity: the effects of `atomically` act become visible to another thread all at once. For instance, on a bank transaction problem, this ensures that no other thread can see a state in which money has been deposited into but not yet withdrawn from it.
- Isolation: during a call `atomically` act, the action act is completely unaffected by other threads. It is as if act takes a snapshot of the state of the world when it begins running, and then executes against that snapshot. [4]

### 1.3 STM Operations

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/4fa2c464-1778-4f08-a39b-74e9bd7995f8/Untitled.png)

- `atomically` takes a memory transaction, of type STM a, and delivers an I/O action that, when performed, runs the transaction atomically with respect to all other memory transactions.
- The `retry` function allows possibly-blocking transactions to be composed in sequence. It is worth mentioning that the programmer does not have to identify the condition under which the transaction can run to completion: retry can occur anywhere within the transaction, blocking it until an alternative execution path becomes possible.
- `orElse` allows transactions to be composed as `alternatives`, so that the second is run if the first `retries`. This ability allows threads to wait for many things at once, like the Unix `select` system call – except that `orElse` composes well, whereas `select` does not.
- The transaction `s1 ‘orElse‘ s2` first runs s1; if it retries, then `s1` is abandoned with no effect, and `s2` is run. If `s2` retries as well, the entire call retries — but it waits on the variables read by either of the two nested transactions. Again, the programmer need know nothing about the enabling condition of `s1` and `s2`. [6]

## 2. Architecture of STM in Haskell

Since Haskell currently implements lazy conflict detection, when a transaction is finished it is validated by the runtime system that it was executed on a consistent system state, and that no other finished transaction may have modified relevant parts of this state in the meantime. In this case, the modifications of the transaction are committed, otherwise, they are discarded. The Haskell STM runtime maintains a list of accessed transactional variables for each transaction, where all the variables in this list which were written are called the “writeset” and all that were read are called the “readset” of the transaction. It is worth noticing that these two sets can (and usually do) overlap.

Operationally, `atomically` takes the tentative updates and applies them to the `TVars` involved, making these effects visible to other transactions. When `atomically` is invoked, this method deals with maintaining a per-thread transaction log that records the tentative accesses made to `TVars` during the “work phase” where the actual computational work takes place. Later in the “commit phase”, a global lock is acquired and the validation (first part of the two-phase commit) is performed: going through the readset checking each variable with its local original value that was obtained at the start of the transaction. If all `TVars` that are read are consistent, all new values are actually committed into the memory (the second part of the two-phase commit) and then the lock is released.

In case a concurrent transaction has committed conflicting updates, the writeback cannot be performed. Instead, the rollback mechanism takes place discarding the uncommitted intermediate values and restarting the execution. [1]

### Synopsis:

- Optimistic execution, like in a database.

When (`atomically act`) is performed:

- A thread-local transaction log is allocated, initially empty.
- Then the action `act` is performed, without taking any locks.
- While performing `act`, each call to `writeTVar` writes the address of the TVar and its new value into the log; it does not write to the `TVar` itself.
- Each call to `readTVar` first searches the log.
- When the action finishes the implementation first validates the log and, if validation is successful, commits the log (with locks or CAS or what have you).
- If validation fails,  we try the whole transaction again. [4]

### Analysis

The implementation technique that makes transactions viable is *optimistic concurrency*; that is, all transactions run to completion under the assumption that no conflicts have occurred, and only at the end of the transaction do we perform a consistency check, retrying the transaction from the start if a conflict has occurred. This is “optimistic” in the sense that it performs well if conflicts are rare, but poorly if they are common. If conflicts are common (many transactions modifying the same state), then optimistic concurrency can have worse performance that just sequentializing all the transactions using a single global lock. [5] 

There is an extensive research related with the performance of STM on `The limits of software transactional memory (STM) dissecting Haskell STM applications on a many-core environment` [1]

## References

[1] Perfumo, C., Sönmez, N., Stipic, S., Unsal, O., Cristal, A., Harris, T. and Valero, M., 2008, May. The limits of software transactional memory (STM) dissecting Haskell STM applications on a many-core environment. In *Proceedings of the 5th Conference on Computing Frontiers* (pp. 67-78).

[2] Schmidt-Schauß, M. and Sabel, D., 2013, September. Correctness of an STM Haskell implementation. In *Proceedings of the 18th ACM SIGPLAN International Conference on Functional programming* (pp. 161-172).

[3] MENA, A. S. (2019). *Practical Haskell: a real world guide to programming*. 

[4] O’Connor, L., Haskell/Concurrency Braindump.

[5] Sulzmann, M., Lam, E.S. and Marlow, S., 2009. Comparing the performance of concurrent linked-list implementations in Haskell. *ACM Sigplan Notices*, *44*(5), pp.11-20.

[6] Harris, T., Marlow, S., Peyton-Jones, S. and Herlihy, M., 2005, June. Composable memory transactions. In *Proceedings of the tenth ACM SIGPLAN symposium on Principles and practice of parallel programming* (pp. 48-60).
