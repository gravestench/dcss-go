-- Player Lee's Rapid Deconstruction keeps the command's aim and range
-- contract. The material and blast rule is shared with monster casters.
-- Source: spl-damage.cc:cast_fragmentation.
local component = require("constants.component")
local fragmentation = require("policy.combat.monster_area.fragmentation")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local lrd = {}

-- Translate the player's direction into the current level's target cell.
local function target_cell(ctx, player, dx, dy)
    local origin = ctx:get(player, component.POSITION)

    return origin, origin.x + dx, origin.y + dy
end

-- An aimed floor has no fragments, while a solid wall or material actor
-- can be shattered if it lies within the spell's visible range.
function lrd.prepare(ctx, player, spell, dx, dy)
    local origin, x, y = target_cell(ctx, player, dx, dy)
    local reach = range.for_spell(ctx, player, spell)

    if math.max(math.abs(dx), math.abs(dy)) > reach or
        not ctx:visible(origin.level_id,
            origin.x, origin.y, reach, x, y) or
        not fragmentation.profile(ctx, origin.level_id, x, y) then
        return "You can't deconstruct that!"
    end
end

-- The command selected this cell before spending the action. Resolve the
-- same cell through the shared owner, using the player's saved spell stream.
function lrd.resolve(ctx, player, intent, _, power)
    local origin, x, y = target_cell(ctx, player,
        intent.dx, intent.dy)

    fragmentation.resolve(ctx, player, origin.level_id,
        x, y, power, streams.SPELL)
end

registry.add(spells.SPELL_LRD, lrd)

return lrd
