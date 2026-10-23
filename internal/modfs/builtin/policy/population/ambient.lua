-- Theory of operation: ordinary monsters are drawn from the effective
-- branch population catalog, then placed on unoccupied, unexcluded floor.
-- This owner is shared by generated Dungeon levels and a new Abyss window;
-- the caller supplies its branch depth and source roll budget.
local factory = require("policy.population.factory")
local pool = require("policy.population.pool")
local bands = require("policy.population.bands")
local monster_ids = require("ids.monsters")
local requests = require("constants.vault_monster_requests")
local resolver = require("policy.generation.vaults.specs.resolve")
local sentinels = require("constants.population_sentinels")
local terrain = require("constants.terrain")

local ambient = {}

local corpse_forms = {
    [monster_ids.MONS_ZOMBIE] = requests.RANDOM_ZOMBIE,
    [monster_ids.MONS_SKELETON] = requests.RANDOM_SKELETON,
    [monster_ids.MONS_SIMULACRUM] = requests.RANDOM_SIMULACRUM,
    [monster_ids.MONS_SPECTRAL_THING] = requests.RANDOM_SPECTRAL,
}

-- Source undead rows name a body class rather than a fully specified
-- monster. Resolve that body with the same policy as an authored DES MONS.
local function spawn_request(ctx, monster_id, branch_id, depth)
    local name = corpse_forms[monster_id]

    if not name then
        return monster_id, nil
    end

    local selected = resolver.monster(ctx, {
        name = name,
        source = name,
    }, depth, {
        branch_id = branch_id,
        local_depth = depth,
    })

    return selected.kind_id, selected
end

-- Convert saved, authored no-spawn cells into a lookup shared by the
-- ambient picker and band followers.
function ambient.exclusions(level)
    local excluded = {}

    for _, point in ipairs(level.spawn_exclusions or {}) do
        excluded[point.x .. ":" .. point.y] = true
    end

    return excluded
end

-- Scan in row-major order, as the source grid does. The entry clearance
-- stops a fresh floor's ambient pass from trapping the arriving player.
local function free_cells(ctx, level, excluded)
    local cells = {}

    for y = 0, level.height - 1 do
        for x = 0, level.width - 1 do
            local distance = math.max(math.abs(x - level.entry_x),
                math.abs(y - level.entry_y))

            if ctx:cell(level.id, x, y) == terrain.DNGN_FLOOR and
                distance >= 5 and not excluded[x .. ":" .. y] and
                not ctx:actor_at(level.id, x, y) then
                cells[#cells + 1] = { x = x, y = y }
            end
        end
    end

    return cells
end

-- Spend every requested source population roll. A no-monster sentinel
-- consumes its roll without making an ECS entity; bands own their own
-- follower count and honor the same authored exclusion mask.
function ambient.populate(ctx, level, allowed, scenario_id)
    if level.budget <= 0 then
        error("level " .. level.id .. " has no population budget")
    end

    local branch_id = level.branch_id
    local depth = level.local_depth
    local choices, total = pool.at_depth(branch_id, depth,
        allowed, scenario_id)

    if total == 0 then
        error("level " .. level.id .. " has no supported population")
    end

    local actors = 0
    local excluded = ambient.exclusions(level)

    for _ = 1, level.budget do
        local cells = free_cells(ctx, level, excluded)

        if #cells == 0 then
            break
        end

        local monster_id = pool.pick(ctx, choices, total)

        if monster_id ~= sentinels.NO_MONSTER then
            local cell = cells[ctx:random("placement", #cells) + 1]
            local kind_id, options = spawn_request(ctx, monster_id,
                branch_id, depth)
            local leader = factory.spawn(ctx, kind_id, level.id,
                cell.x, cell.y, options)

            actors = actors + 1
            actors = actors + bands.spawn(ctx, leader, level, excluded)
        end
    end

    return actors
end

return ambient
