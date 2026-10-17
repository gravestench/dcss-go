local catalog = require("policy.catalog")
local component = require("constants.component")
local monster_drain = require("policy.combat.monster_drain")
local player_drain = require("policy.combat.player_drain")

local draining = {}

-- Source: ouch.cc:check_your_resists and beam.cc:mons_adjust_flavoured.
function draining.before_damage(ctx, caster, defender, _, outcome)
    if ctx:has(defender, component.PLAYER) then
        player_drain.apply(ctx, defender, outcome.after_armour,
            "monster_spell")

        return
    end

    local actor = ctx:get(defender, component.ACTOR)
    local health = ctx:get(defender, component.HEALTH)

    if not actor or not health then
        error("draining beam defender has no actor or health")
    end

    if health.current <= 0 then
        return
    end

    local definition = catalog.get("monsters", actor.kind_id)

    monster_drain.apply(ctx, defender, definition, caster,
        "monster_spell")
end

return draining
