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

    const trimmed = std.mem.trim(u8, file_contents, "\t\r\n");

    const sol_1 = try part_1(allocator, trimmed);
    std.debug.print("Solution part 1: {d}\n", .{sol_1});

    const sol_2 = try part_2(allocator, trimmed);
    std.debug.print("Solution part 2: {d}\n", .{sol_2});
}

fn part_1(allocator: std.mem.Allocator, input: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var total: usize = 0;

    while (lines.next()) |line| {
        var m = try Machine.from(allocator, line);
        defer m.deinit();

        const result = try min_presses_lights(allocator, m);
        total += result;
    }

    return total;
}

fn part_2(allocator: std.mem.Allocator, input: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var total: usize = 0;

    while (lines.next()) |line| {
        var m = try Machine.from(allocator, line);
        defer m.deinit();

        var matrix = try Matrix.fromMachine(allocator, m);
        defer matrix.deinit();

        // Find the maximum joltage value
        var max: usize = 0;
        for (m.joltage) |j| {
            max = @max(max, j);
        }
        max += 1;

        var min_val: usize = std.math.maxInt(usize);
        const values = try allocator.alloc(usize, matrix.independents.items.len);
        defer allocator.free(values);
        @memset(values, 0);

        dfs(&matrix, 0, values, &min_val, max);

        if (min_val != std.math.maxInt(usize)) {
            total += min_val;
        }
    }

    return total;
}

fn min_presses_lights(allocator: std.mem.Allocator, m: Machine) !usize {
    var queue = std.ArrayList(struct { usize, usize }){};
    defer queue.deinit(allocator);

    try queue.append(allocator, .{ 0, 0 });

    var seen = std.AutoArrayHashMap(usize, void).init(allocator);
    defer seen.deinit();
    try seen.put(0, {});

    while (queue.items.len > 0) {
        const head = queue.orderedRemove(0);

        if (head.@"0" == m.lights) {
            return head.@"1";
        }

        for (m.buttons) |button| {
            var toggled = head.@"0";

            for (button) |press| {
                toggled = toggled ^ (@as(u32, 1) << @intCast(press));
            }

            if (seen.contains(toggled)) {
                continue;
            }

            try seen.put(toggled, {});
            try queue.append(allocator, .{ toggled, head.@"1" + 1 });
        }
    }

    unreachable;
}

const Machine = struct {
    lights: usize,
    buttons: [][]const usize,
    joltage: []const usize,
    allocator: std.mem.Allocator,

    fn from(allocator: std.mem.Allocator, input: []const u8) !Machine {
        var parts = std.mem.splitScalar(u8, input, ' ');
        const lights = try parse_lights(parts.next().?);

        var _buttons = std.ArrayList([]const usize){};
        while (parts.next()) |part| {
            const peek = parts.peek();

            if (part[0] == '(') {
                const button = try parse_button(allocator, part);
                try _buttons.append(allocator, button);
            }

            if (peek != null and peek.?[0] == '{') {
                break;
            }
        }

        const buttons = try _buttons.toOwnedSlice(allocator);
        const joltage = try parse_joltage(allocator, parts.next().?);

        return .{
            .lights = lights,
            .buttons = buttons,
            .joltage = joltage,
            .allocator = allocator,
        };
    }

    fn deinit(self: *Machine) void {
        for (self.buttons) |button| {
            self.allocator.free(button);
        }
        self.allocator.free(self.buttons);
        self.allocator.free(self.joltage);
    }
};

// {3,5,4,7}
fn parse_joltage(allocator: std.mem.Allocator, input: []const u8) ![]const usize {
    var joltage = std.ArrayList(usize){};
    defer joltage.deinit(allocator);

    const trimmed = input[1 .. input.len - 1];
    var iter = std.mem.splitScalar(u8, trimmed, ',');

    while (iter.next()) |i| {
        const n = try std.fmt.parseInt(usize, i, 10);
        try joltage.append(allocator, n);
    }

    return joltage.toOwnedSlice(allocator);
}

// (0,3,4)
fn parse_button(allocator: std.mem.Allocator, input: []const u8) ![]const usize {
    var button = std.ArrayList(usize){};
    defer button.deinit(allocator);

    const trimmed = input[1 .. input.len - 1];
    var iter = std.mem.splitScalar(u8, trimmed, ',');

    while (iter.next()) |i| {
        const n = try std.fmt.parseInt(usize, i, 10);
        try button.append(allocator, n);
    }

    return button.toOwnedSlice(allocator);
}

// [#.##.]
fn parse_lights(input: []const u8) !usize {
    var acc: usize = 0;
    var pos: usize = 0;

    for (input) |c| {
        if (c == '[' or c == ']') {
            continue;
        }

        if (c == '#') {
            acc |= (@as(usize, 1) << @intCast(pos));
        }
        pos += 1;
    }

    return acc;
}

const EPSILON = 1e-9;

const Matrix = struct {
    data: [][]f64,
    rows: usize,
    cols: usize,
    dependents: std.ArrayList(usize),
    independents: std.ArrayList(usize),
    allocator: std.mem.Allocator,

    fn fromMachine(allocator: std.mem.Allocator, machine: Machine) !Matrix {
        const rows = machine.joltage.len;
        const cols = machine.buttons.len;

        // Allocate 2D array for matrix data
        const data = try allocator.alloc([]f64, rows);
        for (data) |*row| {
            row.* = try allocator.alloc(f64, cols + 1);
            @memset(row.*, 0.0);
        }

        // Add all buttons to the matrix
        for (machine.buttons, 0..) |button, c| {
            for (button) |r| {
                if (r < rows) {
                    data[r][c] = 1.0;
                }
            }
        }

        // Add joltage values to the last column
        for (machine.joltage, 0..) |val, r| {
            data[r][cols] = @floatFromInt(val);
        }

        var matrix = Matrix{
            .data = data,
            .rows = rows,
            .cols = cols,
            .dependents = std.ArrayList(usize){},
            .independents = std.ArrayList(usize){},
            .allocator = allocator,
        };

        try matrix.gaussianElimination();
        return matrix;
    }

    fn gaussianElimination(self: *Matrix) !void {
        var pivot: usize = 0;
        var col: usize = 0;

        while (pivot < self.rows and col < self.cols) {
            // Find the best pivot row for this column
            var best_row: usize = pivot;
            var best_value: f64 = @abs(self.data[pivot][col]);

            var r: usize = pivot + 1;
            while (r < self.rows) : (r += 1) {
                const val = @abs(self.data[r][col]);
                if (val > best_value) {
                    best_row = r;
                    best_value = val;
                }
            }

            // If the best value is zero, this is a free variable
            if (best_value < EPSILON) {
                try self.independents.append(self.allocator, col);
                col += 1;
                continue;
            }

            // Swap rows and mark this column as dependent
            std.mem.swap([]f64, &self.data[pivot], &self.data[best_row]);
            try self.dependents.append(self.allocator, col);

            // Normalize pivot row
            const pivot_value = self.data[pivot][col];
            var c: usize = col;
            while (c <= self.cols) : (c += 1) {
                self.data[pivot][c] /= pivot_value;
            }

            // Eliminate this column in all other rows
            r = 0;
            while (r < self.rows) : (r += 1) {
                if (r != pivot) {
                    const factor = self.data[r][col];
                    if (@abs(factor) > EPSILON) {
                        c = col;
                        while (c <= self.cols) : (c += 1) {
                            self.data[r][c] -= factor * self.data[pivot][c];
                        }
                    }
                }
            }

            pivot += 1;
            col += 1;
        }

        // Any remaining columns are free variables
        while (col < self.cols) : (col += 1) {
            try self.independents.append(self.allocator, col);
        }
    }

    fn valid(self: *const Matrix, values: []const usize) ?usize {
        // Start with how many times we've pressed the free variables
        var total: usize = 0;
        for (values) |v| {
            total += v;
        }

        // Calculate dependent variable values based on independent variables
        for (0..self.dependents.items.len) |row| {
            // Calculate this dependent by subtracting the sum of the free variable pushes
            var val: f64 = self.data[row][self.cols];
            for (self.independents.items, 0..) |ind_col, i| {
                val -= self.data[row][ind_col] * @as(f64, @floatFromInt(values[i]));
            }

            // We need non-negative, whole numbers for a valid solution
            if (val < -EPSILON) {
                return null;
            }

            const rounded = @round(val);
            if (@abs(val - rounded) > EPSILON) {
                return null;
            }

            total += @as(usize, @intFromFloat(rounded));
        }

        return total;
    }

    fn deinit(self: *Matrix) void {
        for (self.data) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.data);
        self.dependents.deinit(self.allocator);
        self.independents.deinit(self.allocator);
    }
};

fn dfs(matrix: *const Matrix, idx: usize, values: []usize, min: *usize, max: usize) void {
    // When we've assigned all independent variables, check if it's a valid solution
    if (idx == matrix.independents.items.len) {
        if (matrix.valid(values)) |total| {
            min.* = @min(min.*, total);
        }
        return;
    }

    // Try different values for the current independent variable
    var total: usize = 0;
    for (values[0..idx]) |v| {
        total += v;
    }

    var val: usize = 0;
    while (val < max) : (val += 1) {
        // Optimization: If we ever go above our min, we can't possibly do better
        if (total + val >= min.*) {
            break;
        }
        values[idx] = val;
        dfs(matrix, idx + 1, values, min, max);
    }
}
