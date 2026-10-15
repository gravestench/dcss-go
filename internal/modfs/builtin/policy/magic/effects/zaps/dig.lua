local component = require("constants.component")
local spells = require("ids.spells")
local terrain = require("constants.terrain")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")

local dig = {}

-- terrain.cc:feat_is_diggable. Temporary terrain and veto markers are not
-- represented by the current grid, so only intrinsic feature IDs qualify.
local diggable = {
    [terrain.DNGN_ROCK_WALL] = true,
    [terrain.DNGN_CLEAR_ROCK_WALL] = true,
    [terrain.DNGN_SLIMY_WALL] = true,
    [terrain.DNGN_GRATE] = true,
    [terrain.DNGN_ORCISH_IDOL] = true,
    [terrain.DNGN_GRANITE_STATUE] = true,
    [terrain.DNGN_PETRIFIED_TREE] = true,
}

function dig.resolve(ctx, player, intent, spell)
    local origin = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)
    local aim_x = origin.x + intent.dx
    local aim_y = origin.y + intent.dy
    local changed = false

    -- Dig's beam continues through each newly destroyed wall. Repeating
    -- the shared trajectory after the grid change preserves its tie breaks
    -- while allowing it to inspect the next blocking cell.
    for _ = 1, reach do
        local ray = trajectory.trace(ctx, origin.level_id, origin.x,
            origin.y, aim_x, aim_y, reach)

        if not ray.blocked then
            break
        end

        local feature = ctx:cell(origin.level_id, ray.blocked_x,
            ray.blocked_y)

        if not diggable[feature] then
            break
        end

        ctx:set_cell(origin.level_id, ray.blocked_x, ray.blocked_y,
            terrain.DNGN_FLOOR)
        changed = true
    end

    if changed then
        ctx:emit("spell", "The rock shatters into small pieces.")
    end
end

registry.add(spells.SPELL_DIG, dig)

return dig
