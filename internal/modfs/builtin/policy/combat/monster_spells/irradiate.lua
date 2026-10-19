-- Monster Irradiate uses the same neighboring radiation rule as the player
-- cast. The AI first weighs nearby enemies against allied collateral and
-- refuses an allied cast that would engulf an adjacent player.
-- Source: mon-cast.cc:_should_irradiate and spl-damage.cc:cast_irradiate.
-- Example: a hostile caster may contaminate the player beside it, while
-- a surviving ordinary monster gains Wretched instead.
local area = require("policy.combat.monster_area.irradiate")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local decision = require("policy.combat.monster_area.decision")
local display = require("policy.combat.monster_support.display")
local self_target = require("policy.combat.monster_support.self_target")
local senses = require("policy.character.senses")
local stats = require("policy.combat.monster_stats")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local effect = {}
local FOE_RATIO = 80
local POWER_PER_SPELL_HD = 6

-- The source adds this absolute refusal before tracing the area. Friendly
-- casters will not Irradiate in melee with the player they protect.
local function allied_player_adjacent(ctx, caster)
    if not targets.allied(ctx, caster) then
        return false
    end

    local player = ctx:player()
    local source = ctx:get(caster, component.POSITION)
    local destination = player and
        ctx:get(player, component.POSITION)

    if not source or not destination or
        source.level_id ~= destination.level_id then
        return false
    end

    return math.max(math.abs(source.x - destination.x),
        math.abs(source.y - destination.y)) <= 1
end

-- Plan a self-centered burst only if its current eight-cell footprint
-- contains enough hostile impact to justify any allied collateral.
function effect.plan(ctx, caster)
    if allied_player_adjacent(ctx, caster) or
        not decision.accept(ctx, caster,
            area.victims(ctx, caster), FOE_RATIO) then
        return nil
    end

    return self_target.plan(caster)
end

-- The source uses six power per spell HD, unlike the usual twelve.
-- Recompute live victims before applying their separate damage rolls.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS,
        actor.kind_id)
    local power = stats.spell_hit_dice(ctx,
        caster, definition) * POWER_PER_SPELL_HD

    if senses.player_sees_actor(ctx, caster) then
        ctx:emit(channels.SPELL,
            "The " .. display.name(ctx, caster) ..
                " erupts in a fountain of uncontrolled magic!")
    end

    area.resolve(ctx, caster, power, streams.MONSTER_SPELL)
end

return effect
