local component = require("constants.component")
local spells = require("ids.spells")
local projectile = require("policy.magic.effects.zaps.projectile")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")

local starburst = {}

-- spl-damage.cc:cast_starburst emits ZAP_BOLT_OF_FIRE in eight directions.
local directions = {
    { dx = 1, dy = 0 },
    { dx = 1, dy = 1 },
    { dx = 0, dy = 1 },
    { dx = -1, dy = 1 },
    { dx = -1, dy = 0 },
    { dx = -1, dy = -1 },
    { dx = 0, dy = -1 },
    { dx = 1, dy = -1 },
}

local bolt = {
    name = "bolt of fire",
    cap = 200,
    beam = true,
    damage = {
        kind = "calcdice",
        count = 6,
        base = 18,
        numerator = 2,
        denominator = 3,
    },
    hit = {
        base = 10,
        numerator = 1,
        denominator = 25,
    },
    ac_rule = "normal",
    element = "MR_RES_FIRE",
}

-- Example: A visible monster on one of eight rays makes Starburst targetable.
-- Trace all eight fixed directions before offering the cast, matching the later beam geometry.
function starburst.can_target(ctx, player, spell)
    local origin = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)

    for _, direction in ipairs(directions) do
        local ray = trajectory.trace(ctx, origin.level_id,
            origin.x, origin.y,
            origin.x + direction.dx,
            origin.y + direction.dy,
            reach)

        for _, contact in ipairs(ray.contacts) do
            local health = ctx:get(contact.actor, component.HEALTH)

            if contact.actor ~= player and health and health.current > 0 then
                return true
            end
        end
    end

    return false
end

-- Shuffle ray direction order before tracing so simultaneous beams consume RNG consistently.
function starburst.resolve(ctx, player, _, spell, power)
    local order = {}

    for index, direction in ipairs(directions) do
        order[index] = direction
    end

    -- Source shuffles the eight bolts after the failure check.
    for index = #order, 2, -1 do
        local chosen = 1 + ctx:random("spell", index)
        order[index], order[chosen] = order[chosen], order[index]
    end

    for _, direction in ipairs(order) do
        projectile.fire(ctx, player, direction, spell, bolt, power)
    end
end

registry.add(spells.SPELL_STARBURST, starburst)

return starburst
