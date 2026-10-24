local brands = require("constants.weapon_brands")
local monster_health = require("policy.combat.monster_health")
local monster_drain = require("policy.combat.monster_drain")
local component = require("constants.component")

local target_brands = {}

-- Map weapon brand IDs to effect modules and reject unknown catalog spellings early.
local function effect(id)
    local brand_id = id == "" and brands.NORMAL or id
    local name = brand_id:match("^SPWPN_([A-Z_]+)$")

    if not name then
        error("invalid monster-target weapon brand " .. tostring(id))
    end

    local module = require("policy.combat.monster_target_brands." .. name:lower())

    if type(module) ~= "table" or type(module.apply) ~= "function" then
        error("monster-target weapon brand " .. brand_id ..
            " has no apply function")
    end

    return module
end

-- Validate a brand before a weapon reaches either attacker path.
function target_brands.check(id)
    effect(id)
end

-- Messages name the real wielder. A ghost without an item still has its
-- captured brand, so describe its attack rather than inventing a weapon.
function target_brands.subject(ctx, hit)
    if ctx:has(hit.attacker, component.PLAYER) then
        if hit.projectile_name then
            return "The " .. hit.projectile_name
        end

        return "Your weapon"
    end

    local suffix = hit.weapon_entity and "'s weapon" or "'s attack"

    return "The " .. hit.attacker_name .. suffix
end

-- Credit a kill only to the player or a credited ally. Hostile-on-friendly
-- brand damage must not award experience merely because the target died.
function target_brands.damage(ctx, hit, amount)
    local before = hit.health.current
    hit.health = monster_health.damage(ctx, hit.defender, amount, hit.attacker)

    local credit = hit.player_credit

    if credit == nil then
        credit = ctx:has(hit.attacker, component.PLAYER)
    end

    if credit and before > 0 and hit.health.current == 0 then
        ctx:signal("player_kill", hit.defender)
    end

    return hit.health
end

-- Scale negative-energy brand damage by monster drain resistance before applying it.
function target_brands.negative(ctx, hit, raw)
    local resistance = monster_drain.resistance(ctx, hit.defender,
        hit.definition)

    if resistance >= 3 then
        return 0
    end

    if resistance > 0 then
        return math.floor(raw / (1 + resistance * resistance))
    end

    if resistance < 0 then
        return math.floor(raw * 15 / 10)
    end

    return raw
end

-- Dead-target and zero-damage gates are brand-specific; postmortem effects opt in through module flags.
function target_brands.apply(ctx, id, hit)
    local module = effect(id)

    if hit.health.current <= 0 and not module.after_death then
        return hit
    end

    if hit.damage_done <= 0 and module.requires_damage then
        return hit
    end

    module.apply(ctx, hit, target_brands)

    return hit
end

-- Some brands act once per swing even when damage handling already ended the target.
function target_brands.after_attack(ctx, id, hit)
    local module = effect(id)

    if module.after_attack then
        module.after_attack(ctx, hit)
    end
end

return target_brands
