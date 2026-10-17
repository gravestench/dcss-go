local categories = require("constants.catalog")
local content = require("policy.catalog")
local removed = require("constants.trap_removed")

local traps = {}

local function origin(definition)
    local okay, path = pcall(register.origin,
        categories.TRAPS, definition.id)

    return okay and path or "trap " .. tostring(definition.id)
end

local function fail(definition, reason)
    error(origin(definition) .. ": " .. reason)
end

function traps.definition(definition)
    if type(definition.id) ~= "string" or
        not definition.id:match("^TRAP_[A-Z0-9_]+$") then
        fail(definition, "invalid trap ID")
    end

    if removed[definition.id] then
        fail(definition, "removed trap ID " .. definition.id)
    end

    if type(definition.name) ~= "string" or definition.name == "" then
        fail(definition, "trap requires a name")
    end

    if definition.glyph ~= "^" then
        fail(definition, "trap glyph must be ^")
    end

    if type(definition.regular) ~= "boolean" then
        fail(definition, "trap regular flag must be boolean")
    end

    if definition.one_shot ~= nil and
        type(definition.one_shot) ~= "boolean" then
        fail(definition, "trap one_shot flag must be boolean")
    end

    local lifetime = definition.lifetime_turns

    if lifetime then
        if definition.one_shot or type(lifetime) ~= "table" or
            type(lifetime.minimum) ~= "number" or
            lifetime.minimum < 1 or lifetime.minimum % 1 ~= 0 or
            type(lifetime.random) ~= "number" or
            lifetime.random < 1 or lifetime.random % 1 ~= 0 then
            fail(definition, "trap lifetime must have positive integer bounds")
        end
    end

    local effect = definition.effect

    if type(effect) ~= "string" or
        not effect:match("^policy%.traps%.effects%.[a-z0-9_]+$") then
        fail(definition, "trap effect must name a trap effect module")
    end

    local path = effect:gsub("%.", "/") .. ".lua"
    local found = pcall(mod.read, path)

    if not found then
        fail(definition, "missing trap effect " .. path)
    end

    local loaded, module = pcall(require, effect)

    if not loaded or type(module) ~= "table" or
        type(module.trigger) ~= "function" then
        fail(definition, "trap effect has no trigger method " .. path)
    end
end

function traps.validate()
    for _, definition in ipairs(content.all(categories.TRAPS)) do
        traps.definition(definition)
    end
end

return traps
