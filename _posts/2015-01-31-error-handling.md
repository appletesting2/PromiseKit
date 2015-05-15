---
category: docs
layout: default
---

# Error Handling. Like a Boss.

Error handling is notoriously hard; asynchronous error handling can be downright outrageous. The result is a shameful number of unhandled errors in modern codebases.

{% highlight objectivec %}
void (^errorHandler)(NSError *) = ^(NSError *error) {
    [[UIAlertView …] show];
};
[NSURLConnection sendAsynchronousRequest:rq queue:q completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
    if (connectionError) {
        errorHandler(connectionError);
    } else {
        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
            errorHandler(jsonError);
        } else {
            id rq = [NSURLRequest requestWithURL:[NSURL URLWithString:json[@"avatar_url"]]];
            [NSURLConnection sendAsynchronousRequest:rq queue:q completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                UIImage *image = [UIImage imageWithData:data];
                if (!image) {
                    errorHandler(nil); // NSError TODO!
                } else {
                    self.imageView.image = image;
                }
            }];
        }
    }
}];
{% endhighlight %}

This isn't even a complicated example.

Promises streamline error handling:

{% highlight objectivec %}
[NSURLConnection GET:url].then(^(NSDictionary *json){
    return [NSURLConnection GET:json[@"avatar_url"]];
}).then(^(UIImage *image){
    self.imageView.image = image;
}).catch(^(NSError *error){
    [[UIAlertView …] show];
})
{% endhighlight %}

This is a somewhat unfair example: PromiseKit’s `NSURLConnection` category detects the JSON and the image HTTP responses and automatically decode them for you (with thoroughly filled `NSError` objects). But the key here is that any errors that happen anywhere in the chain propogate to the error handler skipping any intermediary `then` handlers.

It’s important to remember that in order for your errors to propogate they must occur in the chain. **If you don’t return your promise, thus inserting it into the chain, the error won’t propogate**.

PromiseKit has an additional bonus: unhandled errors (ie. errors that never get handled in a `catch`) are logged. If you like, we even provide [a mechanism][ueh] to execute your own code whenever errors are not caught.

<aside>Even exceptions are caught during Promise execution and will cause the nearest catch handler to execute. When this happens the resulting <code>NSError</code> will have its localizedDescription set to the exception’s description. The thrown object will be stored in the error’s <code>userInfo</code> under <code>PMKUnderlyingExceptionKey</code>.<br><br>The reason we do this is so you have an opportunity to recover. An exception that occurs in an asynchronous task is usually specific to that task, you can recover and you don’t have to crash. If the exception was just thrown you wouldn't be able to <code>@catch</code> it since it is outside your control. If you still want to crash, you can rethrow exceptions in your catch handler, and to catch unhandled errors implement <code>PMKUnhandlerErrorHandler</code>.<br><br>Our recommendation however is: enjoy the additional stability promises provide. Chain all your promises so any errors or exceptions will halt the flow of the task the chain represents. Errors will naturally halt sequences of logic so you don't have to worry about your state machine’s integrity.</aside>

<aside>PromiseKit cannot catch exceptions thrown in other threads even if they were spawned inside handlers, even if the throw happens from a nested block inside a PromiseKit handler. If you have such situations, consider <code>dispatch_promise</code> or wrapping more of your asynchronous systems in other promises.</aside>

<div><a class="pagination" href="/when">Next: `when`</a></div>

[ueh]: https://github.com/mxcl/PromiseKit/blob/master/Sources/ErrorUnhandler.swift#L20