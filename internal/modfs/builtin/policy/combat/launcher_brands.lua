local brands = require("constants.weapon_brands")

local launcher_brands = {}

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

function launcher_brands.check(id)
    effect(id)
end

function launcher_brands.apply(ctx, id, missile, defender, damage)
    if damage <= 0 then
        return 0
    end

    return effect(id).apply(ctx, missile, defender, damage)
end

return launcher_brands
