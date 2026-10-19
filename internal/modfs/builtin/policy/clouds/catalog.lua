local categories = require("constants.catalog")
local content = require("policy.catalog")
local colors = require("policy.presentation.colors")

local clouds = {}

-- A bad cloud definition reports the winning VFS file when available.
local function origin(definition)
    local okay, path = pcall(register.origin,
        categories.CLOUDS, definition.id)

    return okay and path or "cloud " .. tostring(definition.id)
end

-- Stop catalog validation with the cloud's source location.
local function fail(definition, reason)
    error(origin(definition) .. ": " .. reason)
end

-- Cloud timing and damage metadata must be integral and nonnegative.
local function nonnegative_integer(value)
    return type(value) == "number" and
        value >= 0 and value % 1 == 0
end

-- Cloud definitions need a valid effect module and nonnegative timing fields before placement can use them.
function clouds.definition(definition)
    if type(definition.id) ~= "string" or
        not definition.id:match("^CLOUD_[A-Z0-9_]+$") then
        fail(definition, "invalid cloud ID")
    end

    if type(definition.name) ~= "string" or
        definition.name == "" then
        fail(definition, "cloud requires a name")
    end

    if type(definition.color) ~= "string" or
        definition.color == "" then
        fail(definition, "cloud requires a color")
    end

    local console_color = definition.console_color or definition.color

    if colors.source[console_color] == nil then
        fail(definition, "cloud has unknown console color " ..
            tostring(console_color))
    end

    if type(definition.opaque) ~= "boolean" then
        fail(definition, "cloud requires opacity")
    end

    if type(definition.harmless) ~= "boolean" then
        fail(definition, "cloud requires harmless classification")
    end

    if not nonnegative_integer(definition.spread_rate) or
        definition.spread_rate > 100 then
        fail(definition, "cloud requires a spread rate from 0 to 100")
    end

    local damage = definition.damage

    if type(damage) ~= "table" or
        not nonnegative_integer(damage.base) or
        not nonnegative_integer(damage.random) or
        type(damage.extra_player) ~= "boolean" then
        fail(definition, "cloud requires source damage metadata")
    end

    local effect = definition.effect

    if type(effect) ~= "string" or
        not effect:match("^policy%.clouds%.effects%.[a-z0-9_]+$") then
        fail(definition, "cloud requires an effect module")
    end

    local path = effect:gsub("%.", "/") .. ".lua"
    local exists = pcall(mod.read, path)

    if not exists then
        fail(definition, "missing cloud effect " .. path)
    end

    local loaded, module = pcall(require, effect)

    if not loaded or type(module) ~= "table" or
        type(module.apply) ~= "function" then
        fail(definition, "cloud effect has no apply method " .. path)
    end
end

-- Validate every cloud at boot, before a field tick tries to load its effect module.
-- Example: a cloud definition naming a missing effect module fails validation before turn simulation.
function clouds.validate()
    for _, definition in ipairs(content.all(categories.CLOUDS)) do
        clouds.definition(definition)
    end
end

return clouds
