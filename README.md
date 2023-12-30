# TL;DR

A minimal benchmark library.

## TODO:

- The current implementation uses `std.time.Timer` for the measurement. It's not 100% clear what happens if the current thread gets suspended and resumes later at some point. Will the Timer's monotonic clock skip the ideal time or include it with the measurement?

- For some reason, explicit measurement with `ready()` took longer than the `run()`. Might be additional overhead from `start()` and `stop()`. Nevertheless figure out what's causing this delay! 
    - It's the overhead for sure! and the ctx itself taking majority of the times for simple `add(10, 20)`. Figure out how to eliminate this time.

- Suspend and resume `start()` and `stop()` **n** amount of times in real code to benchmark a non-contagious code block.

## Examples

```zig
const snail = @import("snail.zig");

pub fn main() void {
    // With default code iteration
    snail.benchmark("addition", measure_add, null);
    snail.benchmark("addition", measure_add_explicit, null);

    // With manual code iteration
    snail.benchmark("addition", measure_add, 1000);
    snail.benchmark("addition", measure_add_explicit, 1000);
}


fn add(x: i32, y: i32) i32 {
    return x + y;
}

fn measure_add(ctx: *snail.Context) void {
    while (ctx.run()) {
        _ = add(56, 44);
    }
}

fn measure_add_explicit(ctx: *snail.Context) void {
    while (ctx.ready()) {
        ctx.start();
        defer ctx.stop()
        _ = add(56, 44);
    }
}
```
