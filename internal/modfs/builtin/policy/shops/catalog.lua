local categories = require("constants.catalog")
local content = require("policy.catalog")
local ids = require("ids.shops")

local shops = {}

local removed = {
    [ids.SHOP_EVOKABLES] = true,
    [ids.SHOP_FOOD] = true,
    [ids.SHOP_UNASSIGNED] = true,
    [ids.SHOP_RANDOM] = true,
}

-- Attach the winning source path to validation errors so a modder can find
-- the exact overlay file that supplied a malformed shop definition.
local function fail(definition, reason)
    local id = type(definition) == "table" and definition.id or nil
    local okay, origin = pcall(register.origin, categories.SHOPS, id)
    local source = okay and origin or "shop " .. tostring(id)

    error(source .. ": " .. reason)
end

-- Require whole positive weights and counts; fractional weights would alter
-- the integer draw bounds used by the shop RNG stream.
local function positive_integer(value)
    return type(value) == "number" and value > 0 and value % 1 == 0
end

-- Shop definitions validate stock and pricing fields before generation uses them.
-- Example: shops.definition(shop_kind) rejects a stock class with an invalid generation weight.
function shops.definition(definition)
    if type(definition) ~= "table" or
        type(definition.id) ~= "string" or
        not definition.id:match("^SHOP_[A-Z0-9_]+$") or
        removed[definition.id] then
        fail(definition, "invalid active shop ID")
    end

    if type(definition.name) ~= "string" or definition.name == "" then
        fail(definition, "shop requires a name")
    end

    if type(definition.identifies_stock) ~= "boolean" then
        fail(definition, "shop requires identification policy")
    end

    if not positive_integer(definition.generation_weight) then
        fail(definition, "shop requires positive generation weight")
    end

    local weights = definition.class_weights

    if type(weights) ~= "table" or #weights == 0 then
        fail(definition, "shop requires stock class weights")
    end

    for _, row in ipairs(weights) do
        if type(row) ~= "table" or
            type(row.class) ~= "string" or
            not row.class:match("^OBJ_[A-Z0-9_]+$") or
            not positive_integer(row.weight) then
            fail(definition, "shop has invalid stock class weight")
        end
    end
end

-- Validate every effective definition at boot, before any level attempts to
-- place a shop and before a malformed stock pool can consume seeded draws.
function shops.validate()
    for _, definition in ipairs(content.all(categories.SHOPS)) do
        shops.definition(definition)
    end
end

return shops
