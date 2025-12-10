const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file_contents = try std.fs.cwd().readFileAlloc(
        allocator,
        "input.txt",
        1025 * 1024,
    );
    defer allocator.free(file_contents);

    const trimmed = std.mem.trim(u8, file_contents, "\t\r\n");

    const sol_1 = try part_1(allocator, trimmed);
    std.debug.print("Solution part 1: {d}\n", .{sol_1});

    const sol_2 = try part_2(allocator, trimmed);
    std.debug.print("Solution part 2: {d}\n", .{sol_2});
}

fn part_1(allocator: std.mem.Allocator, input: []const u8) !usize {
    const homework = try parse_homework(allocator, input);
    defer {
        for (homework) |line| {
            allocator.free(line);
        }
        allocator.free(homework);
    }

    const numbers = try parse_numbers(allocator, homework[0 .. homework.len - 1]);
    defer {
        for (numbers) |line| {
            allocator.free(line);
        }
        allocator.free(numbers);
    }

    const operators = try parse_operator(allocator, homework[homework.len - 1]);
    defer allocator.free(operators);

    return do_math(operators, numbers);
}

fn part_2(allocator: std.mem.Allocator, input: []const u8) !usize {
    const homework = try parse_homework(allocator, input);
    defer {
        for (homework) |line| {
            allocator.free(line);
        }
        allocator.free(homework);
    }

    return do_math_right_to_left(allocator, homework);
}

const Operator = enum { add, multiply };

fn flushDigitsToNumbers(allocator: std.mem.Allocator, digits: *std.ArrayList(u8), numbers: *std.ArrayList(usize)) !void {
    if (digits.items.len > 0) {
        const digits_slice = try digits.toOwnedSlice();
        defer allocator.free(digits_slice);

        const number = try std.fmt.parseInt(usize, digits_slice, 10);
        try numbers.append(number);
    }
}

fn do_math_right_to_left(allocator: std.mem.Allocator, input: [][]u8) !usize {
    var total: usize = 0;

    var numbers = std.ArrayList(usize).init(allocator);
    defer numbers.deinit();

    const width = input[0].len;
    const height = input.len;
    
    for (0..width) |column_index| {
        var digits = std.ArrayList(u8).init(allocator);
        defer digits.deinit();

        for (input, 0..) |row, row_index| {
            const raw = row[width - 1 - column_index];

            if (raw == '+') {
                try flushDigitsToNumbers(allocator, &digits, &numbers);

                var result: usize = 0;
                for (numbers.items) |number| {
                    result += number;
                }
                numbers.clearRetainingCapacity();
                
                total += result;
                break;
            }

            if (raw == '*') {
                try flushDigitsToNumbers(allocator, &digits, &numbers);

                var result: usize = 1;
                for (numbers.items) |number| {
                    result *= number;
                }
                numbers.clearRetainingCapacity();
                
                total += result;
                break;
            }

            if (raw != ' ') {
                try digits.append(raw);
            }

            if (row_index == height - 1) {
                try flushDigitsToNumbers(allocator, &digits, &numbers);
            }
        }
    }
    return total;
}

fn do_math(operators: []const Operator, numbers: [][]const usize) usize {
    var total: usize = 0;
    const row_count = numbers.len;
    const col_count = numbers[0].len;
    
    for (0..col_count) |col| {
        const operator = operators[col];

        const result = switch (operator) {
            .add => blk: {
                var sum: usize = 0;
                for (0..row_count) |row| {
                    sum += numbers[row][col];
                }
                break :blk sum;
            },
            .multiply => blk: {
                var product: usize = 1;
                for (0..row_count) |row| {
                    product *= numbers[row][col];
                }
                break :blk product;
            },
        };
        
        total += result;
    }

    return total;
}

fn parse_numbers(allocator: std.mem.Allocator, input: [][]u8) ![][]const usize {
    var lines = std.ArrayList([]const usize).init(allocator);
    defer lines.deinit();

    for (input) |line| {
        var numbers = std.ArrayList(usize).init(allocator);
        defer numbers.deinit();

        var raw_numbers = std.mem.tokenizeScalar(u8, line, ' ');
        while (raw_numbers.next()) |raw| {
            const number = try std.fmt.parseInt(usize, raw, 10);
            try numbers.append(number);
        }

        try lines.append(try numbers.toOwnedSlice());
    }

    return lines.toOwnedSlice();
}

fn parse_operator(allocator: std.mem.Allocator, input: []const u8) ![]Operator {
    var raw_operators = std.mem.tokenizeScalar(u8, input, ' ');

    var operators = std.ArrayList(Operator).init(allocator);
    defer operators.deinit();

    while (raw_operators.next()) |raw| {
        if (std.mem.eql(u8, raw, "*")) {
            try operators.append(Operator.multiply);
        }

        if (std.mem.eql(u8, raw, "+")) {
            try operators.append(Operator.add);
        }
    }

    return operators.toOwnedSlice();
}

fn parse_homework(allocator: std.mem.Allocator, input: []const u8) ![][]u8 {
    var homework = std.ArrayList([]u8).init(allocator);
    defer homework.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, "\t\r ");
        const mutable_line = try allocator.dupe(u8, trimmed);
        try homework.append(mutable_line);
    }

    return homework.toOwnedSlice();
}
