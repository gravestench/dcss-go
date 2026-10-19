-- Monster Refrigeration hits every other living body in LOS_NO_TRANS,
-- including allies. Crowded victims take smaller cold dice from a precast
-- snapshot, and surviving cold-blooded monsters may slow.
-- Source: mon-cast.cc and spl-damage.cc:_cast_los_attack_spell.
local actors = require("policy.combat.monster_area.actors")
local area = require("policy.combat.monster_area.refrigeration")
local beam_damage = require("policy.combat.monster_beams.damage")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local decision = require("policy.combat.monster_area.decision")
local direct = require("policy.combat.monster_direct")
local display = require("policy.combat.monster_support.display")
local exposure = require("policy.magic.effects.statuses.monster_cold_exposure")
local magic_damage = require("policy.magic.damage")
local power = require("policy.combat.monster_beams.power")
local resistances = require("constants.resistance_ids")
local self_target = require("policy.combat.monster_support.self_target")
local senses = require("policy.character.senses")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local effect = {}
local SIGHT_RADIUS = 7
local FOE_RATIO = 80
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_OZOCUBUS_REFRIGERATION)

-- Planning needs a resistance estimate without applying the player's
-- cold-blooded or icy-defence reactions before the cast actually occurs.
local function expected_impact(ctx, victim)
    if not ctx:has(victim, component.PLAYER) then
        return magic_damage.monster_elemental(ctx, victim,
            100, resistances.COLD)
    end

    local level = magic_damage.player_resistance(ctx, victim,
        resistances.COLD)

    if level > 0 then
        return math.floor(100 /
            math.floor((3 * level + 1) / 2))
    end

    return level < 0 and 150 or 100
end

-- The source refuses a LOS attack with too little enemy impact relative
-- to allies. An allied caster also avoids this spell in the player's view.
function effect.plan(ctx, caster)
    if targets.allied(ctx, caster) and
        senses.player_sees_actor(ctx, caster) then
        return nil
    end

    local victims = actors.los(ctx, caster, SIGHT_RADIUS)

    if not decision.accept(ctx, caster, victims,
        FOE_RATIO, expected_impact) then
        return nil
    end

    return self_target.plan(caster)
end

-- The zap's four-die maximum comes from capped spell power. Snapshot
-- adjacency before any hit, then apply AC, cold resistance, HP, and slow.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local source = ctx:get(caster, component.POSITION)
    local victims = actors.los(ctx, caster, SIGHT_RADIUS)
    local snapshot = area.snapshot(ctx, caster)
    local spell_power = power.caster_power(ctx, caster, profile)
    local base = area.base_sides(ctx, spell_power,
        streams.MONSTER_SPELL)

    if senses.player_sees_actor(ctx, caster) then
        ctx:emit(channels.SPELL,
            "The " .. display.name(ctx, caster) ..
                " drains the heat from the surrounding environment!")
    elseif senses.player_sees_cell(ctx, source) then
        ctx:emit(channels.SPELL,
            "The ambient heat is drained!")
    end

    for _, victim in ipairs(victims) do
        local health = ctx:get(victim, component.HEALTH)

        if health.current > 0 then
            local adjacent = area.adjacent(snapshot, victim)
            local raw = area.raw_damage(ctx, base, adjacent,
                streams.MONSTER_SPELL)
            local after_ac = direct.armour(ctx, victim, raw)
            local amount = beam_damage.resisted(ctx, victim,
                after_ac, profile)

            if amount > 0 then
                direct.damage(ctx, caster, victim, amount)
            end

            if not ctx:has(victim, component.PLAYER) then
                local surviving = ctx:get(victim, component.HEALTH)

                if surviving.current > 0 then
                    local state = ctx:get(victim, component.ACTOR)
                    local definition = catalog.get(categories.MONSTERS,
                        state.kind_id)

                    exposure.apply(ctx, victim, definition, 5,
                        streams.MONSTER_SPELL)
                end
            end
        end
    end
end

return effect
