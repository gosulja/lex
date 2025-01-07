const std = @import("std");

pub const token_type = enum {
    identifier,
    number,
    string,
    symbol,
    ws, // whitespace
    eof,
};

pub const token = struct {
    type: token_type,
    value: []const u8,
    line: usize,
    col: usize,
};

pub const lex = struct {
    src: []const u8,
    pos: usize,
    line: usize,
    col: usize,
    alloc: std.mem.Allocator,

    const Self = @This();

    pub fn init(src: []const u8, alloctr: std.mem.Allocator) Self {
        return Self{
            .src = src,
            .pos = 0,
            .line = 1,
            .col = 1,
            .alloc = alloctr,
        };
    }

    pub fn next(self: *Self) !?token {
        if (self.pos >= self.src.len) {
            return token{
                .type = .eof,
                .value = "",
                .line = self.line,
                .col = self.col,
            };
        }

        // skip ws
        while (self.pos < self.src.len and std.ascii.isWhitespace(self.src[self.pos])) {
            if (self.src[self.pos] == '\n') {
                self.line += 1;
                self.col = 1;
            } else {
                self.col += 1;
            }

            self.pos += 1;
        }

        const start_p = self.pos;
        const start_l = self.line;
        const start_c = self.col;

        if (self.pos >= self.src.len) {
            return token{ .type = .eof, .value = "", .line = start_l, .col = start_c };
        }

        const c = self.src[self.pos];
        self.pos += 1;
        self.col += 1;

        if (std.ascii.isAlphabetic(c)) {
            while (self.pos < self.src.len and
                (std.ascii.isAlphanumeric(self.src[self.pos]) or
                self.src[self.pos] == '_'))
            {
                self.pos += 1;
                self.col += 1;
            }

            return token{ .type = .identifier, .value = self.src[start_p..self.pos], .line = start_l, .col = start_c };
        }

        if (std.ascii.isDigit(c)) {
            while (self.pos < self.src.len and std.ascii.isDigit(self.src[self.pos])) {
                self.pos += 1;
                self.col += 1;
            }

            return token{
                .type = .number,
                .value = self.src[start_p..self.pos],
                .line = start_l,
                .col = start_c,
            };
        }

        return token{
            .type = .symbol,
            .value = self.src[start_p..self.pos],
            .line = self.line,
            .col = self.col,
        };
    }
};

test "basic" {
    const testing = std.testing;

    const source = "abc123 +";
    var lexer = lex.init(source, testing.allocator);

    const tok1 = try lexer.next();
    try testing.expectEqual(token_type.identifier, tok1.?.type);
    try testing.expectEqualStrings("abc123", tok1.?.value);

    const tok2 = try lexer.next();
    try testing.expectEqual(token_type.symbol, tok2.?.type);
    try testing.expectEqualStrings("+", tok2.?.value);

    const tok3 = try lexer.next();
    try testing.expectEqual(token_type.eof, tok3.?.type);
}
