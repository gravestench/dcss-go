local brands = require("constants.weapon_brands")

local launcher_brands = {}

-- Resolve a launcher brand ID to its damage module while rejecting unknown egos.
local function effect(id)
    local brand_id = id == "" and brands.NORMAL or id
    local name = brand_id:match("^SPWPN_([A-Z_]+)$")

    if not name then
        error("invalid launcher brand " .. tostring(id))
    end

    local module = require("policy.combat.launcher_brands." .. name:lower())

    if type(module) ~= "table" or type(module.apply) ~= "function" then
        error("launcher brand " .. brand_id .. " has no apply function")
    end

    return module
end

-- Example: launcher_brands.check(id) with invalid launcher ego -> validation error
-- Validate a launcher ego by resolving its module before missiles are fired.
function launcher_brands.check(id)
    effect(id)
end

-- Launcher brands only add damage after a missile deals positive base damage.
function launcher_brands.apply(ctx, id, missile, defender, damage,
    target, attacker, health, weapon_entity)
    if damage <= 0 then
        return 0
    end

    return effect(id).apply(ctx, missile, defender, damage,
        target, attacker, health, weapon_entity)
end

return launcher_brands
