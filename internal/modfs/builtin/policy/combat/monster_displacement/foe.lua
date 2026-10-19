local component = require("constants.component")
local hex = require("policy.combat.monster_spells.hex")
local landing = require("policy.combat.monster_displacement.landing")
local relocate = require("policy.combat.monster_displacement.relocate")
local target = require("policy.combat.monster_summons.target")
local trajectory = require("policy.combat.trajectory")
local streams = require("constants.rng_streams")

local foe = {}

-- A self blink keeps the selected foe's identity and checks its live cell
-- at resolution. A missing or off-level foe cannot redirect a cast.
function foe.position(ctx, caster, selected)
    local caster_pos = ctx:get(caster, component.POSITION)
    local foe_pos = selected and ctx:get(selected, component.POSITION)

    if not caster_pos or not foe_pos or
        caster_pos.level_id ~= foe_pos.level_id then
        return nil
    end

    return foe_pos
end

-- Foe enchantments aim at a saved cell, so a moving original target does
-- not drag the ray onto a different line after intent creation.
function foe.plan(ctx, caster, selected)
    local position = foe.position(ctx, caster, selected)

    if not position then
        return nil
    end

    local origin = ctx:get(caster, component.POSITION)

    if not ctx:visible(origin.level_id, origin.x, origin.y, 7,
        position.x, position.y) then
        return nil
    end

    return target.plan(ctx, caster, selected)
end

-- Self blink variants still commit the foe's cell. The cell survives the
-- intent boundary, so a moving or dead foe cannot redirect the landing.
function foe.require_plan(ctx, caster, plan)
    target.require_cell(ctx, caster, plan)

    return plan
end

-- Blink Other is a beam enchantment. The source uses ordinary monster
-- power divided by ENCH_POW_FACTOR, giving four willpower units per HD.
local enchantment = {
    is_enchantment = true,
    power_hd_factor = 4,
    rng_stream = streams.MONSTER_SPELL,
}

-- Trace the original ray and move only its first actor contact after a
-- source-shaped willpower check. Later contacts cannot be hit past it.
function foe.enchant(ctx, caster, plan, close)
    target.require_cell(ctx, caster, plan)

    local origin = ctx:get(caster, component.POSITION)
    local ray = trajectory.to_target(ctx, origin.level_id, origin.x,
        origin.y, plan.x, plan.y, 7)
    local contact = ray.contacts[1]

    if not contact or hex.resisted(ctx, caster, contact.actor,
        enchantment) then
        return false
    end

    local victim = contact.actor
    local x, y

    if close then
        x, y = landing.weighted(ctx, victim, origin, true, true)
    else
        x, y = landing.ordinary(ctx, victim)

        -- Source uncontrolled_blink retries neighboring cells for a
        -- player when every nonadjacent destination is unavailable.
        if not x and victim == ctx:player() then
            x, y = landing.ordinary(ctx, victim, true)
        end
    end

    if not x then
        return false
    end

    return relocate.move(ctx, victim, x, y, caster)
end

return foe
