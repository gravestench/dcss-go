-- Monster Vampiric Draining is an adjacent life theft, not a travelling ray.
-- Source: mon-cast.cc spell_to_logic and beam.cc:_vampiric_draining_effect.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local display = require("policy.combat.monster_support.display")
local life = require("policy.combat.life_transfer")
local monster_stats = require("policy.combat.monster_stats")
local senses = require("policy.character.senses")
local target = require("policy.combat.monster_spell_target")
local target_kind = require("constants.target_kind")
local streams = require("constants.rng_streams")

local effect = {}

-- Source casts only against an adjacent body with extractable life and less
-- than full negative-energy immunity. The saved plan binds that exact foe.
function effect.plan(ctx, caster, foe)
    local source = ctx:get(caster, component.POSITION)
    local destination = foe and ctx:get(foe, component.POSITION)

    if not source or not destination or
        source.level_id ~= destination.level_id or
        math.max(math.abs(source.x - destination.x),
            math.abs(source.y - destination.y)) > 1 or
        not life.susceptible(ctx, foe) or
        life.resistance(ctx, foe) >= 3 then
        return nil
    end

    return {
        kind = target_kind.ENTITY,
        entity = foe,
    }
end

-- Roll the source monster dice on the saved spell stream. Monster spell HD
-- changes the side count, while each successful cast always rolls two dice.
local function raw_damage(ctx, caster)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local hd = monster_stats.spell_hit_dice(ctx, caster, definition)
    local power = math.min(200, hd * 12)
    local sides = 6 + math.floor(power / 14)

    return 2 + ctx:random(streams.MONSTER_SPELL, sides) +
        ctx:random(streams.MONSTER_SPELL, sides)
end

-- Recheck the saved adjacent actor before HP transfer. The caster heals by
-- two thirds of damage actually removed, as monsters do in source DCSS.
function effect.resolve(ctx, caster, foe, _, plan)
    target.require_entity(plan, foe)

    if not effect.plan(ctx, caster, foe) then
        error("Vampiric Draining target is no longer adjacent or susceptible")
    end

    local dealt = life.hurt(ctx, caster, foe, raw_damage(ctx, caster))

    if dealt <= 0 then
        return 0
    end

    local gained = life.heal(ctx, caster,
        math.floor(dealt * 2 / 3))

    if ctx:has(foe, component.PLAYER) then
        ctx:emit(channels.SPELL, "The " .. display.name(ctx, caster) ..
            " draws life force from you!")
    elseif senses.player_sees_actor(ctx, foe) or
        senses.player_sees_actor(ctx, caster) then
        ctx:emit(channels.SPELL, "The " .. display.name(ctx, caster) ..
            " draws life force from the " .. display.name(ctx, foe) .. ".")
    end

    if gained > 0 and senses.player_sees_actor(ctx, caster) then
        ctx:emit(channels.SPELL, "The " .. display.name(ctx, caster) ..
            " is healed by the life force!")
    end

    return dealt
end

return effect
