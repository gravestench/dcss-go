-- Theory of operation: a surviving monster hit may make Xom eject a
-- short-lived shower of butterflies. The source gates on final HP loss,
-- rolls the chance before the count, and saves ordinary summon ownership.
local attitudes = require("constants.attitude")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local gods = require("constants.gods")
local monsters = require("ids.monsters")
local order = require("constants.damage_reaction_order")
local reactions = require("policy.combat.player_damage_reactions")
local streams = require("constants.rng_streams")

local xom_hit = {}

-- The source's monster-by-mid test excludes self-harm and nonmonster
-- hazards before any random draw. A surviving hit is supplied by health.
function xom_hit.on_damage(ctx, player, damage, _, attacker)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if not worship or worship.god_id ~= gods.XOM or
        not attacker or attacker == player or
        not ctx:has(attacker, component.ACTOR) then
        return 0
    end

    local health = ctx:get(player, component.HEALTH)

    if not health or health.max <= 0 then
        error("Xom butterfly ejection requires player health")
    end

    if damage < math.floor(health.max / 4) or
        ctx:random(streams.RELIGION, 3 * health.max) >= damage then
        return 0
    end

    local count = 2 + ctx:random(streams.RELIGION, 5)
    local summons = require("policy.magic.effects.summons.common")
    local attacker_health = ctx:get(attacker, component.HEALTH)
    local foe_alive = attacker_health and attacker_health.current > 0
    local created = 0

    for _ = 1, count do
        local entity = summons.spawn(ctx, player, gods.XOM,
            monsters.MONS_BUTTERFLY, 2, nil, {
                attitude = attitudes.FRIENDLY,
                source_category = categories.GODS,
                stream = streams.RELIGION,
                silent_failure = true,
            })

        if entity then
            created = created + 1

            if foe_alive then
                ctx:add(entity, component.SUMMON_HAUNTING, {
                    target = attacker,
                })
            end
        end
    end

    if created > 0 then
        ctx:emit(channels.RELIGION,
            "A shower of butterflies erupts from you!")
    end

    return created
end

-- Register after the Jiyva branch and before the demonic guardian, so
-- later mods can inspect the same stable source-facing reaction order.
function xom_hit.register()
    reactions.add("religion.xom.butterfly_ejection",
        order.XOM_BUTTERFLY_EJECTION, xom_hit.on_damage)
end

return xom_hit
