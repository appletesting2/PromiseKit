---
category: home
layout: default
---

# Troubleshooting

There are a few common issues that come up when using PromiseKit:


## 1. Unexpected Continuation

Not returning from a catch will resolve that promise `nil` and continue. For example:

{% highlight objectivec %}
self.somePromise.catch(^(NSError *err){
    [UIAlertView show:err];
}).then(^(id o){
    // this block always executes!
    assert(o == nil);
})
{% endhighlight %}

This is a rigid adherance to Promises/A+, however we are [considering changing](https://github.com/mxcl/PromiseKit/issues/62) it to “rethrow” the error.

Really though, this is bad chain design. Probably what you wanted was to nest the chains. Sometimes rightward-drift is *correct* and makes the code clearer.


## 2. `EXC_BAD_ACCESS`

Something got deallocated, and you still used it as part of your promise chain.

When wrapping delegate patterns, the delegate property is usually `assign` which means if nothing else points to it, it will be deallocated immediately. The block-heavy nature of promises can easily lead to this situation, so it is something to be aware of.


## 3. `Return type must match previous return type`

If Xcode complains in this manner, your code is likely something like:

{% highlight objectivec %}

[self myPromise].then(^{
    if (foo) {
        return @1;
    } else {
        return [NSError …];
    }
});

{% endhighlight %}

You need to change the return type of your block. Clang is smart, but only so far, usually in this context it determines the return type for the block automatically. But when the return types are different, it refuses. Thus:

{% highlight objectivec %}

[self myPromise].then(^id{
    if (foo) {
        return @1;
    } else {
        return [NSError …];
    }
});

{% endhighlight %}

You see the `id` after the `^` and before the `{`? That’s the fix.


## 4. Chaining Doesn’t Seem To Work

{% highlight objectivec %}
foo.then(^{
    [self promise];
}).then(^{
    NSLog(@"Happens immediately! WTF?!");
});
{% endhighlight %}

This happens because you didn’t *return* the promise. We can’t know you mean to
wait on the promise before executing the next `then`.

{% highlight objectivec %}
foo.then(^{
    return [self promise];
}).then(^{
    NSLog(@"Happens once [self promise] finishes :)");
});
{% endhighlight %}

With Swift especially there seems to be a compiler bug where this is possible:

{% highlight swift %}
foo.then { _ -> Void in
    return promise()
}.then { _ in
    NSLog("Happens immediately! But why?!")
}
{% endhighlight %}

We return the promise *but*! The closure has been specified as `Void` return type. Swift seems to respect the `Void` return rather than have a compile error, meaning the promise is not inserted into the chain.


<div><a class="pagination" href="/common-misusage">Next: Common Misusage</a></div>
