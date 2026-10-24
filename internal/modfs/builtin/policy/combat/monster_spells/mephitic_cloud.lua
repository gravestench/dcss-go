-- Mephitic Cloud is a zero-damage explosion whose actual hazard is the
-- placed cloud. The shared burst owner also serves the player spell, so
-- both routes keep identical radius, spread, and duration rules.
local beam = require("policy.combat.monster_beams")
local burst = require("policy.clouds.mephitic_burst")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local power = require("policy.combat.monster_beams.power")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local target_kind = require("constants.target_kind")
local trajectory = require("policy.combat.trajectory")
local plant_protection = require(
    "policy.religion.fedhas.protection")

local mephitic_cloud = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_MEPHITIC_CLOUD)

-- The area planner checks the intended cell and its possible cloud cells
-- before an ordinary monster commits to casting near allies.
function mephitic_cloud.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile, {
        cloud_max_size = 9,
    })
end

-- Stop at the first reached actor or wall. Wrath's feet plan instead
-- bursts in the player's cell without tracing a travel step.
function mephitic_cloud.resolve(ctx, caster, foe, _, plan)
    if not plan or plan.kind ~= target_kind.CELL then
        error("Mephitic Cloud requires a cell target")
    end

    local source = ctx:get(caster, component.POSITION)

    if not source or source.level_id ~= plan.level_id then
        error("Mephitic Cloud caster left the target level")
    end

    local center_x = plan.x
    local center_y = plan.y

    if plan.at_feet then
        local target = ctx:get(foe, component.POSITION)

        if not ctx:has(foe, component.PLAYER) or not target or
            source.x ~= target.x or source.y ~= target.y or
            center_x ~= target.x or center_y ~= target.y then
            error("Mephitic Cloud feet target moved")
        end
    else
        local ray = trajectory.to_target(ctx, source.level_id,
            source.x, source.y, center_x, center_y,
            power.spell_range(ctx, caster, profile))
        local contact = plant_protection.first_unprotected_contact(ctx,
            caster, ray.contacts)

        center_x = contact and contact.x or ray.x
        center_y = contact and contact.y or ray.y
    end

    return burst.place(ctx, caster, source.level_id,
        center_x, center_y,
        power.caster_power(ctx, caster, profile),
        streams.MONSTER_SPELL)
end

return mephitic_cloud
