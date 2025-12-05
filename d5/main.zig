const std = @import("std");

const Range = struct {
    start: u64,
    end: u64,

    fn init(line: []const u8) !Range {
        var it = std.mem.tokenizeScalar(u8, line, '-');
        const start = try std.fmt.parseInt(u64, it.next() orelse return error.InvalidRange, 10);
        const end = try std.fmt.parseInt(u64, it.next() orelse return error.InvalidRange, 10);
        return .{ .start = start, .end = end };
    }

    fn check(self: *const Range, ingr: u64) bool {
        return self.start <= ingr and ingr <= self.end;
    }

    fn size(self: *const Range) u64 {
        if (is_empty(self)) {
            return 0;
        }
        return self.end - self.start + 1;
    }

    fn is_empty(self: *const Range) bool {
        return self.start == 0 and self.end == 0;
    }

    fn empty(self: *Range) void {
        self.start = 0;
        self.end = 0;
    }
};

fn parse(allocator: std.mem.Allocator, range_section: []const u8) ![]Range {
    var list = try std.ArrayList(Range).initCapacity(allocator, 10);

    var range_lines = std.mem.tokenizeScalar(u8, range_section, '\n');
    while (range_lines.next()) |line| {
        var it = std.mem.tokenizeScalar(u8, line, '-');
        const start = try std.fmt.parseInt(u64, it.next() orelse return error.InvalidRange, 10);
        const end = try std.fmt.parseInt(u64, it.next() orelse return error.InvalidRange, 10);
        try list.append(allocator, Range{ .start = start, .end = end });
    }

    return try list.toOwnedSlice(allocator);
}

fn p1(allocator: std.mem.Allocator, input: []const u8) !void {
    var groups = std.mem.tokenizeSequence(u8, input, "\n\n");
    const ranges = try parse(allocator, groups.next() orelse return error.InvalidInput);
    var ingredients = std.mem.tokenizeScalar(u8, groups.next() orelse return error.InvalidInput, '\n');

    var fresh_count: u64 = 0;
    while (ingredients.next()) |ingr_s| {
        const ingr = try std.fmt.parseInt(u64, ingr_s, 10);
        for (ranges) |range| {
            if (range.check(ingr)) {
                fresh_count += 1;
                break;
            }
        }
    }

    std.debug.print("{d}\n", .{fresh_count});
}

fn p2(allocator: std.mem.Allocator, input: []const u8) !void {
    var groups = std.mem.tokenizeSequence(u8, input, "\n\n");
    const ranges = try parse(allocator, groups.next() orelse return error.InvalidInput);

    restart: while (true) {
        for (0..ranges.len) |r_i| {
            const r = &ranges[r_i];
            if (ranges[r_i].is_empty()) {
                continue;
            }
            for (r_i + 1..ranges.len) |s_i| {
                const s = &ranges[s_i];
                if (ranges[s_i].is_empty()) {
                    continue;
                }

                var left, var right = if (r.start <= s.start) .{ r, s } else .{ s, r };
                if (right.start <= left.end and right.end >= left.end) { // overlap
                    left.end = right.end;
                    right.empty();
                    continue :restart;
                } else if (right.start <= left.end and right.end < left.end) { // fully contained
                    right.empty();
                    continue :restart;
                }
            }
        }
        break;
    }

    var total_size: u64 = 0;
    for (ranges) |range| {
        total_size += range.size();
    }

    std.debug.print("{d}\n", .{total_size});
}

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance.deinit();
    const allocator = arena_instance.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "in", std.math.maxInt(usize));

    try p2(allocator, input);
}
