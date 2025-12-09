const std = @import("std");

const Point = struct {
    x: u64,
    y: u64,
};

fn area(pa: Point, pb: Point) u64 {
    return (@max(pa.x, pb.x) - @min(pa.x, pb.x) + 1) *
        (@max(pa.y, pb.y) - @min(pa.y, pb.y) + 1);
}

fn p1(allocator: std.mem.Allocator, input: []const u8) !void {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var points_al = try std.ArrayList(Point).initCapacity(allocator, 256);
    while (lines.next()) |line| {
        var it = std.mem.tokenizeScalar(u8, line, ',');
        const x = try std.fmt.parseInt(u64, it.next() orelse return error.InvalidInput, 10);
        const y = try std.fmt.parseInt(u64, it.next() orelse return error.InvalidInput, 10);
        try points_al.append(allocator, .{ .x = x, .y = y });
    }
    const points = points_al.items;

    var max_area: u64 = 0;
    for (0..points.len) |i| {
        for (i + 1..points.len) |j| {
            const a = area(points[i], points[j]);
            if (a > max_area) max_area = a;
        }
    }

    std.debug.print("{d}\n", .{max_area});
}

const Segment = struct {
    start: u64,
    end: u64,

    fn isEmpty(self: *const Segment) bool {
        return self.start == 0 and self.end == 0;
    }

    fn empty(self: *Segment) void {
        self.start = 0;
        self.end = 0;
    }
};

const SegmentList = struct {
    allocator: std.mem.Allocator,
    segments: std.ArrayList(Segment),

    fn init(allocator: std.mem.Allocator) !SegmentList {
        return .{
            .allocator = allocator,
            .segments = try std.ArrayList(Segment).initCapacity(allocator, 32),
        };
    }

    fn covers(self: *SegmentList, start: u64, end: u64) bool {
        for (self.segments.items) |segment| {
            if (segment.start <= start and segment.end >= end) return true;
        }
        return false;
    }

    fn add(self: *SegmentList, start: u64, end: u64) !void {
        try self.segments.append(self.allocator, .{ .start = start, .end = end });
        self.compact();
    }

    fn compact(self: *SegmentList) void {
        restart: for (0..self.segments.items.len - 1) |i| {
            const s1 = &self.segments.items[i];
            if (s1.isEmpty()) {
                _ = self.segments.swapRemove(i);
                continue :restart;
            }
            for (i + 1..self.segments.items.len) |j| {
                const s2 = &self.segments.items[j];
                if (s2.isEmpty()) {
                    _ = self.segments.swapRemove(j);
                    continue :restart;
                }

                var left, var right = if (s1.start <= s2.start) .{ s1, s2 } else .{ s2, s1 };
                if (right.start <= left.end and right.end >= left.end) { // overlap
                    left.end = right.end;
                    right.empty();
                    continue :restart;
                } else if (right.start <= left.end and right.end < left.end) { // fully contained
                    right.empty();
                    continue :restart;
                } else if (left.end + 1 == right.start) { // adjacent
                    left.end = right.end;
                    right.empty();
                    continue :restart;
                }
            }
        }
    }
};

const Grid = struct {
    segment_lists: std.ArrayList(SegmentList),
    width: usize,
    height: usize,

    fn init(allocator: std.mem.Allocator, points: []Point) !Grid {
        var min_x: u64 = std.math.maxInt(u64);
        var max_x: u64 = 0;
        var min_y: u64 = std.math.maxInt(u64);
        var max_y: u64 = 0;
        for (0..points.len) |i| {
            if (points[i].x > max_x) max_x = points[i].x;
            if (points[i].y > max_y) max_y = points[i].y;
            if (points[i].x < min_x) min_x = points[i].x;
            if (points[i].y < min_y) min_y = points[i].y;
        }

        const width = max_x - min_x + 1;
        const height = max_y - min_y + 1;
        const off_x = min_x;
        const off_y = min_y;

        for (0..points.len) |i| {
            points[i].x -= off_x;
            points[i].y -= off_y;
        }

        var segment_lists = try std.ArrayList(SegmentList).initCapacity(allocator, 256);
        for (0..height) |_| {
            try segment_lists.append(allocator, try SegmentList.init(allocator));
        }

        var vertical_lines = try std.ArrayList(struct { u64, u64, u64 }).initCapacity(allocator, 256);
        for (0..points.len) |i| {
            const pa = points[i];
            const pb = points[(i + 1) % points.len];

            if (pa.y == pb.y) { // horizontal
                try segment_lists.items[pb.y].add(@min(pa.x, pb.x), @max(pa.x, pb.x));
            } else { //vertical
                const start = @min(pa.y, pb.y);
                const end = @max(pa.y, pb.y);
                try vertical_lines.append(allocator, .{ pa.x, start, end });
            }
        }

        var xs = try std.ArrayList(u64).initCapacity(allocator, 256);
        for (0..height) |y| {
            xs.clearRetainingCapacity();
            for (vertical_lines.items) |line| {
                if (line[1] <= y and y < line[2]) try xs.append(allocator, line[0]);
            }
            std.mem.sort(u64, xs.items, {}, std.sort.asc(u64));
            var i: usize = 0;
            while (i < xs.items.len) {
                try segment_lists.items[y].add(xs.items[i], xs.items[i + 1]);
                i += 2;
            }
        }

        return .{
            .segment_lists = segment_lists,
            .width = width,
            .height = height,
        };
    }

    fn print(self: *const Grid) void {
        for (self.segment_lists.items, 0..) |segment_list, y| {
            std.debug.print("{d}: ", .{y});
            for (segment_list.segments.items) |segment| {
                std.debug.print("{d}-{d}, ", .{ segment.start, segment.end });
            }
            std.debug.print("\n", .{});
        }
    }

    fn valid(self: *const Grid, pa: Point, pb: Point) bool {
        const min_x = @min(pa.x, pb.x);
        const max_x = @max(pa.x, pb.x);
        const min_y = @min(pa.y, pb.y);
        const max_y = @max(pa.y, pb.y);

        for (min_y..max_y + 1) |y| {
            if (!self.segment_lists.items[y].covers(min_x, max_x)) return false;
        }

        return true;
    }
};

fn cmp(ctx: void, a: struct { Point, Point, u64 }, b: struct { Point, Point, u64 }) bool {
    _ = ctx;
    return a[2] > b[2];
}

fn p2(allocator: std.mem.Allocator, input: []const u8) !void {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var points_al = try std.ArrayList(Point).initCapacity(allocator, 256);
    while (lines.next()) |line| {
        var it = std.mem.tokenizeScalar(u8, line, ',');
        const x = try std.fmt.parseInt(u64, it.next() orelse return error.InvalidInput, 10);
        const y = try std.fmt.parseInt(u64, it.next() orelse return error.InvalidInput, 10);
        try points_al.append(allocator, .{ .x = x, .y = y });
    }
    const points = points_al.items;

    const grid = try Grid.init(allocator, points);

    var pairs = try std.ArrayList(struct { Point, Point, u64 }).initCapacity(allocator, 256);
    for (0..points.len) |i| {
        for (i + 1..points.len) |j| {
            const a = area(points[i], points[j]);
            try pairs.append(allocator, .{ points[i], points[j], a });
        }
    }

    std.mem.sort(struct { Point, Point, u64 }, pairs.items, {}, cmp);

    for (pairs.items) |pair| {
        if (grid.valid(pair[0], pair[1])) {
            std.debug.print("valid: {d}\n", .{pair[2]});
            return;
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
