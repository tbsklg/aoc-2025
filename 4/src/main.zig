const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file_contents = try std.fs.cwd().readFileAlloc(
        allocator,
        "input.txt",
        1024 * 1024,
    );
    defer allocator.free(file_contents);

    const trimmed = std.mem.trim(u8, file_contents, " \t\r\n");

    const sol_1 = try part_1(trimmed);
    std.debug.print("Solution part 1: {d}\n", .{sol_1});

    const sol_2 = try part_2(trimmed);
    std.debug.print("Solution part 2: {d}\n", .{sol_2});
}

fn part_1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const grid = try Grid.from(allocator, input);
    const papers = grid.accessable_papers();
    defer grid.deinit();

    return papers;
}

fn part_2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const grid = try Grid.from(allocator, input);
    const papers = try grid.accessable_papers_with_cleanup();
    defer grid.deinit();

    return papers;
}

const Pos = struct {
    x: i32,
    y: i32,
};

const Grid = struct {
    grid: [][]u8,
    allocator: std.mem.Allocator,

    fn from(allocator: std.mem.Allocator, input: []const u8) !Grid {
        var grid = std.ArrayList([]u8){};
        defer grid.deinit(allocator);

        var lines = std.mem.splitScalar(u8, input, '\n');
        while (lines.next()) |line| {
            const mutable_line = try allocator.dupe(u8, line);
            try grid.append(allocator, mutable_line);
        }

        return .{
            .grid = try grid.toOwnedSlice(allocator),
            .allocator = allocator,
        };
    }

    fn deinit(self: *const Grid) void {
        for (self.grid) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.grid);
    }

    fn accessable_papers(self: *const Grid) !usize {
        var count: usize = 0;

        for (0..self.grid.len) |x| {
            for (0..self.grid[x].len) |y| {
                const pos = Pos{ .x = @intCast(x), .y = @intCast(y) };
                if (self.grid[x][y] == '@') {
                    const papers = try self.papers_around(pos);
                    defer self.allocator.free(papers);
                    if (papers.len < 4) {
                        count += 1;
                    }
                }
            }
        }

        return count;
    }

    fn accessable_papers_with_cleanup(self: *const Grid) !usize {
        var papers_count: usize = 0;
        for (0..self.grid.len) |x| {
            for (0..self.grid[x].len) |y| {
                const pos = Pos{ .x = @intCast(x), .y = @intCast(y) };
                if (self.grid[x][y] == '@') {
                    const papers = try self.papers_around(pos);
                    defer self.allocator.free(papers);

                    if (papers.len < 4) {
                        papers_count += 1;
                        self.grid[@intCast(x)][@intCast(y)] = 'x';
                    }
                }
            }
        }

        if (papers_count == 0) {
            return 0;
        }

        return papers_count + try self.accessable_papers_with_cleanup();
    }

    fn print(self: *const Grid) void {
        for (self.grid) |row| {
            std.log.debug("{s}", .{row});
        }
    }

    fn papers_around(self: *const Grid, pos: Pos) ![]Pos {
        var papers = std.ArrayList(Pos){};
        defer papers.deinit(self.allocator);

        const dirs = [8](struct { i8, i8 }){ .{ 1, 0 }, .{ 1, -1 }, .{ 0, -1 }, .{ -1, -1 }, .{ -1, 0 }, .{ -1, 1 }, .{ 0, 1 }, .{ 1, 1 } };

        for (dirs) |dir| {
            const xs = @as(i32, pos.x) + dir.@"0";
            const ys = @as(i32, pos.y) + dir.@"1";

            if (xs >= 0 and xs < self.grid.len and ys >= 0 and ys < self.grid[@intCast(pos.y)].len) {
                if (self.grid[@intCast(xs)][@intCast(ys)] == '@') {
                    try papers.append(self.allocator, .{ .x = xs, .y = ys });
                }
            }
        }

        return papers.toOwnedSlice(self.allocator);
    }
};
