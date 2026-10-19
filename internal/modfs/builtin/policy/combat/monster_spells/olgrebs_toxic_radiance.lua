-- Olgreb's Toxic Radiance starts a saved aura on its monster caster.
-- Source: mon-cast.cc and spl-damage.cc:cast_toxic_radiance.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local display = require("policy.combat.monster_support.display")
local monster_stats = require("policy.combat.monster_stats")
local radiance = require("policy.combat.monster_area.toxic_radiance")
local self_target = require("policy.combat.monster_support.self_target")
local senses = require("policy.character.senses")
local streams = require("constants.rng_streams")

local effect = {}
local POWER_PER_HD = 8
local AUT_PER_TURN = 10

-- A running aura is not recast. Eligibility asks the same victim policy
-- that will be used at the immediate pulse and on later caster actions.
function effect.plan(ctx, caster)
    if ctx:has(caster, component.MONSTER_TOXIC_RADIANCE) or
        #radiance.victims(ctx, caster) == 0 then
        return nil
    end

    return self_target.plan(caster)
end

-- Cast power determines duration, while each pulse uses the monster's
-- ordinary HD. Aura of Brilliance can lengthen the cast without changing
-- the body-based damage of the resulting radiance.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local spell_hd = monster_stats.spell_hit_dice(ctx, caster, definition)
    local body_hd = monster_stats.hit_dice(ctx, caster, definition)
    local power = spell_hd * POWER_PER_HD
    local spread = math.floor(power / 15)
    local extra = 0

    if spread > 0 then
        extra = math.floor((
            ctx:random(streams.MONSTER_SPELL, spread) +
            ctx:random(streams.MONSTER_SPELL, spread)) / 2)
    end

    ctx:add(caster, component.MONSTER_TOXIC_RADIANCE, {
        remaining_aut = (4 + extra) * AUT_PER_TURN,
        power = body_hd * POWER_PER_HD,
    })

    if senses.player_sees_actor(ctx, caster) then
        ctx:emit(channels.SPELL,
            "The " .. display.name(ctx, caster) ..
                " begins to radiate toxic energy.")
    end

    radiance.pulse(ctx, caster, body_hd * POWER_PER_HD)
end

return effect
