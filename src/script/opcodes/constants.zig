const std = @import("std");
const testing = std.testing;
const Engine = @import("../engine.zig").Engine;
const Script = @import("../lib.zig").Script;
const ScriptFlags = @import("../lib.zig").ScriptFlags;
const StackError = @import("../stack.zig").StackError;
const Endian = std.builtin.Endian;

/// OP_FALSE: Pushes an empty array to the data stack to represent false.
pub fn opFalse(self: *Engine) !void {
    const empty_array: []const u8 = &.{};
    try self.stack.pushByteArray(empty_array);
}

fn pullData(self: *Engine, n: usize) ![]const u8 {
    if (self.pc + n > self.script.len()) {
        return error.ScriptTooShort;
    }
    const data = self.script.data[self.pc .. self.pc + n];
    self.pc += n;
    return data;
}

/// OP_PUSHDATA: Pushes the next n bytes as an array to the stack.
pub fn opPushData(self: *Engine, n: usize) !void {
    const data = try pullData(self, n);
    try self.stack.pushByteArray(data);
}

const MAX_SCRIPT_ELEMENT_SIZE = 520;

/// OP_PUSHDATA_X: Pushes the next n bytes as a length, then pushes that many bytes as an array.
pub fn opPushDataX(self: *Engine, n: usize) !void {}

/// OP_N: Pushes the integer n to the stack.
pub fn opcodeN(self: *Engine, n: i64) !void {
    try self.stack.pushInt(n);
}

/// OP_1NEGATE: Pushes the integer -1 to the stack.
pub fn op1Negate(self: *Engine) !void {
    try self.stack.pushInt(-1);
}

test "opcode_false" {
    const allocator = testing.allocator;
    const script_bytes = [_]u8{0x00};
    const script = Script.init(&script_bytes);

    var engine = Engine.init(allocator, script, ScriptFlags{});
    defer engine.deinit();

    try opFalse(&engine);

    const result = try engine.stack.pop();
    defer allocator.free(result);

    try testing.expectEqualSlices(u8, &[_]u8{}, result);
}

test "opcode_push_data" {
    const allocator = testing.allocator;
    const script_bytes = [_]u8{ 0x01, 0x02, 0x03 };
    const script = Script.init(&script_bytes);

    var engine = Engine.init(allocator, script, ScriptFlags{});
    defer engine.deinit();

    try opPushData(&engine, 3);

    const result = try engine.stack.pop();
    defer allocator.free(result);

    try testing.expectEqualSlices(u8, &[_]u8{ 0x01, 0x02, 0x03 }, result);
}

// test "opcode_push_data_x" {
//     const allocator = testing.allocator;
//     const script_bytes = [_]u8{ 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x05, 0x06 };
//     const script = Script.init(&script_bytes);

//     var engine = Engine.init(allocator, script, ScriptFlags{});
//     defer engine.deinit();

//     try opPushDataX(&engine, 8);

//     const result = try engine.stack.pop();
//     defer allocator.free(result);

//     try testing.expectEqualSlices(u8, &[_]u8{ 0x04, 0x05, 0x06 }, result);
// }

test "OP_PUSHDATA_X operation" {
    const allocator = testing.allocator;
    const script_bytes = [_]u8{ 0x03, 0x04, 0x05, 0x06, 0x07 };
    const script = Script.init(&script_bytes);

    var engine = Engine.init(allocator, script, ScriptFlags{});
    defer engine.deinit();

    try opPushDataX(&engine, 1);

    const result = try engine.stack.pop();
    defer allocator.free(result);

    try testing.expectEqualSlices(u8, &[_]u8{0x04}, result);
}

test "opcode_n" {
    const allocator = testing.allocator;
    const script_bytes = [_]u8{0x00};
    const script = Script.init(&script_bytes);

    var engine = Engine.init(allocator, script, ScriptFlags{});
    defer engine.deinit();

    try opcodeN(&engine, 42);

    const result = try engine.stack.popInt();
    try testing.expectEqual(@as(i64, 42), result);
}

test "opcode_1negate" {
    const allocator = testing.allocator;
    const script_bytes = [_]u8{0x00};
    const script = Script.init(&script_bytes);

    var engine = Engine.init(allocator, script, ScriptFlags{});
    defer engine.deinit();

    try op1Negate(&engine);

    const result = try engine.stack.popInt();
    try testing.expectEqual(@as(i64, -1), result);
}
