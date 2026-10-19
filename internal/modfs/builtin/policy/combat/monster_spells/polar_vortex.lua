-- Polar Vortex starts a mobile, saved storm around its monster caster.
-- Source: mon-cast.cc:_mons_vortex and spl-vortex.cc. Player and monster
-- casts share wind geometry and damage, but keep separate cast decisions.
local actors = require("policy.combat.monster_area.actors")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local decision = require("policy.combat.monster_area.decision")
local display = require("policy.combat.monster_support.display")
local holiness = require("constants.monster_holiness")
local monster_stats = require("policy.combat.monster_stats")
local self_target = require("policy.combat.monster_support.self_target")
local senses = require("policy.character.senses")
local target_policy = require("policy.ai.targets")
local vortex = require("policy.magic.effects.zaps.polar_vortex")
local zap_ids = require("policy.magic.effects.zaps.ids")

local effect = {}
local RADIUS = 5
local FOE_RATIO = 80
local POWER_PER_HD = 4

-- Source demons may risk the player when allied; other friendly monsters
-- refuse to raise a vortex within sight of their player ally.
local function demonic(definition)
    for _, value in ipairs(definition.holiness or {}) do
        if value == holiness.DEMONIC then
            return true
        end
    end

    return false
end

-- Cooldown and the live aura are distinct source enchantments. The tracer
-- counts only susceptible actors and weighs harm to allies before casting.
function effect.plan(ctx, caster)
    if ctx:has(caster, zap_ids.component.POLAR_VORTEX) or
        ctx:has(caster, component.MONSTER_VORTEX_COOLDOWN) then
        return nil
    end

    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local source = ctx:get(caster, component.POSITION)
    local player = ctx:player()
    local player_position = player and
        ctx:get(player, component.POSITION)

    if target_policy.allied(ctx, caster) and
        not demonic(definition) and player_position and
        player_position.level_id == source.level_id and
        ctx:visible_no_trans(source.level_id,
            source.x, source.y, RADIUS,
            player_position.x, player_position.y) then
        return nil
    end

    local victims = actors.los(ctx, caster, RADIUS)

    if not decision.accept(ctx, caster, victims,
        FOE_RATIO, function(context, target)
            return vortex.immune(context, target) and 0 or 1
        end) then
        return nil
    end

    return self_target.plan(caster)
end

-- Monster vortex power uses ordinary HD, not the player spell's power or
-- monster spell HD. Flight and storm state use the same registered schemas
-- as a player cast and therefore survive save/restore without translation.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local power = monster_stats.hit_dice(ctx, caster,
        definition) * POWER_PER_HD

    vortex.start(ctx, caster, power)

    if senses.player_sees_actor(ctx, caster) then
        ctx:emit(channels.SPELL,
            "A freezing vortex appears around the " ..
                display.name(ctx, caster) .. "!")
    elseif senses.player_sees_cell(ctx,
        ctx:get(caster, component.POSITION)) then
        ctx:emit(channels.SPELL,
            "A freezing vortex appears out of thin air!")
    end
end

return effect
