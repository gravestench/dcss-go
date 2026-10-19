-- A creeping inferno's death is a Fire Storm centered on its last cell.
-- Actor death owns this transition so melee, ranged damage, and spell damage
-- all produce one explosion before the dying ECS actor is destroyed.
-- Source: mon-explode.cc:_setup_inferno_explosion, spl-damage.cc.
local beams = require("policy.combat.monster_beams.damage")
local calculators = require("policy.combat.monster_beams.calculators")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local death_hooks = require("policy.combat.death_hooks")
local defense = require("policy.combat.monster_defense")
local explosion = require("policy.combat.explosion")
local fighter = require("policy.combat.fighter")
local health_monster = require("policy.combat.monster_health")
local health_player = require("policy.combat.player_health")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")
local storm = require("policy.combat.monster_spells.fire_storm")

local inferno = {}

local FIRE_STORM_POWER = 100
local RADIUS_ROLL = 1000
local BASE_RADIUS = 2
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_FIRE_STORM)

-- A fresh damage roll belongs to each reached victim, as in a source beam
-- explosion. The committed beam profile decides dice and lava resistance.
local function hit(ctx, source, target, dice)
    local raw = calculators.roll_damage(ctx, dice)
    local ac

    if ctx:has(target, component.PLAYER) then
        ac = fighter.defense(ctx).ac
    else
        local actor = ctx:get(target, component.ACTOR)
        local definition = catalog.get(categories.MONSTERS,
            actor.kind_id)

        ac = defense.armour(ctx, target, definition)
    end

    local after_armour = beams.armour(ctx, raw, ac, profile)
    local amount = beams.resisted(ctx, target, after_armour, profile)

    if ctx:has(target, component.PLAYER) then
        health_player.damage(ctx, target, amount, false, source)

        return
    end

    local health = health_monster.damage(ctx, target, amount, source)

    if health.current == 0 and targets.allied(ctx, source) and
        not ctx:has(target, component.SUMMON) then
        ctx:signal("player_kill", target)
    end
end

-- Use the surviving caster as cloud/vortex owner where possible. A natural
-- inferno still leaves the blast and clouds, but has no live summon owner.
local function cloud_owner(ctx, source)
    local summoned = ctx:get(source, component.SUMMON)

    if summoned and ctx:has(summoned.owner, component.ACTOR) then
        local health = ctx:get(summoned.owner, component.HEALTH)

        if health and health.current > 0 then
            return summoned.owner
        end
    end

    return nil
end

-- Return true to consume the inferno's corpse. The death hook runs once in
-- actor.death, after movement is removed but before the ECS entity is deleted.
function inferno.on_death(ctx, source, definition, position)
    if definition.id ~= monsters.MONS_CREEPING_INFERNO then
        return false
    end

    local radius = BASE_RADIUS +
        (ctx:random(streams.MONSTER_SPELL, RADIUS_ROLL) <
            FIRE_STORM_POWER and 1 or 0)
    local dice = calculators.damage_dice(ctx, profile,
        FIRE_STORM_POWER)
    local owner = cloud_owner(ctx, source)

    for _, cell in ipairs(explosion.cells(ctx, position.level_id,
        position.x, position.y, radius)) do
        local target = ctx:actor_at(position.level_id,
            cell.x, cell.y)

        if target then
            hit(ctx, source, target, dice)
        end

        -- Fire Storm's existing cloud aftermath has its own terrain rule.
        -- It may spawn vortices only when a living caster can own them.
        storm.after_cell(ctx, owner, nil, {
            level_id = position.level_id,
            x = cell.x,
            y = cell.y,
        })
    end

    return true
end

death_hooks.add("monster.inferno", inferno.on_death)

return inferno
