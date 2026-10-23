-- Example: D:1 consumes population rolls before D:2, regardless of table iteration order.
local factory = require("policy.population.factory")
local pool = require("policy.population.pool")
local roster = require("policy.population.roster")
local catalog = require("policy.catalog")
local abyss = require("policy.world.abyss")
local vaults = require("policy.population.vaults")
local shops = require("policy.shops.generation")
local wallet = require("policy.shops.wallet")
local shop_ids = require("ids.shops")
local item_ids = require("ids.items")
local streams = require("constants.rng_streams")
local bands = require("policy.population.bands")
local boris_replacement = require("policy.population.boris_replacement")
local branches = require("ids.branches")
local sentinels = require("constants.population_sentinels")
local scenarios = require("constants.scenarios")
local monster_ids = require("ids.monsters")
local monster_requests = require("constants.vault_monster_requests")
local monster_resolve = require("policy.generation.vaults.specs.resolve")

-- Ambient tables may request a corpse-form template. It has no fixed HP
-- profile until a source body is chosen at the current branch depth.
local corpse_forms = {
    [monster_ids.MONS_ZOMBIE] = monster_requests.RANDOM_ZOMBIE,
    [monster_ids.MONS_SKELETON] = monster_requests.RANDOM_SKELETON,
    [monster_ids.MONS_SIMULACRUM] = monster_requests.RANDOM_SIMULACRUM,
    [monster_ids.MONS_SPECTRAL_THING] = monster_requests.RANDOM_SPECTRAL,
}

-- Use the same source body selector as an authored vault request so ambient
-- undead and keyed DES undead cannot drift to different species pools.
local function ambient_spawn_request(ctx, monster_id, branch_id, depth)
    local name = corpse_forms[monster_id]

    if not name then
        return monster_id, nil
    end

    local selected = monster_resolve.monster(ctx, {
        name = name,
        source = name,
    }, depth, {
        branch_id = branch_id,
        local_depth = depth,
    })

    return selected.kind_id, selected
end

-- Visit levels by ID so shared population draws have stable order.
local function level_order(left, right)
    return left.id < right.id
end

-- Convert authored no-spawn coordinates to a set before scanning floor cells.
local function exclusion_set(level)
    local excluded = {}

    for _, point in ipairs(level.spawn_exclusions or {}) do
        excluded[point.x .. ":" .. point.y] = true
    end

    return excluded
end

-- Scan walkable floor in row-major order after vault records have occupied their cells.
local function free_cells(ctx, level, excluded)
    local cells = {}

    -- Go's spawnCellsAwayFrom visits terrain in row-major source order.
    for y = 0, level.height - 1 do
        for x = 0, level.width - 1 do
            local distance = math.max(math.abs(x - level.entry_x), math.abs(y - level.entry_y))

            if ctx:cell(level.id, x, y) == "DNGN_FLOOR" and distance >= 5 and
                not excluded[x .. ":" .. y] and
                not ctx:actor_at(level.id, x, y) then
                cells[#cells + 1] = { x = x, y = y }
            end
        end
    end

    return cells
end

-- Place vault materializations before ordinary monsters so blocked and protected cells affect spawn choice.
-- Draw ordinary monsters from the depth pool only after spawn exclusions are applied.
local function populate_level(ctx, level, allowed, scenario_id)
    if level.budget <= 0 then
        error("Dungeon:" .. level.id .. " has no population budget")
    end

    local branch_id = level.branch_id or branches.BRANCH_DUNGEON
    local depth = level.local_depth or level.id

    if scenario_id == scenarios.GENERATED_DUNGEON_BASIC and
        (not level.branch_id or not level.local_depth) then
        error("generated level " .. level.id ..
            " requires explicit branch ID and local depth")
    end
    local choices, total = pool.at_depth(branch_id, depth, allowed, scenario_id)

    if total == 0 then
        error("Dungeon:" .. level.id .. " has no supported population")
    end

    local actors = 0
    local excluded = exclusion_set(level)

    for _ = 1, level.budget do
        local cells = free_cells(ctx, level, excluded)

        if #cells == 0 then
            -- An encompassing map can mark every playable cell as
            -- no_monster_gen. Its authored monsters still materialize, but
            -- ordinary population has nowhere legal to appear. Stop the
            -- ambient pass without changing the saved source roll budget.
            break
        end

        local monster_id = pool.pick(ctx, choices, total)

        -- The source table can spend a roll without placing an actor.
        if monster_id ~= sentinels.NO_MONSTER then
            local cell = cells[ctx:random("placement", #cells) + 1]
            local kind_id, options = ambient_spawn_request(ctx,
                monster_id, branch_id, depth)
            local leader = factory.spawn(ctx, kind_id, level.id,
                cell.x, cell.y, options)
            actors = actors + 1

            -- A definition with a band owns its follower count and membership.
            -- The shared policy handles jackals and named ambient leaders alike.
            actors = actors + bands.spawn(ctx, leader, level, excluded)
        end
    end

    return actors
end

-- Place fixed benchmark monsters in a known order for deterministic scenario state.
local function fixture(ctx)
    factory.spawn(ctx, "MONS_RAT", 1, 4, 1)
    factory.spawn(ctx, "MONS_QUOKKA", 2, 14, 7)
    factory.spawn(ctx, "MONS_FRILLED_LIZARD", 2, 14, 1)

    -- The historical fixture did not account these as population actors.
    return {
        { id = 1, count = 0 },
        { id = 2, count = 0 },
        { id = abyss.level_id, count = 0 },
    }
end

-- Place the fixed shop after fixture monsters so its stock uses the intended stream position.
local function shop_fixture(ctx)
    shops.place(ctx, {
        level_id = 1,
        x = 3,
        y = 2,
        depth = 1,
        kind_id = shop_ids.SHOP_GENERAL,
        full_name = "General Store",
        greed = 10,
        count = 3,
        use_all = true,
        items = {
            item_ids.WPN_CLUB,
            item_ids.ARM_BUCKLER,
            item_ids.POT_CURING,
        },
    })
end

-- Validate an assigned cell before creating a concrete starting potion entity.
local function floor_potion(ctx, kind_id, level_id, cell)
    if not cell or cell.x == nil or cell.y == nil then
        error("missing starting floor item location for " .. kind_id)
    end

    catalog.get("items", kind_id)

    local item = ctx:create()
    ctx:add(item, "core.item", {
        kind_id = kind_id,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(item, "core.position", {
        level_id = level_id,
        x = cell.x,
        y = cell.y,
    })
end

-- Create fixed floor consumables only after monster inventory has consumed item draws.
local function floor_items(ctx, items)
    -- Scenario items follow every monster and its carried inventory.
    -- The generator names the content; this policy only creates entities.
    for _, item in ipairs(items or {}) do
        floor_potion(ctx, item.kind_id, item.level_id, item)
    end
end

local module = {}

-- Sort levels before materialization so shared population streams advance in level order.
function module.run(ctx, input)
    local scenario_id = input.scenario_id
    roster.allowed(scenario_id, branches.BRANCH_DUNGEON)

    local counts = {}
    local materialized = {}

    if scenario_id == "fixed-dungeon-rat-quokka-lizard-v2" or
        scenario_id == "fixed-dungeon-shops-v1" then
        counts = fixture(ctx)

        if scenario_id == "fixed-dungeon-shops-v1" then
            shop_fixture(ctx)
        end
    else
        local levels = input.levels or {}

        table.sort(levels, level_order)

        for _, level in ipairs(levels) do
            if level.entry_x == nil or level.entry_y == nil or not level.width or
                not level.height then
                error("Dungeon:" .. tostring(level.id) .. " has no population entry")
            end

            local excluded = exclusion_set(level)
            local _, placed, followers = vaults.materialize(ctx, level,
                excluded)
            local count = followers

            for _, record in ipairs(placed) do
                materialized[#materialized + 1] = record
            end

            if level.id ~= abyss.level_id and level.budget > 0 then
                local allowed = roster.allowed(scenario_id,
                    level.branch_id or branches.BRANCH_DUNGEON)
                count = count + populate_level(ctx, level, allowed,
                    scenario_id)
                count = count + boris_replacement.place(ctx, level, excluded)
            end

            -- Source Gozag prices conversion from placed floor gold on each
            -- newly populated non-Abyss level, not from collected gold.
            if level.branch_id ~= branches.BRANCH_ABYSS then
                wallet.record_level_gold(ctx, ctx:player(), level.id)
            end

            counts[#counts + 1] = { id = level.id, count = count }
        end
    end

    floor_items(ctx, input.starting_items)

    return {
        initial_actors = counts,
        materialized = materialized,
    }
end

register.policy({
    id = "world.populate",
    run = module.run,
})

return module
