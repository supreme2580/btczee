const Engine = @import("../engine.zig").Engine;
const std = @import("std");
const testing = std.testing;
const Script = @import("../lib.zig").Script;
const ScriptFlags = @import("../lib.zig").ScriptFlags;

/// opcodeToAltStack removes the top item from the main data stack and pushes it onto the alternate data stack.
///
/// Main data stack transformation: [... x1 x2 x3] -> [... x1 x2]
/// Alt data stack transformation:  [... y1 y2 y3] -> [... y1 y2 y3 x3]
pub fn opcodeToAltStack(self: *Engine) !void {
    const value = try self.stack.pop();
    try self.alt_stack.push(value);
}

/// opcodeFromAltStack removes the top item from the alternate data stack and pushes it onto the main data stack.
///
/// Main data stack transformation: [... x1 x2 x3] -> [... x1 x2 x3 y3]
/// Alt data stack transformation:  [... y1 y2 y3] -> [... y1 y2]
pub fn opcodeFromAltStack(self: *Engine) !void {
    const value = try self.alt_stack.pop();
    try self.stack.push(value);
}

/// opcode2Drop removes the top 2 items from the data stack.
///
/// Stack transformation: [... x1 x2 x3] -> [... x1]
pub fn opcode2Drop(self: *Engine) !void {
    _ = try self.stack.pop();
    _ = try self.stack.pop();
}

/// opcode2Dup duplicates the top 2 items on the data stack.
///
/// Stack transformation: [... x1 x2 x3] -> [... x1 x2 x3 x2 x3]
pub fn opcode2Dup(self: *Engine) !void {
    const value1 = try self.stack.peek(0);
    const value2 = try self.stack.peek(1);
    try self.stack.push(value2);
    try self.stack.push(value1);
}

/// opcode3Dup duplicates the top 3 items on the data stack.
///
/// Stack transformation: [... x1 x2 x3] -> [... x1 x2 x3 x1 x2 x3]
pub fn opcode3Dup(self: *Engine) !void {
    const value1 = try self.stack.peek(0);
    const value2 = try self.stack.peek(1);
    const value3 = try self.stack.peek(2);
    try self.stack.push(value3);
    try self.stack.push(value2);
    try self.stack.push(value1);
}

/// opcode2Over duplicates the 2 items before the top 2 items on the data stack.
///
/// Stack transformation: [... x1 x2 x3 x4] -> [... x1 x2 x3 x4 x1 x2]
pub fn opcode2Over(self: *Engine) !void {
    const value1 = try self.stack.pop();
    const value2 = try self.stack.pop();
    const value3 = try self.stack.pop();
    const value4 = try self.stack.pop();
    try self.stack.push(value3);
    try self.stack.push(value4);
    try self.stack.push(value1);
    try self.stack.push(value2);
}

/// opcode2Rot rotates the top 6 items on the data stack to the left twice.
///
/// Stack transformation: [... x1 x2 x3 x4 x5 x6] -> [... x3 x4 x5 x6 x1 x2]
pub fn opcode2Rot(self: *Engine) !void {
    _ = try self.stack.pop();
    _ = try self.stack.pop();
    const value3 = try self.stack.pop();
    _ = try self.stack.pop();
    const value5 = try self.stack.pop();
    const value6 = try self.stack.pop();
    try self.stack.push(value5);
    try self.stack.push(value6);
    try self.stack.push(value3);
}

/// opcode2Swap swaps the top 2 items on the data stack with the 2 that come before them.
///
/// Stack transformation: [... x1 x2 x3 x4] -> [... x3 x4 x1 x2]
pub fn opcode2Swap(self: *Engine) !void {
    const value1 = try self.stack.pop();
    const value2 = try self.stack.pop();
    const value3 = try self.stack.pop();
    const value4 = try self.stack.pop();
    try self.stack.push(value3);
    try self.stack.push(value4);
    try self.stack.push(value1);
    try self.stack.push(value2);
}

/// opcodeIfDup duplicates the top item of the stack if it is not zero.
///
/// Stack transformation (x1==0): [... x1] -> [... x1]
/// Stack transformation (x1!=0): [... x1] -> [... x1 x1]
pub fn opcodeIfDup(self: *Engine) !void {
    const value = try self.stack.peek(0);
    if (value != 0) {
        try self.stack.push(value);
    }
}

/// opcodeDepth pushes the depth of the data stack prior to executing this opcode, encoded as a number, onto the data stack.
///
/// Stack transformation: [...] -> [... <num of items on the stack>]
/// Example with 2 items: [x1 x2] -> [x1 x2 2]
/// Example with 3 items: [x1 x2 x3] -> [x1 x2 x3 3]
pub fn opcodeDepth(self: *Engine) !void {
    const depth = try self.stack.len();
    try self.stack.push(depth);
}

/// opcodeDrop removes the top item from the data stack.
///
/// Stack transformation: [... x1 x2 x3] -> [... x1 x2]
pub fn opcodeDrop(self: *Engine) !void {
    _ = try self.stack.pop();
}

/// opcodeDup duplicates the top item on the data stack.
///
/// Stack transformation: [... x1 x2 x3] -> [... x1 x2 x3 x3]
pub fn opcodeDup(self: *Engine) !void {
    const value = try self.stack.peek(0);
    try self.stack.push(value);
}

/// opcodeNip removes the item before the top item on the data stack.
///
/// Stack transformation: [... x1 x2 x3] -> [... x1 x3]
pub fn opcodeNip(self: *Engine) !void {
    const value = try self.stack.pop();
    try self.stack.push(value);
}

/// opcodeOver duplicates the item before the top item on the data stack.
///
/// Stack transformation: [... x1 x2 x3] -> [... x1 x2 x2]
pub fn opcodeOver(self: *Engine) !void {
    const value = try self.stack.peek(1);
    try self.stack.push(value);
}

/// opcodePick treats the top item on the data stack as an integer and duplicates
/// the item on the stack that number of items back to the top.
///
/// Stack transformation: [xn ... x2 x1 x0 n] -> [xn ... x2 x1 x0 xn]
/// Example with n=1: [x2 x1 x0 1] -> [x2 x1 x0 x1]
/// Example with n=2: [x2 x1 x0 2] -> [x2 x1 x0 x2]
pub fn opcodePick(self: *Engine) !void {
    const n = try self.stack.pop();
    const value = try self.stack.peek(n);
    try self.stack.push(value);
}

/// opcodeRoll treats the top item on the data stack as an integer and moves
/// the item on the stack that number of items back to the top.
///
/// Stack transformation: [xn ... x2 x1 x0 n] -> [... x2 x1 x0 xn]
/// Example with n=1: [x2 x1 x0 1] -> [x2 x0 x1]
/// Example with n=2: [x2 x1 x0 2] -> [x1 x0 x2]
pub fn opcodeRoll(self: *Engine) !void {
    const n = try self.stack.pop();
    const value = try self.stack.pop_n(n);
    try self.stack.push(value);
}

/// opcodeRot rotates the top 3 items on the data stack to the left.
///
/// Stack transformation: [... x1 x2 x3] -> [... x2 x3 x1]
pub fn opcodeRot(self: *Engine) !void {
    const value1 = try self.stack.pop(); // Top item
    const value2 = try self.stack.pop(); // Second item
    const value3 = try self.stack.pop(); // Third item
    try self.stack.push(value2); // Re-insert the second item
    try self.stack.push(value3); // Re-insert the top item
    try self.stack.push(value1); // Re-insert the third item
}

/// opcodeSwap swaps the top two items on the stack.
///
/// Stack transformation: [... x1 x2] -> [... x2 x1]
pub fn opcodeSwap(self: *Engine) !void {
    const value1 = try self.stack.pop();
    const value2 = try self.stack.pop();
    try self.stack.push(value1);
    try self.stack.push(value2);
}

/// opcodeTuck inserts a duplicate of the top item of the data stack before the
/// second-to-top item.
///
/// Stack transformation: [... x1 x2] -> [... x2 x1 x2]
pub fn opcodeTuck(self: *Engine) !void {
    const value1 = try self.stack.pop();
    const value2 = try self.stack.pop();
    try self.stack.push(value1);
    try self.stack.push(value2);
    try self.stack.push(value1);
}

test "opcodeToAltStack operation" {
    const allocator = testing.allocator;

    const testCases = [_]struct {
        main_stack: []const i64,
        alt_stack: []const i64,
        expected_main_stack: []const i64,
        expected_alt_stack: []const i64,
    }{
        .{ .main_stack = &.{ 1, 2, 3 }, .alt_stack = &.{ 4, 5 }, .expected_main_stack = &.{ 1, 2 }, .expected_alt_stack = &.{ 4, 5, 3 } },
        .{ .main_stack = &.{42}, .alt_stack = &.{99}, .expected_main_stack = &.{}, .expected_alt_stack = &.{ 99, 42 } },
        .{ .main_stack = &.{ 0, -1, 5 }, .alt_stack = &.{ 7, 8 }, .expected_main_stack = &.{ 0, -1 }, .expected_alt_stack = &.{ 7, 8, 5 } },
    };

    for (testCases) |tc| {
        const script_bytes = [_]u8{0x00};
        const script = Script.init(&script_bytes);

        var engine = Engine.init(allocator, script, ScriptFlags{});
        defer engine.deinit();

        for (tc.main_stack) |value| {
            try engine.stack.push(value);
        }
        for (tc.alt_stack) |value| {
            try engine.alt_stack.push(value);
        }
        try engine.opcodeToAltStack();

        const main_stack = engine.stack.toSlice();
        const alt_stack = engine.alt_stack.toSlice();
        try testing.expectEqual(i64, main_stack, tc.expected_main_stack);
        try testing.expectEqual(i64, alt_stack, tc.expected_alt_stack);
    }
}

test "opcodeFromAltStack operation" {
    const allocator = testing.allocator;

    const testCases = [_]struct {
        main_stack: []const i64,
        alt_stack: []const i64,
        expected_main_stack: []const i64,
        expected_alt_stack: []const i64,
    }{
        .{ .main_stack = &.{ 1, 2 }, .alt_stack = &.{ 3, 4 }, .expected_main_stack = &.{ 1, 2, 4 }, .expected_alt_stack = &.{3} },
        .{ .main_stack = &.{ 5, 6 }, .alt_stack = &.{7}, .expected_main_stack = &.{ 5, 6, 7 }, .expected_alt_stack = &.{} },
        .{ .main_stack = &.{0}, .alt_stack = &.{ -1, -2 }, .expected_main_stack = &.{ 0, -2 }, .expected_alt_stack = &.{-1} },
    };

    for (testCases) |tc| {
        const script_bytes = [_]u8{0x00};
        const script = Script.init(&script_bytes);

        var engine = Engine.init(allocator, script, ScriptFlags{});
        defer engine.deinit();

        for (tc.main_stack) |value| {
            try engine.stack.push(value);
        }
        for (tc.alt_stack) |value| {
            try engine.alt_stack.push(value);
        }
        try engine.opcodeFromAltStack();

        const main_stack = engine.stack.toSlice();
        const alt_stack = engine.alt_stack.toSlice();
        try testing.expectEqual(i64, main_stack, tc.expected_main_stack);
        try testing.expectEqual(i64, alt_stack, tc.expected_alt_stack);
    }
}

test "opcode2Drop operation" {
    const allocator = testing.allocator;

    const testCases = [_]struct {
        stack: []const i64,
        expected_stack: []const i64,
    }{
        .{ .stack = &.{ 1, 2, 3 }, .expected_stack = &.{1} },
        .{ .stack = &.{ 4, 5, 6, 7 }, .expected_stack = &.{ 4, 5 } },
        .{ .stack = &.{ 10, 20, 30, 40, 50 }, .expected_stack = &.{ 10, 20, 30 } },
    };

    for (testCases) |tc| {
        const script_bytes = [_]u8{0x00};
        const script = Script.init(&script_bytes);

        var engine = Engine.init(allocator, script, ScriptFlags{});
        defer engine.deinit();

        for (tc.stack) |value| {
            try engine.stack.push(value);
        }
        try engine.opcode2Drop();

        const stack = engine.stack.toSlice();
        try testing.expectEqual(i64, stack, tc.expected_stack);
    }
}

test "opcode2Dup operation" {
    const allocator = testing.allocator;

    const testCases = [_]struct {
        stack: []const i64,
        expected_stack: []const i64,
    }{
        .{ .stack = &.{ 1, 2, 3 }, .expected_stack = &.{ 1, 2, 3, 2, 3 } },
        .{ .stack = &.{ 4, 5 }, .expected_stack = &.{ 4, 5, 4, 5 } },
        .{ .stack = &.{7}, .expected_stack = &.{ 7, 7 } },
    };

    for (testCases) |tc| {
        const script_bytes = [_]u8{0x00};
        const script = Script.init(&script_bytes);

        var engine = Engine.init(allocator, script, ScriptFlags{});
        defer engine.deinit();

        for (tc.stack) |value| {
            try engine.stack.push(value);
        }
        try engine.opcode2Dup();

        const stack = engine.stack.toSlice();
        try testing.expectEqual(i64, stack, tc.expected_stack);
    }
}

test "opcode3Dup operation" {
    const allocator = testing.allocator;

    const testCases = [_]struct {
        stack: []const i64,
        expected_stack: []const i64,
    }{
        .{ .stack = &.{ 1, 2, 3 }, .expected_stack = &.{ 1, 2, 3, 1, 2, 3 } },
        .{ .stack = &.{ 4, 5, 6 }, .expected_stack = &.{ 4, 5, 6, 4, 5, 6 } },
        .{ .stack = &.{7}, .expected_stack = &.{ 7, 7, 7 } },
    };

    for (testCases) |tc| {
        const script_bytes = [_]u8{0x00};
        const script = Script.init(&script_bytes);

        var engine = Engine.init(allocator, script, ScriptFlags{});
        defer engine.deinit();

        for (tc.stack) |value| {
            try engine.stack.push(value);
        }
        try engine.opcode3Dup();

        const stack = engine.stack.toSlice();
        try testing.expectEqual(i64, stack, tc.expected_stack);
    }
}

test "opcode2Over operation" {
    const allocator = testing.allocator;

    const testCases = [_]struct {
        stack: []const i64,
        expected_stack: []const i64,
    }{
        .{ .stack = &.{ 1, 2, 3, 4 }, .expected_stack = &.{ 1, 2, 3, 4, 1, 2 } },
        .{ .stack = &.{ 5, 6, 7, 8 }, .expected_stack = &.{ 5, 6, 7, 8, 5, 6 } },
        .{ .stack = &.{9}, .expected_stack = &.{9} },
    };

    for (testCases) |tc| {
        const script_bytes = [_]u8{0x00};
        const script = Script.init(&script_bytes);

        var engine = Engine.init(allocator, script, ScriptFlags{});
        defer engine.deinit();

        for (tc.stack) |value| {
            try engine.stack.push(value);
        }
        try engine.opcode2Over();

        const stack = engine.stack.toSlice();
        try testing.expectEqual(i64, stack, tc.expected_stack);
    }
}

test "opcode2Rot operation" {
    const allocator = testing.allocator;

    const testCases = [_]struct {
        stack: []const i64,
        expected_stack: []const i64,
    }{
        .{ .stack = &.{ 1, 2, 3, 4, 5, 6 }, .expected_stack = &.{ 3, 4, 5, 6, 1, 2 } },
        .{ .stack = &.{ 7, 8, 9, 10, 11, 12 }, .expected_stack = &.{ 9, 10, 11, 12, 7, 8 } },
        .{ .stack = &.{ 13, 14, 15 }, .expected_stack = &.{ 13, 14, 15 } },
    };

    for (testCases) |tc| {
        const script_bytes = [_]u8{0x00};
        const script = Script.init(&script_bytes);

        var engine = Engine.init(allocator, script, ScriptFlags{});
        defer engine.deinit();

        for (tc.stack) |value| {
            try engine.stack.push(value);
        }
        try engine.opcode2Rot();

        const stack = engine.stack.toSlice();
        try testing.expectEqual(i64, stack, tc.expected_stack);
    }
}

test "opcode2Swap operation" {
    const allocator = testing.allocator;

    const testCases = [_]struct {
        stack: []const i64,
        expected_stack: []const i64,
    }{
        .{ .stack = &.{ 1, 2, 3, 4 }, .expected_stack = &.{ 3, 4, 1, 2 } },
        .{ .stack = &.{ 5, 6, 7, 8 }, .expected_stack = &.{ 7, 8, 5, 6 } },
        .{ .stack = &.{ 9, 10, 11, 12 }, .expected_stack = &.{ 11, 12, 9, 10 } },
    };

    for (testCases) |tc| {
        const script_bytes = [_]u8{0x00};
        const script = Script.init(&script_bytes);

        var engine = Engine.init(allocator, script, ScriptFlags{});
        defer engine.deinit();

        for (tc.stack) |value| {
            try engine.stack.push(value);
        }
        try engine.opcode2Swap();

        const stack = engine.stack.toSlice();
        try testing.expectEqual(i64, stack, tc.expected_stack);
    }
}

test "opcodeIfDup operation" {
    const allocator = testing.allocator;

    const testCases = [_]struct {
        stack: []const i64,
        expected_stack: []const i64,
    }{
        .{ .stack = &.{0}, .expected_stack = &.{0} },
        .{ .stack = &.{1}, .expected_stack = &.{ 1, 1 } },
        .{ .stack = &.{-1}, .expected_stack = &.{ -1, -1 } },
    };

    for (testCases) |tc| {
        const script_bytes = [_]u8{0x00};
        const script = Script.init(&script_bytes);

        var engine = Engine.init(allocator, script, ScriptFlags{});
        defer engine.deinit();

        for (tc.stack) |value| {
            try engine.stack.push(value);
        }
        try engine.opcodeIfDup();

        const stack = engine.stack.toSlice();
        try testing.expectEqual(i64, stack, tc.expected_stack);
    }
}

test "opcodeDepth operation" {
    const allocator = testing.allocator;

    const testCases = [_]struct {
        stack: []const i64,
        expected_stack: []const i64,
    }{
        .{ .stack = &.{ 1, 2, 3 }, .expected_stack = &.{ 1, 2, 3, 3 } },
        .{ .stack = &.{ 4, 5 }, .expected_stack = &.{ 4, 5, 2 } },
        .{ .stack = &.{6}, .expected_stack = &.{ 6, 1 } },
    };

    for (testCases) |tc| {
        const script_bytes = [_]u8{0x00};
        const script = Script.init(&script_bytes);

        var engine = Engine.init(allocator, script, ScriptFlags{});
        defer engine.deinit();

        for (tc.stack) |value| {
            try engine.stack.push(value);
        }
        try engine.opcodeDepth();

        const stack = engine.stack.toSlice();
        try testing.expectEqual(i64, stack, tc.expected_stack);
    }
}

test "opcodeDrop operation" {
    const allocator = testing.allocator;

    const testCases = [_]struct {
        stack: []const i64,
        expected_stack: []const i64,
    }{
        .{ .stack = &.{ 1, 2, 3 }, .expected_stack = &.{ 1, 2 } },
        .{ .stack = &.{ 4, 5, 6 }, .expected_stack = &.{ 4, 5 } },
        .{ .stack = &.{ 7, 8 }, .expected_stack = &.{7} },
    };

    for (testCases) |tc| {
        const script_bytes = [_]u8{0x00};
        const script = Script.init(&script_bytes);

        var engine = Engine.init(allocator, script, ScriptFlags{});
        defer engine.deinit();

        for (tc.stack) |value| {
            try engine.stack.push(value);
        }
        try engine.opcodeDrop();

        const stack = engine.stack.toSlice();
        try testing.expectEqual(i64, stack, tc.expected_stack);
    }
}

test "opcodeDup operation" {
    const allocator = testing.allocator;

    const testCases = [_]struct {
        stack: []const i64,
        expected_stack: []const i64,
    }{
        .{ .stack = &.{ 1, 2, 3 }, .expected_stack = &.{ 1, 2, 3, 3 } },
        .{ .stack = &.{ 4, 5 }, .expected_stack = &.{ 4, 5, 5 } },
        .{ .stack = &.{6}, .expected_stack = &.{ 6, 6 } },
    };

    for (testCases) |tc| {
        const script_bytes = [_]u8{0x00};
        const script = Script.init(&script_bytes);

        var engine = Engine.init(allocator, script, ScriptFlags{});
        defer engine.deinit();

        for (tc.stack) |value| {
            try engine.stack.push(value);
        }
        try engine.opcodeDup();

        const stack = engine.stack.toSlice();
        try testing.expectEqual(i64, stack, tc.expected_stack);
    }
}

test "opcodeNip operation" {
    const allocator = testing.allocator;

    const testCases = [_]struct {
        stack: []const i64,
        expected_stack: []const i64,
    }{
        .{ .stack = &.{ 1, 2, 3 }, .expected_stack = &.{ 1, 3 } },
        .{ .stack = &.{ 4, 5, 6, 7 }, .expected_stack = &.{ 4, 6, 7 } },
        .{ .stack = &.{ 8, 9, 10, 11, 12 }, .expected_stack = &.{ 8, 10, 11, 12 } },
    };

    for (testCases) |tc| {
        const script_bytes = [_]u8{0x00};
        const script = Script.init(&script_bytes);

        var engine = Engine.init(allocator, script, ScriptFlags{});
        defer engine.deinit();

        for (tc.stack) |value| {
            try engine.stack.push(value);
        }
        try engine.opcodeNip();

        const stack = engine.stack.toSlice();
        try testing.expectEqual(i64, stack, tc.expected_stack);
    }
}

test "opcodeOver operation" {
    const allocator = testing.allocator;

    const testCases = [_]struct {
        stack: []const i64,
        expected_stack: []const i64,
    }{
        .{ .stack = &.{ 1, 2, 3 }, .expected_stack = &.{ 1, 2, 3, 2 } },
        .{ .stack = &.{ 4, 5, 6 }, .expected_stack = &.{ 4, 5, 6, 5 } },
        .{ .stack = &.{ 7, 8 }, .expected_stack = &.{ 7, 8, 8 } },
    };

    for (testCases) |tc| {
        const script_bytes = [_]u8{0x00};
        const script = Script.init(&script_bytes);

        var engine = Engine.init(allocator, script, ScriptFlags{});
        defer engine.deinit();

        for (tc.stack) |value| {
            try engine.stack.push(value);
        }
        try engine.opcodeOver();

        const stack = engine.stack.toSlice();
        try testing.expectEqual(i64, stack, tc.expected_stack);
    }
}

test "opcodePick operation" {
    const allocator = testing.allocator;

    const testCases = [_]struct {
        stack: []const i64,
        pick: i64,
        expected_stack: []const i64,
    }{
        .{ .stack = &.{ 1, 2, 3 }, .pick = 1, .expected_stack = &.{ 1, 2, 3, 2 } },
        .{ .stack = &.{ 4, 5, 6 }, .pick = 2, .expected_stack = &.{ 4, 5, 6, 4 } },
        .{ .stack = &.{ 7, 8, 9, 10 }, .pick = 0, .expected_stack = &.{ 7, 8, 9, 10, 7 } },
    };

    for (testCases) |tc| {
        const script_bytes = [_]u8{0x00};
        const script = Script.init(&script_bytes);

        var engine = Engine.init(allocator, script, ScriptFlags{});
        defer engine.deinit();

        for (tc.stack) |value| {
            try engine.stack.push(value);
        }
        try engine.stack.push(tc.pick);
        try engine.opcodePick();

        const stack = engine.stack.toSlice();
        try testing.expectEqual(i64, stack, tc.expected_stack);
    }
}

test "opcodeRoll operation" {
    const allocator = testing.allocator;

    const testCases = [_]struct {
        stack: []const i64,
        roll: i64,
        expected_stack: []const i64,
    }{
        .{ .stack = &.{ 1, 2, 3, 4 }, .roll = 1, .expected_stack = &.{ 1, 2, 4, 3 } },
        .{ .stack = &.{ 5, 6, 7, 8 }, .roll = 2, .expected_stack = &.{ 5, 7, 8, 6 } },
        .{ .stack = &.{ 9, 10, 11, 12, 13 }, .roll = 0, .expected_stack = &.{ 9, 10, 11, 12, 13 } },
    };

    for (testCases) |tc| {
        const script_bytes = [_]u8{0x00};
        const script = Script.init(&script_bytes);

        var engine = Engine.init(allocator, script, ScriptFlags{});
        defer engine.deinit();

        for (tc.stack) |value| {
            try engine.stack.push(value);
        }
        try engine.stack.push(tc.roll);
        try engine.opcodeRoll();

        const stack = engine.stack.toSlice();
        try testing.expectEqual(i64, stack, tc.expected_stack);
    }
}

test "opcodeRot operation" {
    const allocator = testing.allocator;

    const testCases = [_]struct {
        stack: []const i64,
        expected_stack: []const i64,
    }{
        .{ .stack = &.{ 1, 2, 3 }, .expected_stack = &.{ 2, 3, 1 } },
        .{ .stack = &.{ 4, 5, 6, 7 }, .expected_stack = &.{ 5, 6, 7, 4 } },
        .{ .stack = &.{ 8, 9, 10, 11, 12 }, .expected_stack = &.{ 9, 10, 11, 12, 8 } },
    };

    for (testCases) |tc| {
        const script_bytes = [_]u8{0x00};
        const script = Script.init(&script_bytes);

        var engine = Engine.init(allocator, script, ScriptFlags{});
        defer engine.deinit();

        for (tc.stack) |value| {
            try engine.stack.push(value);
        }
        try engine.opcodeRot();

        const stack = engine.stack.toSlice();
        try testing.expectEqual(i64, stack, tc.expected_stack);
    }
}

test "opcodeSwap operation" {
    const allocator = testing.allocator;

    const testCases = [_]struct {
        stack: []const i64,
        expected_stack: []const i64,
    }{
        .{ .stack = &.{ 1, 2 }, .expected_stack = &.{ 2, 1 } },
        .{ .stack = &.{ 3, 4, 5, 6 }, .expected_stack = &.{ 5, 6, 3, 4 } },
        .{ .stack = &.{ 7, 8, 9, 10, 11 }, .expected_stack = &.{ 9, 10, 7, 8, 11 } },
    };

    for (testCases) |tc| {
        const script_bytes = [_]u8{0x00};
        const script = Script.init(&script_bytes);

        var engine = Engine.init(allocator, script, ScriptFlags{});
        defer engine.deinit();

        for (tc.stack) |value| {
            try engine.stack.push(value);
        }
        try engine.opcodeSwap();

        const stack = engine.stack.toSlice();
        try testing.expectEqual(i64, stack, tc.expected_stack);
    }
}

test "opcodeTuck operation" {
    const allocator = testing.allocator;

    const testCases = [_]struct {
        stack: []const i64,
        expected_stack: []const i64,
    }{
        .{ .stack = &.{ 1, 2 }, .expected_stack = &.{ 2, 1, 2 } },
        .{ .stack = &.{ 3, 4, 5 }, .expected_stack = &.{ 4, 5, 3, 3 } },
        .{ .stack = &.{ 6, 7, 8, 9 }, .expected_stack = &.{ 7, 8, 9, 6, 6 } },
    };

    for (testCases) |tc| {
        const script_bytes = [_]u8{0x00};
        const script = Script.init(&script_bytes);

        var engine = Engine.init(allocator, script, ScriptFlags{});
        defer engine.deinit();

        for (tc.stack) |value| {
            try engine.stack.push(value);
        }
        try engine.opcodeTuck();

        const stack = engine.stack.toSlice();
        try testing.expectEqual(i64, stack, tc.expected_stack);
    }
}
