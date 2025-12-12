const std = @import("std");

const Nodes = std.StringHashMap([]const u8);
const Memo = std.StringHashMap(usize);

fn paths(start: []const u8, end: []const u8, nodes: *const Nodes) !usize {
    if (std.mem.eql(u8, start, end)) return 1;

    const edges = nodes.get(start) orelse return error.MissingNode;
    var it = std.mem.tokenizeScalar(u8, edges, ' ');
    var total: usize = 0;
    while (it.next()) |next| {
        total += try paths(next, end, nodes);
    }

    return total;
}

fn pathsRequire(allocator: std.mem.Allocator, start: []const u8, end: []const u8, disallowed: []const u8, nodes: *const Nodes, memo: *Memo) !usize {
    if (std.mem.eql(u8, start, disallowed)) return 0;

    var mkey: [6]u8 = undefined;
    @memcpy(mkey[0..3], start);
    @memcpy(mkey[3..], end);
    if (memo.get(&mkey)) |r| {
        return r;
    }
    if (std.mem.eql(u8, start, end)) {
        return 1;
    }

    const edges = nodes.get(start) orelse return 0;
    var it = std.mem.tokenizeScalar(u8, edges, ' ');
    var total: usize = 0;
    while (it.next()) |next| {
        total += try pathsRequire(allocator, next, end, disallowed, nodes, memo);
    }

    try memo.put(try allocator.dupe(u8, &mkey), total);

    return total;
}

fn p1(allocator: std.mem.Allocator, input: []const u8) !void {
    var nodes = Nodes.init(allocator);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse return error.InvalidInput;
        const name = line[0..colon];
        const dests = line[colon + 2 ..];

        try nodes.put(name, dests);
    }

    std.debug.print("{d}\n", .{try paths("you", "out", &nodes)});
}

fn p2(allocator: std.mem.Allocator, input: []const u8) !void {
    var nodes = Nodes.init(allocator);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse return error.InvalidInput;
        const name = line[0..colon];
        const dests = line[colon + 2 ..];

        try nodes.put(name, dests);
    }

    var memo = Memo.init(allocator);

    const svr_dac = try pathsRequire(allocator, "svr", "dac", "fft", &nodes, &memo);
    memo.clearRetainingCapacity();
    const dac_fft = try pathsRequire(allocator, "dac", "fft", "", &nodes, &memo);
    memo.clearRetainingCapacity();
    const fft_out = try pathsRequire(allocator, "fft", "out", "dac", &nodes, &memo);

    const svr_fft = try pathsRequire(allocator, "svr", "fft", "dac", &nodes, &memo);
    memo.clearRetainingCapacity();
    const fft_dac = try pathsRequire(allocator, "fft", "dac", "", &nodes, &memo);
    memo.clearRetainingCapacity();
    const dac_out = try pathsRequire(allocator, "dac", "out", "fft", &nodes, &memo);
    memo.clearRetainingCapacity();

    const result = svr_dac * dac_fft * fft_out + svr_fft * fft_dac * dac_out;

    std.debug.print("{d}\n", .{result});
}

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance.deinit();
    const allocator = arena_instance.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "in", std.math.maxInt(usize));

    try p2(allocator, input);
}
