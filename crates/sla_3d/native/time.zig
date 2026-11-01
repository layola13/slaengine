const std = @import("std");


const NS_PER_SEC: u64 = 1_000_000_000;
const DEFAULT_WRAP_PERIOD_NS: u64 = 3600 * NS_PER_SEC;
const FIXED_DEFAULT_TIMESTEP_NS: u64 = 15_625_000;
const U32_MAX_AS_U64: u64 = 0xffff_ffff;

pub const TimeClockNative = extern struct {
    wrap_period_ns: u64,
    delta_ns: u64,
    elapsed_ns: u64,
    elapsed_wrapped_ns: u64,
};

pub const TimerNative = extern struct {
    duration_ns: u64,
    elapsed_ns: u64,
    mode: u32,
    finished: u32,
    times_finished_this_tick: u32,
    paused: u32,
};

pub const FixedTimeNative = extern struct {
    timestep_ns: u64,
    overstep_ns: u64,
    delta_ns: u64,
    elapsed_ns: u64,
    step_index: u64,
};

pub export fn sa3d_time_clock_init(out: *TimeClockNative) callconv(.c) void {
    out.* = .{
        .wrap_period_ns = DEFAULT_WRAP_PERIOD_NS,
        .delta_ns = 0,
        .elapsed_ns = 0,
        .elapsed_wrapped_ns = 0,
    };
}

pub export fn sa3d_time_clock_set_wrap_period(out: *TimeClockNative, wrap_period_ns: u64) callconv(.c) u32 {
    if (wrap_period_ns == 0) return 1;
    out.wrap_period_ns = wrap_period_ns;
    return 0;
}

pub export fn sa3d_time_clock_advance_by(out: *TimeClockNative, delta_ns: u64) callconv(.c) void {
    out.delta_ns = delta_ns;
    out.elapsed_ns +%= delta_ns;
    out.elapsed_wrapped_ns = out.elapsed_ns % out.wrap_period_ns;
}

pub export fn sa3d_time_clock_advance_to(out: *TimeClockNative, elapsed_ns: u64) callconv(.c) u32 {
    if (elapsed_ns < out.elapsed_ns) return 1;
    sa3d_time_clock_advance_by(out, elapsed_ns - out.elapsed_ns);
    return 0;
}

pub export fn sa3d_timer_native_init(out: *TimerNative, duration_ns: u64, mode: u32) callconv(.c) void {
    out.* = .{
        .duration_ns = duration_ns,
        .elapsed_ns = 0,
        .mode = mode,
        .finished = 0,
        .times_finished_this_tick = 0,
        .paused = 0,
    };
}

pub export fn sa3d_timer_native_pause(out: *TimerNative) callconv(.c) void {
    out.paused = 1;
}

pub export fn sa3d_timer_native_unpause(out: *TimerNative) callconv(.c) void {
    out.paused = 0;
}

pub export fn sa3d_timer_native_reset(out: *TimerNative) callconv(.c) void {
    out.elapsed_ns = 0;
    out.finished = 0;
    out.times_finished_this_tick = 0;
}

pub export fn sa3d_timer_native_tick(out: *TimerNative, delta_ns: u64) callconv(.c) u32 {
    if (out.paused != 0) {
        out.times_finished_this_tick = 0;
        if (out.mode == 1) out.finished = 0;
        return out.times_finished_this_tick;
    }

    if (out.mode != 1 and out.finished != 0) {
        out.times_finished_this_tick = 0;
        return out.times_finished_this_tick;
    }

    out.elapsed_ns +%= delta_ns;
    out.finished = if (out.elapsed_ns >= out.duration_ns) 1 else 0;

    if (out.finished != 0) {
        if (out.mode == 1) {
            if (out.duration_ns == 0) {
                out.times_finished_this_tick = std.math.maxInt(u32);
                out.elapsed_ns = 0;
            } else {
                const times = out.elapsed_ns / out.duration_ns;
                out.times_finished_this_tick = if (times > U32_MAX_AS_U64) std.math.maxInt(u32) else @as(u32, @intCast(times));
                out.elapsed_ns = out.elapsed_ns % out.duration_ns;
            }
        } else {
            out.times_finished_this_tick = 1;
            out.elapsed_ns = out.duration_ns;
        }
    } else {
        out.times_finished_this_tick = 0;
    }
    return out.times_finished_this_tick;
}

pub export fn sa3d_fixed_time_native_init(out: *FixedTimeNative, timestep_ns: u64) callconv(.c) void {
    out.* = .{
        .timestep_ns = if (timestep_ns == 0) FIXED_DEFAULT_TIMESTEP_NS else timestep_ns,
        .overstep_ns = 0,
        .delta_ns = 0,
        .elapsed_ns = 0,
        .step_index = 0,
    };
}

pub export fn sa3d_fixed_time_native_set_timestep(out: *FixedTimeNative, timestep_ns: u64) callconv(.c) u32 {
    if (timestep_ns == 0) return 1;
    out.timestep_ns = timestep_ns;
    return 0;
}

pub export fn sa3d_fixed_time_native_accumulate(out: *FixedTimeNative, delta_ns: u64) callconv(.c) void {
    out.overstep_ns +%= delta_ns;
}

pub export fn sa3d_fixed_time_native_expend(out: *FixedTimeNative) callconv(.c) u32 {
    if (out.overstep_ns < out.timestep_ns) return 0;
    out.overstep_ns -= out.timestep_ns;
    out.delta_ns = out.timestep_ns;
    out.elapsed_ns +%= out.timestep_ns;
    out.step_index +%= 1;
    return 1;
}

pub export fn sa3d_time_selftest() callconv(.c) i32 {
    var clock: TimeClockNative = undefined;
    sa3d_time_clock_init(&clock);
    if (clock.wrap_period_ns != DEFAULT_WRAP_PERIOD_NS or clock.delta_ns != 0 or clock.elapsed_ns != 0) return 1;
    if (sa3d_time_clock_set_wrap_period(&clock, 3 * NS_PER_SEC) != 0) return 2;
    sa3d_time_clock_advance_by(&clock, 2 * NS_PER_SEC);
    if (clock.delta_ns != 2 * NS_PER_SEC or clock.elapsed_wrapped_ns != 2 * NS_PER_SEC) return 3;
    sa3d_time_clock_advance_by(&clock, 2 * NS_PER_SEC);
    if (clock.elapsed_ns != 4 * NS_PER_SEC or clock.elapsed_wrapped_ns != NS_PER_SEC) return 4;
    if (sa3d_time_clock_advance_to(&clock, 3 * NS_PER_SEC) != 1) return 5;

    var once: TimerNative = undefined;
    sa3d_timer_native_init(&once, NS_PER_SEC, 0);
    if (sa3d_timer_native_tick(&once, 250_000_000) != 0 or once.elapsed_ns != 250_000_000 or once.finished != 0) return 6;
    if (sa3d_timer_native_tick(&once, 2 * NS_PER_SEC) != 1 or once.elapsed_ns != NS_PER_SEC or once.finished != 1) return 7;
    if (sa3d_timer_native_tick(&once, 1) != 0 or once.finished != 1) return 8;

    var repeating: TimerNative = undefined;
    sa3d_timer_native_init(&repeating, NS_PER_SEC, 1);
    if (sa3d_timer_native_tick(&repeating, 3 * NS_PER_SEC + 500_000_000) != 3) return 9;
    if (repeating.elapsed_ns != 500_000_000 or repeating.finished != 1) return 10;
    if (sa3d_timer_native_tick(&repeating, 200_000_000) != 0 or repeating.finished != 0) return 11;
    sa3d_timer_native_pause(&repeating);
    if (sa3d_timer_native_tick(&repeating, 2 * NS_PER_SEC) != 0 or repeating.finished != 0 or repeating.elapsed_ns != 700_000_000) return 12;

    var zero_repeat: TimerNative = undefined;
    sa3d_timer_native_init(&zero_repeat, 0, 1);
    if (sa3d_timer_native_tick(&zero_repeat, NS_PER_SEC) != std.math.maxInt(u32)) return 13;
    if (zero_repeat.elapsed_ns != 0 or zero_repeat.finished != 1) return 14;

    var fixed: FixedTimeNative = undefined;
    sa3d_fixed_time_native_init(&fixed, 0);
    if (fixed.timestep_ns != FIXED_DEFAULT_TIMESTEP_NS) return 15;
    _ = sa3d_fixed_time_native_set_timestep(&fixed, 2 * NS_PER_SEC);
    sa3d_fixed_time_native_accumulate(&fixed, 7 * NS_PER_SEC);
    if (sa3d_fixed_time_native_expend(&fixed) != 1 or fixed.elapsed_ns != 2 * NS_PER_SEC or fixed.overstep_ns != 5 * NS_PER_SEC) return 16;
    if (sa3d_fixed_time_native_expend(&fixed) != 1 or fixed.elapsed_ns != 4 * NS_PER_SEC or fixed.overstep_ns != 3 * NS_PER_SEC) return 17;
    if (sa3d_fixed_time_native_expend(&fixed) != 1 or fixed.elapsed_ns != 6 * NS_PER_SEC or fixed.overstep_ns != NS_PER_SEC) return 18;
    if (sa3d_fixed_time_native_expend(&fixed) != 0 or fixed.elapsed_ns != 6 * NS_PER_SEC or fixed.overstep_ns != NS_PER_SEC) return 19;
    return 0;
}

test "time native selftest matches Bevy time timer and fixed semantics" {
    try std.testing.expectEqual(@as(i32, 0), sa3d_time_selftest());
}
