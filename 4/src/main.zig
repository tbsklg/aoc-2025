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
}

fn part_1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const grid = (try Grid.from(allocator, input)).grid;
    defer allocator.free(grid);

    std.debug.print("{d}", .{grid[0][0]});
    return 0;
}

const Pos = struct {
    x: u8,
    y: u8,
};

const Grid = struct {
    grid: []const []const u8,

    fn from(allocator: std.mem.Allocator, input: []const u8) !Grid {
        var grid = std.ArrayList([]const u8){};
        defer grid.deinit(allocator);

        var lines = std.mem.splitScalar(u8, input, '\n');
        while (lines.next()) |line| {
            try grid.append(allocator, line);
        }

        return .{ .grid = try grid.toOwnedSlice(allocator) };
    }

    fn accessable_paper(self: *Grid) ![]Pos {
       self.grid 
    }
};
