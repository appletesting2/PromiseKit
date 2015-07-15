import Foundation.NSProgress

private func when<T>(promises: [Promise<T>]) -> Promise<Void> {
    let (rootPromise, fulfill, reject) = Promise<Void>.pendingPromise()
#if !PMKDisableProgress
    let progress = NSProgress(totalUnitCount: Int64(promises.count))
    progress.cancellable = false
    progress.pausable = false
#else
    var progress: (completedUnitCount: Int, totalUnitCount: Int) = (0, 0)
#endif
    var countdown = promises.count
    if countdown == 0 {
        fulfill()
    }

    for promise in promises {
        promise.pipe { resolution in
            if rootPromise.pending {
                switch resolution {
                case .Rejected(let error):
                    progress.completedUnitCount = progress.totalUnitCount
                    //TODO PMKFailingPromiseIndexKey
                    reject(error)
                case .Fulfilled:
                    progress.completedUnitCount++
                    if --countdown == 0 {
                        fulfill()
                    }
                }
            }
        }
    }

    return rootPromise
}

/**
 Wait for all promises in a set to resolve.

 For example:

     when(promise1, promise2).then { results in
        //…
     }

 - Warning: If *any* of the provided promises reject, the returned promise is immediately rejected with that promise’s rejection. The error’s `userInfo` object is supplemented with `PMKFailingPromiseIndexKey`.
 - Warning: In the event of rejection the other promises will continue to resolve and, as per any other promise, will either fulfill or reject. This is the right pattern for `getter` style asynchronous tasks, but often for `setter` tasks (eg. storing data on a server), you most likely will need to wait on all tasks and then act based on which have succeeded and which have failed, in such situations use `join`.
 - Parameter promises: The promies upon which to wait before the returned promise resolves.
 - Returns: A new promise that resolves when all the provided promises fulfill or one of the provided promises rejects.
 - SeeAlso: `join()`
*/
public func when<T>(promises: [Promise<T>]) -> Promise<[T]> {
    return when(promises).then(on: zalgo) { promises.map{ $0.value! } }
}

public func when<T>(promises: Promise<T>...) -> Promise<[T]> {
    return when(promises)
}

public func when(promises: Promise<Void>...) -> Promise<Void> {
    return when(promises)
}

public func when<U, V>(pu: Promise<U>, _ pv: Promise<V>) -> Promise<(U, V)> {
    return when(pu.asVoid(), pv.asVoid()).then(on: zalgo) { (pu.value!, pv.value!) }
}

public func when<U, V, X>(pu: Promise<U>, _ pv: Promise<V>, _ px: Promise<X>) -> Promise<(U, V, X)> {
    return when(pu.asVoid(), pv.asVoid(), px.asVoid()).then(on: zalgo) { (pu.value!, pv.value!, px.value!) }
}

@available(*, unavailable, message="Use `when`")
public func join<T>(promises: Promise<T>...) {}