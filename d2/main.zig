const std = @import("std");

fn isInvalidId(id: u64) bool {
    var id_s: [256]u8 = undefined;
    const len = std.fmt.printInt(&id_s, id, 10, .lower, .{});
    if (len % 2 == 0) {
        return std.mem.eql(u8, id_s[0 .. len / 2], id_s[len / 2 .. len]);
    }
    return false;
}

fn isInvalidId2(id: u64) bool {
    var id_s: [256]u8 = undefined;
    const len = std.fmt.printInt(&id_s, id, 10, .lower, .{});

    for (1..len / 2 + 1) |seq_len| blk: {
        if (len % seq_len != 0) continue;
        for (1..len / seq_len) |offset| {
            if (!std.mem.eql(u8, id_s[0..seq_len], id_s[offset * seq_len .. (offset + 1) * seq_len])) {
                break :blk;
            }
        }
        return true;
    }
    return false;
}

fn p1(input: []const u8) !void {
    var ranges = std.mem.tokenizeScalar(u8, input, ',');
    var sum_invalids: u64 = 0;

    while (ranges.next()) |range| {
        var ids = std.mem.tokenizeScalar(u8, range, '-');
        const start_s = try std.fmt.parseInt(u64, ids.next() orelse return error.InvalidRange, 10);
        const end_s = try std.fmt.parseInt(u64, ids.next() orelse return error.InvalidRange, 10);

        for (start_s..end_s + 1) |id| {
            if (isInvalidId2(id)) {
                sum_invalids += id;
            }
        }
    }

    std.debug.print("{d}\n", .{sum_invalids});
}

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance.deinit();
    const allocator = arena_instance.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "in", std.math.maxInt(usize));

    try p1(std.mem.trimEnd(u8, input, "\n"));
}
