-- Seracfall sacrifices a visible allied simulacrum, then fires the source
-- Iceblast profile from its cell toward the caster's selected foe. The
-- donor handle and target cell cross the saved monster intent boundary.
-- Source: mon-cast.cc:_mons_seracfall_source and _prepare_seracfall.
-- Example: a donor whose blast hits a foe and an ally loses to a safer donor.
local blast = require("policy.combat.monster_beams.explosion")
local calculators = require("policy.combat.monster_beams.calculators")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local decision = require("policy.combat.monster_area.decision")
local display = require("policy.combat.monster_support.display")
local explosion = require("policy.combat.explosion")
local monster_health = require("policy.combat.monster_health")
local monsters = require("ids.monsters")
local power = require("policy.combat.monster_beams.power")
local senses = require("policy.character.senses")
local spells = require("ids.spells")
local target_kind = require("constants.target_kind")
local targets = require("policy.ai.targets")
local trajectory = require("policy.combat.trajectory")

local effect = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_SERACFALL)
local SIGHT_RADIUS = 7

-- A ball explodes at the first ray contact or the cell before a wall.
-- The killed donor is excluded because it is gone before the blast fires.
local function affected(ctx, caster, donor, origin, destination)
    local trace = trajectory.to_target(ctx, origin.level_id,
        origin.x, origin.y, destination.x, destination.y,
        SIGHT_RADIUS)
    local contact = trace.contacts[1]
    local x = contact and contact.x or trace.x
    local y = contact and contact.y or trace.y
    local victims = {}

    for _, cell in ipairs(explosion.cells(ctx, origin.level_id,
        x, y, profile.explosion_radius)) do
        local actor = ctx:actor_at(origin.level_id, cell.x, cell.y)
        local health = actor and ctx:get(actor, component.HEALTH)

        if actor and actor ~= donor and
            health and health.current > 0 then
            victims[#victims + 1] = actor
        end
    end

    return victims, trace
end

-- Compare source damage fractions without a floating-point tie. A donor
-- must hit more foe power than friend power and beat earlier candidates.
function effect.plan(ctx, caster, foe)
    local caster_pos = ctx:get(caster, component.POSITION)
    local foe_pos = foe and ctx:get(foe, component.POSITION)

    if not caster_pos or not foe_pos or
        caster_pos.level_id ~= foe_pos.level_id then
        return nil
    end

    local best
    local best_foes = 1
    local best_total = 2

    for _, donor in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        local actor = ctx:get(donor, component.ACTOR)
        local position = ctx:get(donor, component.POSITION)
        local health = ctx:get(donor, component.HEALTH)
        local distance = math.max(math.abs(position.x - caster_pos.x),
            math.abs(position.y - caster_pos.y))

        if actor.kind_id == monsters.MONS_SIMULACRUM and
            donor ~= caster and health.current > 0 and
            targets.aligned(ctx, caster, donor) and
            position.level_id == caster_pos.level_id and
            distance <= SIGHT_RADIUS and
            ctx:visible_no_trans(caster_pos.level_id,
                caster_pos.x, caster_pos.y, SIGHT_RADIUS,
                position.x, position.y) and
            senses.player_sees_cell(ctx, position) then
            local victims = affected(ctx, caster, donor,
                position, foe_pos)
            local foes, friends = decision.weights(ctx,
                caster, victims)
            local total = foes + friends

            if total > 0 and foes * best_total >
                best_foes * total then
                best = donor
                best_foes = foes
                best_total = total
            end
        end
    end

    if not best then
        return nil
    end

    return {
        kind = target_kind.CELL,
        entity = best,
        level_id = foe_pos.level_id,
        x = foe_pos.x,
        y = foe_pos.y,
        dx = foe_pos.x - caster_pos.x,
        dy = foe_pos.y - caster_pos.y,
    }
end

-- Consume exactly the planned ally before tracing the ball from its saved
-- cell. The ordinary death phase later handles that zero-HP summon.
function effect.resolve(ctx, caster, _, _, plan)
    local donor = plan and plan.entity
    local donor_state = donor and ctx:get(donor, component.ACTOR)
    local donor_pos = donor and ctx:get(donor, component.POSITION)
    local health = donor and ctx:get(donor, component.HEALTH)
    local caster_pos = ctx:get(caster, component.POSITION)

    if not plan or plan.kind ~= target_kind.CELL or
        not donor_state or not donor_pos or not health or
        health.current <= 0 or
        donor_state.kind_id ~= monsters.MONS_SIMULACRUM or
        not caster_pos or caster_pos.level_id ~= plan.level_id or
        donor_pos.level_id ~= plan.level_id or
        not targets.aligned(ctx, caster, donor) then
        error("Seracfall lost its planned simulacrum")
    end

    ctx:emit(channels.SPELL, "The " ..
        display.name(ctx, donor) .. " collapses into a mass of ice!")
    monster_health.damage(ctx, donor, health.current, caster)

    local destination = {
        level_id = plan.level_id,
        x = plan.x,
        y = plan.y,
    }
    local _, trace = affected(ctx, caster, donor,
        donor_pos, destination)
    local spell_power = power.caster_power(ctx, caster, profile)
    local to_hit = calculators.to_hit(profile, spell_power)

    ctx:emit(channels.SPELL, "The mass of ice explodes!")
    blast.resolve(ctx, caster, profile, trace, destination,
        spell_power, to_hit)
end

return effect
