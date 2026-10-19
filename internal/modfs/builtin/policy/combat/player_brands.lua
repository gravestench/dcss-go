local brands = require("constants.weapon_brands")
local monster_health = require("policy.combat.monster_health")
local monster_drain = require("policy.combat.monster_drain")

local player_brands = {}

-- Map weapon brand IDs to effect modules and reject unknown catalog spellings early.
local function effect(id)
    local brand_id = id == "" and brands.NORMAL or id
    local name = brand_id:match("^SPWPN_([A-Z_]+)$")

    if not name then
        error("invalid player weapon brand " .. tostring(id))
    end

    local module = require("policy.combat.player_brands." .. name:lower())

    if type(module) ~= "table" or type(module.apply) ~= "function" then
        error("player weapon brand " .. brand_id .. " has no apply function")
    end

    return module
end

-- Example: player_brands.check(id) with invalid ego ID -> brand validation error
-- Resolve a brand module before an item can enter the player attack path.
function player_brands.check(id)
    effect(id)
end

-- Signal a player kill only on the live-to-dead transition, after monster health is updated.
function player_brands.damage(ctx, hit, amount)
    local before = hit.health.current
    hit.health = monster_health.damage(ctx, hit.defender, amount, hit.attacker)

    if before > 0 and hit.health.current == 0 then
        ctx:signal("player_kill", hit.defender)
    end

    return hit.health
end

-- Scale negative-energy brand damage by monster drain resistance before applying it.
function player_brands.negative(ctx, hit, raw)
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
function player_brands.apply(ctx, id, hit)
    local module = effect(id)

    if hit.health.current <= 0 and not module.after_death then
        return hit
    end

    if hit.damage_done <= 0 and module.requires_damage then
        return hit
    end

    module.apply(ctx, hit, player_brands)

    return hit
end

-- Some brands act once per swing even when damage handling already ended the target.
function player_brands.after_attack(ctx, id, hit)
    local module = effect(id)

    if module.after_attack then
        module.after_attack(ctx, hit)
    end
end

return player_brands
