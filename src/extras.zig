const std = @import("std");
const c = @import("c.zig");
const xml = @import("xml.zig");
const mem = std.mem;
const Allocator = mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const ArrayList = std.ArrayList;

const ns = "https://ianjohnson.dev/zig-gobject/extras";

pub const Repository = struct {
    namespaces: []const Namespace,
    arena: ArenaAllocator,

    pub fn parseFile(allocator: Allocator, file: [:0]const u8) !Repository {
        const doc = xml.parseFile(file) catch return error.InvalidExtras;
        defer c.xmlFreeDoc(doc);
        return try parseDoc(allocator, doc);
    }

    pub fn deinit(self: *Repository) void {
        self.arena.deinit();
    }

    fn parseDoc(a: Allocator, doc: *c.xmlDoc) !Repository {
        var arena = ArenaAllocator.init(a);
        const allocator = arena.allocator();
        const node: *c.xmlNode = c.xmlDocGetRootElement(doc) orelse return error.InvalidExtras;

        var namespaces = ArrayList(Namespace).init(allocator);

        var maybe_child: ?*c.xmlNode = node.children;
        while (maybe_child) |child| : (maybe_child = child.next) {
            if (xml.nodeIs(child, ns, "namespace")) {
                try namespaces.append(try parseNamespace(allocator, doc, child));
            }
        }

        return .{
            .namespaces = namespaces.items,
            .arena = arena,
        };
    }
};

pub const Namespace = struct {
    name: []const u8,
    version: []const u8,
    functions: []const Function,
};

fn parseNamespace(allocator: Allocator, doc: *c.xmlDoc, node: *const c.xmlNode) !Namespace {
    var name: ?[]const u8 = null;
    var version: ?[]const u8 = null;
    var functions = ArrayList(Function).init(allocator);

    var maybe_attr: ?*c.xmlAttr = node.properties;
    while (maybe_attr) |attr| : (maybe_attr = attr.next) {
        if (xml.attrIs(attr, null, "name")) {
            name = try xml.attrContent(allocator, doc, attr);
        } else if (xml.attrIs(attr, null, "version")) {
            version = try xml.attrContent(allocator, doc, attr);
        }
    }

    var maybe_child: ?*c.xmlNode = node.children;
    while (maybe_child) |child| : (maybe_child = child.next) {
        if (xml.nodeIs(child, ns, "function")) {
            try functions.append(try parseFunction(allocator, doc, child));
        }
    }

    return .{
        .name = name orelse return error.InvalidExtras,
        .version = version orelse return error.InvalidExtras,
        .functions = functions.items,
    };
}

pub const Function = struct {
    name: []const u8,
    parameters: []const Parameter,
    return_value: ReturnValue,
    body: []const u8,
};

fn parseFunction(allocator: Allocator, doc: *c.xmlDoc, node: *const c.xmlNode) !Function {
    var name: ?[]const u8 = null;
    var parameters = ArrayList(Parameter).init(allocator);
    var return_value: ?ReturnValue = null;
    var body: ?[]const u8 = null;

    var maybe_attr: ?*c.xmlAttr = node.properties;
    while (maybe_attr) |attr| : (maybe_attr = attr.next) {
        if (xml.attrIs(attr, null, "name")) {
            name = try xml.attrContent(allocator, doc, attr);
        }
    }

    var maybe_child: ?*c.xmlNode = node.children;
    while (maybe_child) |child| : (maybe_child = child.next) {
        if (xml.nodeIs(child, ns, "parameter")) {
            try parameters.append(try parseParameter(allocator, doc, child));
        } else if (xml.nodeIs(child, ns, "return-value")) {
            return_value = try parseReturnValue(allocator, doc, child);
        } else if (xml.nodeIs(child, ns, "body")) {
            body = try xml.nodeContent(allocator, doc, child.children);
        }
    }

    return .{
        .name = name orelse return error.InvalidExtras,
        .parameters = parameters.items,
        .return_value = return_value orelse return error.InvalidExtras,
        .body = body orelse return error.InvalidExtras,
    };
}

pub const Parameter = struct {
    name: []const u8,
    type: []const u8,
    @"comptime": bool,
};

fn parseParameter(allocator: Allocator, doc: *c.xmlDoc, node: *const c.xmlNode) !Parameter {
    var name: ?[]const u8 = null;
    var @"type": ?[]const u8 = null;
    var @"comptime": bool = false;

    var maybe_attr: ?*c.xmlAttr = node.properties;
    while (maybe_attr) |attr| : (maybe_attr = attr.next) {
        if (xml.attrIs(attr, null, "name")) {
            name = try xml.attrContent(allocator, doc, attr);
        } else if (xml.attrIs(attr, null, "type")) {
            @"type" = try xml.attrContent(allocator, doc, attr);
        } else if (xml.attrIs(attr, null, "comptime")) {
            @"comptime" = std.mem.eql(u8, try xml.attrContent(allocator, doc, attr), "1");
        }
    }

    return .{
        .name = name orelse return error.InvalidExtras,
        .type = @"type" orelse return error.InvalidExtras,
        .@"comptime" = @"comptime",
    };
}

pub const ReturnValue = struct {
    type: []const u8,
};

fn parseReturnValue(allocator: Allocator, doc: *c.xmlDoc, node: *const c.xmlNode) !ReturnValue {
    var @"type": ?[]const u8 = null;

    var maybe_attr: ?*c.xmlAttr = node.properties;
    while (maybe_attr) |attr| : (maybe_attr = attr.next) {
        @"type" = try xml.attrContent(allocator, doc, attr);
    }

    return .{
        .type = @"type" orelse return error.InvalidExtras,
    };
}
