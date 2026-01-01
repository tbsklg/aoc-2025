const std = @import("std");

pub fn main() !void {
    // Line 1: [.##....#] (1,5,6) (1,3,4,7) (0,2) (2,5) (2,4,5,7) (1,2,3,6) (0,5,7) (0,4,7) (3,5,6) (0,2,5)
    const button0 = [_]usize{ 1, 5, 6 };
    const button1 = [_]usize{ 1, 3, 4, 7 };
    const button2 = [_]usize{ 0, 2 };
    const button3 = [_]usize{ 2, 5 };
    const button4 = [_]usize{ 2, 4, 5, 7 };
    const button5 = [_]usize{ 1, 2, 3, 6 };
    const button6 = [_]usize{ 0, 5, 7 };
    const button7 = [_]usize{ 0, 4, 7 };
    const button8 = [_]usize{ 3, 5, 6 };
    const button9 = [_]usize{ 0, 2, 5 };
    
    std.debug.print("8 positions, 10 buttons\n", .{});
    std.debug.print("Matrix:\n", .{});
    std.debug.print("     B0 B1 B2 B3 B4 B5 B6 B7 B8 B9\n", .{});
    
    const buttons = [_][]const usize{
        &button0, &button1, &button2, &button3, &button4,
        &button5, &button6, &button7, &button8, &button9,
    };
    
    const targets = [_]usize{ 48, 31, 52, 26, 20, 57, 37, 26 };
    
    var pos: usize = 0;
    while (pos < 8) : (pos += 1) {
        std.debug.print("P{d} | ", .{pos});
        for (buttons) |button| {
            var found = false;
            for (button) |p| {
                if (p == pos) found = true;
            }
            std.debug.print(" {d}  ", .{@as(u8, if (found) 1 else 0)});
        }
        std.debug.print("| {d}\n", .{targets[pos]});
    }
}
