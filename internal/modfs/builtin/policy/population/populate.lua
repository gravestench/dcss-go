-- Example: D:1 consumes population rolls before D:2, regardless of table iteration order.
local ambient = require("policy.population.ambient")
local factory = require("policy.population.factory")
local roster = require("policy.population.roster")
local catalog = require("policy.catalog")
local abyss = require("policy.world.abyss")
local abyss_constants = require("constants.abyss")
local vaults = require("policy.population.vaults")
local shops = require("policy.shops.generation")
local wallet = require("policy.shops.wallet")
local shop_ids = require("ids.shops")
local item_ids = require("ids.items")
local boris_replacement = require("policy.population.boris_replacement")
local branches = require("ids.branches")

-- Visit levels by ID so shared population draws have stable order.
local function level_order(left, right)
    return left.id < right.id
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
        { id = abyss_constants.TRANSIT_LEVEL_ID, count = 0 },
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

            local excluded = ambient.exclusions(level)
            local _, placed, followers = vaults.materialize(ctx, level,
                excluded)
            local count = followers

            for _, record in ipairs(placed) do
                materialized[#materialized + 1] = record
            end

            if level.branch_id ~= branches.BRANCH_ABYSS and
                level.budget > 0 then
                local allowed = roster.allowed(scenario_id,
                    level.branch_id or branches.BRANCH_DUNGEON)
                count = count + ambient.populate(ctx, level, allowed,
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
