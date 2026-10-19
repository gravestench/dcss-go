local flags = require("constants.monster_flags")
local component = require("constants.component")
local holiness = require("constants.monster_holiness")
local player_health = require("policy.combat.player_health")
local roll = require("policy.combat.roll")

local brand = {
    after_death = true,
    requires_damage = true,
}

-- Read holiness and threat flags before deciding whether blood healing is possible.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Summons and inert firewood cannot supply the attacker with life on contact.
local function susceptible(ctx, hit)
    local definition = hit.definition
    local living = has(definition.holiness, holiness.NATURAL) or
        has(definition.holiness, holiness.PLANT)
    local firewood = has(definition.flags, flags.STATIONARY) and
        has(definition.flags, flags.NO_THREAT)

    return living and not firewood and
        not ctx:has(hit.defender, component.SUMMON)
end

-- Example: brand.apply(ctx, hit, brands) with attacker at full HP -> no vampiric heal
-- Heal only a wounded attacker after a susceptible nonsummoned target takes a valid hit.
function brand.apply(ctx, hit, brands)
    local health = ctx:get(hit.attacker, "core.health")

    if not health or health.current >= health.max or
        not player_health.can_heal(ctx, hit.attacker) or
        not susceptible(ctx, hit) then
        return
    end

    -- Source: attack.cc. The 2/5 veto precedes the heal draw.
    if roll.melee(ctx, 5) < 2 then
        return
    end

    local raw = 1 + roll.melee(ctx, hit.damage_done)
    local healed = brands.negative(ctx, hit, raw)

    if healed <= 0 then
        return
    end

    health.current = math.min(health.max, health.current + healed)
    ctx:set(hit.attacker, "core.health", health)
    ctx:emit("combat", "You feel better.")
end

return brand
