-- Example: D:1 consumes population rolls before D:2, regardless of table iteration order.
local factory = require("policy.population.factory")
local pool = require("policy.population.pool")
local roster = require("policy.population.roster")
local catalog = require("policy.catalog")
local abyss = require("policy.world.abyss")
local vaults = require("policy.population.vaults")
local shops = require("policy.shops.generation")
local shop_ids = require("ids.shops")
local item_ids = require("ids.items")
local streams = require("constants.rng_streams")
local kirke_band = require("policy.population.kirke_band")
local monsters = require("ids.monsters")

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

-- Pack jackal followers near their leader without reusing a protected or occupied square.
local function follower_cell(ctx, level, origin, excluded)
    for _ = 1, 1000 do
        local x = origin.x + ctx:random("placement", 7) - 3
        local y = origin.y + ctx:random("placement", 7) - 3

        if ctx:walkable(level.id, x, y) and
            not excluded[x .. ":" .. y] and
            ctx:visible(level.id, origin.x, origin.y, 7, x, y) and
            not ctx:actor_at(level.id, x, y) then
            return { x = x, y = y }
        end
    end

    return nil
end

-- Draw a small band size after its leader is placed, then seek adjacent free cells.
local function jackal_followers(ctx, level, leader, origin, excluded)
    local count = ctx:random("bands", 3) + 1
    local placed = 0

    for _ = 1, count do
        local cell = follower_cell(ctx, level, origin, excluded)

        if cell then
            local follower = factory.spawn(ctx, "MONS_JACKAL", level.id, cell.x, cell.y)
            ctx:add(follower, "core.follower", { leader = leader })
            placed = placed + 1
        end
    end

    return placed
end

-- Place vault materializations before ordinary monsters so blocked and protected cells affect spawn choice.
-- Draw ordinary monsters from the depth pool only after spawn exclusions are applied.
local function populate_level(ctx, level, allowed, scenario_id)
    if level.budget <= 0 then
        error("Dungeon:" .. level.id .. " has no population budget")
    end

    local choices, total = pool.at_depth(level.id, allowed, scenario_id)

    if total == 0 then
        error("Dungeon:" .. level.id .. " has no supported population")
    end

    local actors = 0
    local excluded = exclusion_set(level)

    for _ = 1, level.budget do
        local cells = free_cells(ctx, level, excluded)

        if #cells == 0 then
            error("Dungeon:" .. level.id .. " has no free monster spawn cell")
        end

        local monster_id = pool.pick(ctx, choices, total)
        local cell = cells[ctx:random("placement", #cells) + 1]
        local leader = factory.spawn(ctx, monster_id, level.id, cell.x, cell.y)
        actors = actors + 1

        if monster_id == "MONS_JACKAL" then
            actors = actors + jackal_followers(ctx, level, leader, cell, excluded)
        elseif monster_id == monsters.MONS_KIRKE then
            actors = actors + kirke_band.spawn(ctx, leader, level, excluded)
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
local function floor_items(ctx, input)
    -- Scenario potions follow every monster and its carried inventory.
    floor_potion(ctx, "POT_CURING", 1, input.curing)
    floor_potion(ctx, "POT_HEAL_WOUNDS", 2, input.heal)
    floor_potion(ctx, "POT_HASTE", 2, input.haste)
end

local module = {}

-- Sort levels before materialization so shared population streams advance in level order.
function module.run(ctx, input)
    local scenario_id = input.scenario_id
    roster.allowed(scenario_id)

    local counts = {}
    local materialized = {}

    if scenario_id == "fixed-dungeon-rat-quokka-lizard-v2" or
        scenario_id == "fixed-dungeon-shops-v1" then
        counts = fixture(ctx)

        if scenario_id == "fixed-dungeon-shops-v1" then
            shop_fixture(ctx)
        end
    else
        local allowed = roster.allowed(scenario_id)
        local levels = input.levels or {}

        table.sort(levels, level_order)

        for _, level in ipairs(levels) do
            if level.entry_x == nil or level.entry_y == nil or not level.width or
                not level.height then
                error("Dungeon:" .. tostring(level.id) .. " has no population entry")
            end

            local excluded = exclusion_set(level)
            local _, placed = vaults.materialize(ctx, level, excluded)
            local count = 0

            for _, record in ipairs(placed) do
                materialized[#materialized + 1] = record
            end

            if level.id ~= abyss.level_id then
                count = populate_level(ctx, level, allowed, scenario_id)
            end

            counts[#counts + 1] = { id = level.id, count = count }
        end
    end

    -- Fixed starting consumables belong to initial setup. A newly entered
    -- Dungeon floor uses the live RNG state but must not duplicate those
    -- items when its own population policy runs.
    if input.place_starting_items then
        floor_items(ctx, input)
    end

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
