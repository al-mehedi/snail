//! # A minimal benchmark library

const std = @import("std");

const time = std.time;
const Timer = time.Timer;
const CallModifier = std.builtin.CallModifier;

/// Benchmark function wrapper
const Bfn = *const fn (*Context) void;

pub const Context = struct {
    timer: Timer,
    count: u64,
    limit: u64,
    state: State,
    tspan: u64,

    const cache_hit = time.ns_per_ms;  // Approximation for CPU cache to be hot

    const State = enum {
        None,
        Heating,
        Running,
        Finished,
    };

    /// Run count (`rc`) sets the limit for code ietration.
    /// i.e., `1000` will execute benchmark code for thousand times.
    fn init(rc: u64) Context {
        return .{
            .timer = Timer.start() catch @panic("System clock is unavailable!"),
            .count = 0,
            .limit = rc,
            .state = .None,
            .tspan = 0
        };
    }

    pub fn run(self: *Context) bool {
        switch (self.state) {
            .None => {
                self.state = .Heating;
                self.timer.reset();
                return true;
            },
            .Heating => {
                const elapsed = self.timer.read();
                if (elapsed >= cache_hit) {
                    self.state = .Running;
                    self.timer.reset();
                }

                return true;
            },
            .Running => {
                if (self.count < self.limit) {
                    self.count += 1;
                    return true;
                } else {
                    self.tspan = self.timer.read();
                    self.state = .Finished;
                    return false;
                }
            },
            .Finished => unreachable,
        }
    }

    /// Allows timer to be handled explicitly.
    /// Use `start()` and `stop()` methods for this.
    pub fn ready(self: *Context) bool {
        switch (self.state) {
            .None => {
                self.state = .Heating;
                return true;
            },
            .Heating => {
                if (self.tspan >= cache_hit) { self.state = .Running; }
                return true;
            },
            .Running => {
                if (self.count < self.limit) {
                    self.count += 1;
                    return true;
                } else {
                    self.state = .Finished;
                    return false;
                }
            },
            .Finished => unreachable,
        }
    }

    /// Starts the timer.
    /// Only use with `ready()`.
    pub fn start(self: *Context) void {
        self.timer.reset();
    }

    /// Stops the timer.
    /// Only use with `ready()`.
    pub fn stop(self: *Context) void {
        self.tspan += self.timer.read();
    }

    fn averageTime(self: *Context, unit: u64) f32 {
        std.debug.assert(self.state == .Finished);
        const duration = @as(f32, @floatFromInt(self.tspan / unit));
        const count = @as(f32, @floatFromInt(self.count));
        return duration / count;
    }
};


/// Run count (`rc`) sets the limit for code ietration.
/// i.e., `1000` will execute benchmark code for thousand times.
/// When `null` the default value of `rc` will be `1_000_000`.
pub fn benchmark(comptime name: []const u8, bfn: Bfn, rc: ?u64) void {
    var ctx = if (rc) |val| Context.init(val) else Context.init(1_000_000);
    @call(CallModifier.never_inline, bfn, .{&ctx});

    var unit: u64 = undefined;
    var unit_name: []const u8 = undefined;
    const avg_time = ctx.averageTime(1);
    std.debug.assert(avg_time >= 0);

    if (avg_time <= time.ms_per_s) {
        unit = 1;
        unit_name = "ns";
    } else if (avg_time <= time.ms_per_s) {
        unit = time.us_per_min;
        unit_name = "us";
    } else {
        unit = time.ms_per_s;
        unit_name = "ms";
    }

    std.log.info(
        \\
        \\  Benchmark:    {s}
        \\  Iterations:   {d}
        \\  Average Time: {d:.3} {s}
        \\
        ,.{name, ctx.count, ctx.averageTime(unit), unit_name}
    );
}