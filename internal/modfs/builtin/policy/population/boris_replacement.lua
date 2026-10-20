-- Theory of operation: once Boris has died, each newly generated level
-- gets the source's one-in-six offer. Only Depths, Vaults, Tomb, and Crypt
-- can place his replacement. The player ledger still bars a second live
-- Boris across all levels.
local branches = require("ids.branches")
local component = require("constants.component")
local factory = require("policy.population.factory")
local history = require("policy.population.unique_history")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local replacement = {}

local allowed = {
    [branches.BRANCH_DEPTHS] = true,
    [branches.BRANCH_VAULTS] = true,
    [branches.BRANCH_TOMB] = true,
    [branches.BRANCH_CRYPT] = true,
}

-- Gather actual open floor after authored and ordinary monsters have been
-- placed, so a respawn never displaces an existing ECS actor or reserved cell.
local function cells(ctx, level, excluded)
    local free = {}

    for y = 0, level.height - 1 do
        for x = 0, level.width - 1 do
            if ctx:cell(level.id, x, y) == terrain.DNGN_FLOOR and
                not excluded[x .. ":" .. y] and
                not ctx:actor_at(level.id, x, y) then
                free[#free + 1] = {
                    x = x,
                    y = y,
                }
            end
        end
    end

    return free
end

-- Call only for a newly built level. The chance precedes the branch gate
-- in the source; failed chances and blocked branches leave no new actor.
function replacement.place(ctx, level, excluded)
    if not history.boris_killed(ctx) or
        history.seen(ctx, monsters.MONS_BORIS) or
        ctx:random(streams.PLACEMENT, 6) ~= 0 then
        return 0
    end

    if not allowed[ctx:level_branch(level.id)] then
        return 0
    end

    local free = cells(ctx, level, excluded or {})

    if #free == 0 then
        return 0
    end

    local cell = free[ctx:random(streams.PLACEMENT, #free) + 1]

    local actor = factory.spawn(ctx, monsters.MONS_BORIS, level.id,
        cell.x, cell.y)

    ctx:add(actor, component.UNIQUE_REPLACEMENT, {
        kind_id = monsters.MONS_BORIS,
    })

    return 1
end

return replacement
