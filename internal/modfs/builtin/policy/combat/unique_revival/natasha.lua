-- Theory of operation: Natasha is allowed two reincarnations. Her old
-- actor still dies, grants its usual kill result, and leaves no corpse;
-- a new actor appears on distant clear floor with the old inventory and
-- an incremented saved revival count. The third death is final.
local clouds = require("policy.clouds.placement")
local component = require("constants.component")
local death_hooks = require("policy.combat.death_hooks")
local factory = require("policy.population.factory")
local history = require("policy.population.unique_history")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")
local terrain = require("constants.terrain")

local natasha = {}

-- A polymorphed Natasha still has her original unique class. Her final
-- transformed body must count toward the same two-revival limit.
local function is_natasha(ctx, actor, definition)
    if definition.id == monsters.MONS_NATASHA then
        return true
    end

    local form = ctx:get(actor, component.MONSTER_POLYMORPH)

    return form and form.original_kind_id == monsters.MONS_NATASHA
end

-- Source revival rejects clouds, occupied cells, no-teleport markers, and
-- cells within eight grid steps of the previous body. Conditioned on a
-- legal cell, a single uniform draw has the source's random-cell result.
local function free_cells(ctx, position)
    local width, height = ctx:level_size(position.level_id)
    local free = {}

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            local distance = math.max(math.abs(x - position.x),
                math.abs(y - position.y))

            if distance >= 9 and
                ctx:cell(position.level_id, x, y) == terrain.DNGN_FLOOR and
                not ctx:actor_at(position.level_id, x, y) and
                not clouds.at(ctx, position.level_id, x, y) and
                not ctx:marker_property(position.level_id, x, y,
                    "no_tele_into") then
                free[#free + 1] = {
                    x = x,
                    y = y,
                }
            end
        end
    end

    return free
end

-- The death system has already removed the old equipment links and placed
-- those exact item entities on the floor. Reattach them to the new actor
-- rather than generating a second loadout or copying item definitions.
local function transfer_items(ctx, actor, dropped)
    for _, record in ipairs(dropped or {}) do
        ctx:remove(record.entity, component.POSITION)
        ctx:add(record.entity, component.CARRIED_BY, {
            holder = actor,
        })

        if record.slot then
            ctx:add(record.entity, component.EQUIPPED, {
                slot = record.slot,
            })
        end
    end
end

-- DCSS keeps a revivable Natasha's inventory off the floor. When it cannot
-- find a safe destination, monster cleanup destroys those items instead.
local function destroy_items(ctx, dropped)
    for _, record in ipairs(dropped or {}) do
        ctx:destroy(record.entity)
    end
end

-- A successful death starts the next Natasha life elsewhere on the same
-- level. If there is no legal cell, the active unique claim is still freed
-- as in the source's failed placement path.
function natasha.on_death(ctx, actor, definition, position, _, _, dropped)
    if not is_natasha(ctx, actor, definition) then
        return false
    end

    local revival = ctx:get(actor, component.UNIQUE_REVIVAL)
    local count = revival and revival.revives or 0

    if count >= 2 then
        return false
    end

    local free = free_cells(ctx, position)
    local attitude = targets.real_attitude(ctx, actor)

    history.release(ctx, monsters.MONS_NATASHA)

    if #free == 0 then
        destroy_items(ctx, dropped)
        return true
    end

    local cell = free[ctx:random(streams.PLACEMENT, #free) + 1]
    local next_life = factory.spawn(ctx, monsters.MONS_NATASHA,
        position.level_id, cell.x, cell.y, {
            equipment = {},
            attitude = attitude,
        })

    ctx:add(next_life, component.UNIQUE_REVIVAL, {
        revives = count + 1,
    })
    transfer_items(ctx, next_life, dropped)

    return true
end

death_hooks.add("unique.natasha", natasha.on_death)

return natasha
