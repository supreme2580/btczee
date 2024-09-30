const std = @import("std");
const Allocator = std.mem.Allocator;

pub const AlertMessage = struct {
    version: i32,
    relay_until: i64,
    expiration: i64,
    id: i32,
    cancel: i32,
    set_cancel: []i32,
    min_ver: i32,
    max_ver: i32,
    set_sub_ver: [][]const u8,
    priority: i32,
    comment: []const u8,
    status_bar: []const u8,
    reserved: []const u8,

    pub fn name() *const [12]u8 {
        return "alert\x00\x00\x00\x00\x00\x00\x00";
    }

    pub fn checksum(self: *const AlertMessage) [4]u8 {
        var hasher = std.crypto.hash.sha2.Sha256.init(.{});
        hasher.update(std.mem.asBytes(&self.version));
        hasher.update(std.mem.asBytes(&self.relay_until));
        hasher.update(std.mem.asBytes(&self.expiration));
        hasher.update(std.mem.asBytes(&self.id));
        hasher.update(std.mem.asBytes(&self.cancel));
        for (self.set_cancel) |cancel_id| {
            hasher.update(std.mem.asBytes(&cancel_id));
        }
        hasher.update(std.mem.asBytes(&self.min_ver));
        hasher.update(std.mem.asBytes(&self.max_ver));
        for (self.set_sub_ver) |sub_ver| {
            hasher.update(sub_ver);
        }
        hasher.update(std.mem.asBytes(&self.priority));
        hasher.update(self.comment);
        hasher.update(self.status_bar);
        hasher.update(self.reserved);

        var hash: [32]u8 = undefined;
        hasher.final(&hash);

        var result: [4]u8 = undefined;
        @memcpy(&result, hash[0..4]);
        return result;
    }

    pub fn serialize(self: *const AlertMessage, allocator: Allocator) ![]u8 {
        var list = std.ArrayList(u8).init(allocator);
        errdefer list.deinit();

        try list.writer().writeIntLittle(i32, self.version);
        try list.writer().writeIntLittle(i64, self.relay_until);
        try list.writer().writeIntLittle(i64, self.expiration);
        try list.writer().writeIntLittle(i32, self.id);
        try list.writer().writeIntLittle(i32, self.cancel);

        try list.writer().writeIntLittle(u32, @intCast(self.set_cancel.len));
        for (self.set_cancel) |cancel_id| {
            try list.writer().writeIntLittle(i32, cancel_id);
        }

        try list.writer().writeIntLittle(i32, self.min_ver);
        try list.writer().writeIntLittle(i32, self.max_ver);

        try list.writer().writeIntLittle(u32, @intCast(self.set_sub_ver.len));
        for (self.set_sub_ver) |sub_ver| {
            try list.writer().writeIntLittle(u32, @intCast(sub_ver.len));
            try list.writer().writeAll(sub_ver);
        }

        try list.writer().writeIntLittle(i32, self.priority);
        try list.writer().writeIntLittle(u32, @intCast(self.comment.len));
        try list.writer().writeAll(self.comment);
        try list.writer().writeIntLittle(u32, @intCast(self.status_bar.len));
        try list.writer().writeAll(self.status_bar);
        try list.writer().writeIntLittle(u32, @intCast(self.reserved.len));
        try list.writer().writeAll(self.reserved);

        return list.toOwnedSlice();
    }

    pub fn deserializeReader(allocator: Allocator, reader: anytype) !AlertMessage {
        var msg = AlertMessage{
            .version = try reader.readIntLittle(i32),
            .relay_until = try reader.readIntLittle(i64),
            .expiration = try reader.readIntLittle(i64),
            .id = try reader.readIntLittle(i32),
            .cancel = try reader.readIntLittle(i32),
            .set_cancel = undefined,
            .min_ver = undefined,
            .max_ver = undefined,
            .set_sub_ver = undefined,
            .priority = undefined,
            .comment = undefined,
            .status_bar = undefined,
            .reserved = undefined,
        };

        const set_cancel_len = try reader.readIntLittle(u32);
        msg.set_cancel = try allocator.alloc(i32, set_cancel_len);
        for (msg.set_cancel) |*cancel_id| {
            cancel_id.* = try reader.readIntLittle(i32);
        }

        msg.min_ver = try reader.readIntLittle(i32);
        msg.max_ver = try reader.readIntLittle(i32);

        const set_sub_ver_len = try reader.readIntLittle(u32);
        msg.set_sub_ver = try allocator.alloc([]const u8, set_sub_ver_len);
        for (msg.set_sub_ver) |*sub_ver| {
            const sub_ver_len = try reader.readIntLittle(u32);
            sub_ver.* = try allocator.alloc(u8, sub_ver_len);
            try reader.readNoEof(sub_ver.*);
        }

        msg.priority = try reader.readIntLittle(i32);

        const comment_len = try reader.readIntLittle(u32);
        msg.comment = try allocator.alloc(u8, comment_len);
        try reader.readNoEof(msg.comment);

        const status_bar_len = try reader.readIntLittle(u32);
        msg.status_bar = try allocator.alloc(u8, status_bar_len);
        try reader.readNoEof(msg.status_bar);

        const reserved_len = try reader.readIntLittle(u32);
        msg.reserved = try allocator.alloc(u8, reserved_len);
        try reader.readNoEof(msg.reserved);

        return msg;
    }

    pub fn deinit(self: *const AlertMessage, allocator: Allocator) void {
        allocator.free(self.set_cancel);
        for (self.set_sub_ver) |sub_ver| {
            allocator.free(sub_ver);
        }
        allocator.free(self.set_sub_ver);
        allocator.free(self.comment);
        allocator.free(self.status_bar);
        allocator.free(self.reserved);
    }

    pub fn hintSerializedLen(self: *const AlertMessage) usize {
        var len: usize = 0;
        len += @sizeOf(i32) * 5; // version, id, cancel, min_ver, max_ver
        len += @sizeOf(i64) * 2; // relay_until, expiration
        len += @sizeOf(u32) * 5; // set_cancel_len, set_sub_ver_len, comment_len, status_bar_len, reserved_len
        len += self.set_cancel.len * @sizeOf(i32);
        for (self.set_sub_ver) |sub_ver| {
            len += @sizeOf(u32) + sub_ver.len;
        }
        len += self.comment.len;
        len += self.status_bar.len;
        len += self.reserved.len;
        return len;
    }
};
