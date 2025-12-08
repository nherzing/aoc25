const std = @import("std");

const Point = struct {
    x: u64,
    y: u64,
    z: u64,

    fn init(line: []const u8) !Point {
        var it = std.mem.tokenizeScalar(u8, line, ',');

        const x = try std.fmt.parseInt(u64, it.next() orelse return error.InvalidInput, 10);
        const y = try std.fmt.parseInt(u64, it.next() orelse return error.InvalidInput, 10);
        const z = try std.fmt.parseInt(u64, it.next() orelse return error.InvalidInput, 10);

        return .{ .x = x, .y = y, .z = z };
    }
};

fn dist(pa: Point, pb: Point) u64 {
    return std.math.sqrt(std.math.pow(u64, @max(pa.x, pb.x) - @min(pa.x, pb.x), 2) +
        std.math.pow(u64, @max(pa.y, pb.y) - @min(pa.y, pb.y), 2) +
        std.math.pow(u64, @max(pa.z, pb.z) - @min(pa.z, pb.z), 2));
}

fn cmp(ctx: void, a: struct { usize, usize, u64 }, b: struct { usize, usize, u64 }) bool {
    _ = ctx;
    return a[2] < b[2];
}

fn p1(allocator: std.mem.Allocator, input: []const u8) !void {
    var lines_it = std.mem.tokenizeScalar(u8, input, '\n');

    var points = try std.ArrayList(Point).initCapacity(allocator, 256);
    var circuits = try std.ArrayList(usize).initCapacity(allocator, 256);

    { // build initial circuits
        var i: usize = 0;
        while (lines_it.next()) |line| {
            const point = try Point.init(line);
            try points.append(allocator, point);
            try circuits.append(allocator, i);
            i += 1;
        }
    }

    // build sorted pairs
    var pairs = try std.ArrayList(struct { usize, usize, u64 }).initCapacity(allocator, std.math.pow(usize, points.items.len, 2));
    for (0..points.items.len) |i| {
        for (i + 1..points.items.len) |j| {
            try pairs.append(allocator, .{ i, j, dist(points.items[i], points.items[j]) });
        }
    }
    std.mem.sort(struct { usize, usize, u64 }, pairs.items, {}, cmp);

    for (pairs.items[0..1000]) |pair| {
        if (circuits.items[pair[0]] != circuits.items[pair[1]]) {
            const ca = circuits.items[pair[0]];
            const cb = circuits.items[pair[1]];
            for (0..circuits.items.len) |i| {
                if (circuits.items[i] == cb) {
                    circuits.items[i] = ca;
                }
            }
        }
    }

    var sizes = try std.ArrayList(u64).initCapacity(allocator, circuits.items.len);
    for (0..circuits.items.len) |i| {
        var size: u64 = 0;
        for (circuits.items) |circuit| {
            if (circuit == i) {
                size += 1;
            }
        }
        try sizes.append(allocator, size);
    }

    std.mem.sort(u64, sizes.items, {}, std.sort.desc(u64));

    std.debug.print("{d}\n", .{sizes.items[0] * sizes.items[1] * sizes.items[2]});
}

fn p2(allocator: std.mem.Allocator, input: []const u8) !void {
    var lines_it = std.mem.tokenizeScalar(u8, input, '\n');

    var points = try std.ArrayList(Point).initCapacity(allocator, 256);
    var circuits = try std.ArrayList(usize).initCapacity(allocator, 256);

    { // build initial circuits
        var i: usize = 0;
        while (lines_it.next()) |line| {
            const point = try Point.init(line);
            try points.append(allocator, point);
            try circuits.append(allocator, i);
            i += 1;
        }
    }

    // build sorted pairs
    var pairs = try std.ArrayList(struct { usize, usize, u64 }).initCapacity(allocator, std.math.pow(usize, points.items.len, 2));
    for (0..points.items.len) |i| {
        for (i + 1..points.items.len) |j| {
            try pairs.append(allocator, .{ i, j, dist(points.items[i], points.items[j]) });
        }
    }
    std.mem.sort(struct { usize, usize, u64 }, pairs.items, {}, cmp);

    for (pairs.items) |pair| {
        if (circuits.items[pair[0]] != circuits.items[pair[1]]) {
            const ca = circuits.items[pair[0]];
            const cb = circuits.items[pair[1]];
            for (0..circuits.items.len) |i| {
                if (circuits.items[i] == cb) {
                    circuits.items[i] = ca;
                }
            }

            if (std.mem.allEqual(u64, circuits.items[1..], circuits.items[0])) {
                std.debug.print("{d}\n", .{points.items[pair[0]].x * points.items[pair[1]].x});
                return;
            }
        }
    }
}

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance.deinit();
    const allocator = arena_instance.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "in", std.math.maxInt(usize));

    try p2(allocator, input);
}
