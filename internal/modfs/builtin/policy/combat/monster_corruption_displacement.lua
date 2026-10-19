local catalog = require("policy.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local habitat = require("policy.combat.monster_habitat")
local items = require("policy.inventory.items")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local displacement = {}

-- Monster flags are content lists rather than special cases in this spell.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Source push spaces are adjacent traversable cells. A floor item may land
-- under a creature, while a creature also needs an empty habitable cell.
local function candidates(ctx, level_id, x, y, actor)
    local result = {}

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local px = x + dx
                local py = y + dy
                local feature = ctx:cell(level_id, px, py)
                local safe_item = feature ~= terrain.DNGN_DEEP_WATER and
                    feature ~= terrain.DNGN_LAVA and
                    feature ~= terrain.DNGN_OPEN_SEA and
                    feature ~= terrain.DNGN_LAVA_SEA

                if ctx:walkable(level_id, px, py) and
                    (actor and not ctx:actor_at(level_id, px, py) and
                        habitat.at(ctx, actor, level_id, px, py) or
                        not actor and safe_item) then
                    result[#result + 1] = { x = px, y = py }
                end
            end
        end
    end

    return result
end

-- Each item gets a fresh draw so a pile may scatter across several cells.
-- A failed push leaves the item for the caller's floor fallback check.
local function push_items(ctx, level_id, x, y, ground)
    local choices = candidates(ctx, level_id, x, y)

    if #choices == 0 then
        return
    end

    for _, item in ipairs(ground) do
        local destination = choices[ctx:random(streams.MONSTER_SPELL,
            #choices) + 1]
        local position = ctx:get(item, component.POSITION)

        position.x = destination.x
        position.y = destination.y
        ctx:set(item, component.POSITION, position)
    end
end

-- Stationary monsters and blocked actors stay in place; the corruption
-- caller must not turn their occupied floor into an impassable wall.
local function push_actor(ctx, level_id, x, y, actor)
    if not actor then
        return
    end

    local state = ctx:get(actor, component.ACTOR)
    local definition = state and catalog.get("monsters", state.kind_id)

    if not definition or has(definition.flags, flags.STATIONARY) then
        return
    end

    local choices = candidates(ctx, level_id, x, y, actor)

    if #choices > 0 then
        local destination = choices[ctx:random(streams.MONSTER_SPELL,
            #choices) + 1]

        ctx:move_actor(actor, level_id, destination.x, destination.y)
    end
end

-- abyss.cc:_corrupt_square_monster tries items first, then actors. If
-- either remains, the caller must use floor instead of burying it in rock.
function displacement.clear(ctx, level_id, x, y)
    local position = { level_id = level_id, x = x, y = y }
    local ground = items.at(ctx, position)
    local actor = ctx:actor_at(level_id, x, y)

    if #ground == 0 and not actor then
        return true
    end

    push_items(ctx, level_id, x, y, ground)
    push_actor(ctx, level_id, x, y, actor)

    return not ctx:actor_at(level_id, x, y) and
        #items.at(ctx, position) == 0
end

return displacement
