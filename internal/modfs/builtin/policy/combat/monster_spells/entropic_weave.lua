-- Source: mon-cast.cc:SPELL_ENTROPIC_WEAVE. This is a direct spell on the
-- selected foe, not a ray and not an acid damage roll.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local channels = require("constants.message_channels")
local direct = require("policy.combat.monster_direct")
local enchant = require("policy.combat.monster_enchant")
local player_corrosion = require("policy.combat.player_corrosion")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local effect = {}

-- A clear line of sight and source spell range are enough to plan this
-- direct affliction; the target's corrosion resistance resolves later.
function effect.plan(ctx, caster, foe)
    if not foe then
        return nil
    end

    return direct.plan(ctx, caster, foe,
        spells.SPELL_ENTROPIC_WEAVE)
end

-- The player and monsters keep distinct saved corrosion owners. Both use
-- the source equipment-corrosion check, which differs from acid splash.
function effect.resolve(ctx, caster, foe, _, plan)
    direct.require(ctx, caster, foe, plan)

    if ctx:has(foe, component.PLAYER) then
        player_corrosion.corrode_equipment(ctx, foe,
            "The entropic weave", streams.MONSTER_SPELL,
            channels.SPELL)

        return
    end

    local actor = ctx:get(foe, component.ACTOR)

    if not actor then
        return
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    enchant.corrode_equipment(ctx, foe, definition,
        "The entropic weave")
end

return effect
