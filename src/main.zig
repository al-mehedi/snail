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
        defer ctx.stop();
        _ = add(56, 44);
    }
}