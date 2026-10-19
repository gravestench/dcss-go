-- Corrupting Pulse applies temporary mutations to an enemy player and
-- wretchedness to enemy monsters through their existing saved owners.
-- Source: mon-cast.cc:_corrupting_pulse.
local actors = require("policy.combat.monster_area.actors")
local catalog = require("policy.catalog")
local channels = require("constants.message_channels")
local choices = require("constants.mutation_choices")
local classes = require("constants.mutation_classes")
local component = require("constants.component")
local irradiate = require("policy.combat.monster_area.irradiate")
local self_target = require("policy.combat.monster_support.self_target")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")
local transition = require("policy.mutations.transition")

local effect = {}
local SIGHT_RADIUS = 7

-- The player follows the ordinary hostile-foe rule. Monsters use source
-- alignment, which also makes neutral actors valid pulse recipients.
local function vulnerable(ctx, caster, target)
    if ctx:has(target, component.PLAYER) then
        return targets.enemy(ctx, caster, target)
    end

    return not targets.aligned(ctx, caster, target)
end

-- One vulnerable unaligned actor makes the pulse worthwhile. The source traces the
-- same area before spending mutation rolls, so planning stays read-only.
function effect.plan(ctx, caster)
    for _, target in ipairs(actors.los(ctx, caster, SIGHT_RADIUS)) do
        if vulnerable(ctx, caster, target) then
            return self_target.plan(caster)
        end
    end

    return nil
end

-- Source processes the player before the monster loop. Keep that order so
-- the named streams replay the same sequence after a save and restore.
local function corrupt_player(ctx, caster, visible)
    local player = ctx:player()

    if not player or not visible[player] or
        not targets.enemy(ctx, caster, player) then
        return
    end

    ctx:emit(channels.SPELL, "A wave of corruption washes over you!")

    local count = ctx:random(streams.MONSTER_SPELL, 4) == 0 and 2 or 1

    for _ = 1, count do
        transition.grant_random(ctx, player, choices.CORRUPT,
            classes.TEMPORARY, false)
    end
end

-- Monster corruption reuses the Wretched component's duration and derived
-- HD/AC rules; a second independent timer would make saves disagree.
local function corrupt_monsters(ctx, caster, victims)
    for _, target in ipairs(victims) do
        if not ctx:has(target, component.PLAYER) and
            vulnerable(ctx, caster, target) then
            local actor = ctx:get(target, component.ACTOR)
            local definition = catalog.get("monsters", actor.kind_id)

            irradiate.wretch(ctx, target, definition,
                streams.MONSTER_SPELL)
        end
    end
end

-- Recompute live recipients after the self-targeted cast commits. A moved
-- actor may leave the pulse; no saved plan is silently retargeted.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local victims = actors.los(ctx, caster, SIGHT_RADIUS)
    local visible = {}

    for _, target in ipairs(victims) do
        visible[target] = true
    end

    corrupt_player(ctx, caster, visible)
    corrupt_monsters(ctx, caster, victims)
end

return effect
