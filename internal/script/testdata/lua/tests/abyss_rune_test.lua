-- Source rune chance chooses one tagged DES map when it fits and falls
-- back to a uniform floor cell otherwise. The resulting item is the
-- ordinary rune entity consumed by the existing pickup policy.
local abyss = require("constants.abyss")
local component = require("constants.component")
local harness = require("tests.harness")
local items = require("ids.items")
local rune = require("policy.world.abyss.rune")
local terrain = require("constants.terrain")

local test = {}

-- A flat window gives every tagged source map room to fit. The exact
-- choice remains owned by the effective DES catalog, not this fixture.
local function level()
    local cells = {}

    for y = 1, abyss.HEIGHT do
        cells[y] = {}

        for x = 1, abyss.WIDTH do
            cells[y][x] = terrain.DNGN_FLOOR
        end
    end

    return {
        cells = cells,
        entry_x = abyss.CENTRE_X,
        entry_y = abyss.CENTRE_Y,
        vault_records = {},
        vault_ids = {},
    }
end

-- Force the source chance to pass. Other draws select a stable map and
-- orientation but do not name any source vault in the test itself.
local function context(collected)
    local ctx = {}
    local player = {}
    local spawned = {}

    function ctx:player()
        return player
    end

    function ctx:get(entity, name)
        harness.equal(entity, player)
        harness.equal(name, component.PLAYER_RUNES)

        return { collected = collected }
    end

    function ctx:random(_, bound)
        return 0
    end

    function ctx:random_u64()
        return 0, 17
    end

    function ctx:create()
        return spawned
    end

    function ctx:add(entity, name, fields)
        harness.equal(entity, spawned)
        spawned[name] = fields
    end

    return ctx, spawned
end

-- Rune depth, tagged geometry, ECS materialization, and collected-rune
-- suppression all use the production policy and shared item ID.
function test.run()
    local ctx, spawned = context({})
    local state = {
        branch_depth = abyss.RUNE_MIN_DEPTH,
        selected_map_ids = {},
    }
    local region = level()
    local location = rune.plan(ctx, region, state, {})

    harness.truthy(location)
    harness.truthy(#region.vault_ids > 0)
    harness.equal(#state.selected_map_ids, #region.vault_ids)

    local seen_ids = {}

    for _, id in ipairs(region.vault_ids) do
        harness.falsy(seen_ids[id], "rune map was recorded twice")
        seen_ids[id] = true
    end
    harness.truthy(location.x >= 1 and location.x < abyss.WIDTH - 1)
    harness.truthy(location.y >= 1 and location.y < abyss.HEIGHT - 1)

    rune.spawn(ctx, location)

    harness.equal(spawned[component.ITEM].kind_id,
        items.RUNE_ABYSSAL)
    harness.equal(spawned[component.POSITION].x, location.x)

    local collected_ctx = context({
        [items.RUNE_ABYSSAL] = true,
    })
    local duplicate = rune.plan(collected_ctx,
        level(), state, {})

    harness.equal(duplicate, nil)

    state.branch_depth = abyss.RUNE_MIN_DEPTH - 1
    harness.equal(rune.plan(ctx, level(), state, {}), nil)

    -- A floor rune inside the radius carried by a shift still owns the
    -- only live copy, even before the player has picked it up.
    local floor_rune = {}
    local old_get = ctx.get

    function ctx:query()
        return { floor_rune }
    end

    function ctx:get(entity, name)
        if entity == floor_rune and name == component.ITEM then
            return { kind_id = items.RUNE_ABYSSAL }
        end

        if entity == floor_rune and name == component.POSITION then
            return { level_id = abyss.LEVEL_ID, x = 22, y = 19 }
        end

        return old_get(self, entity, name)
    end

    state.branch_depth = 7
    harness.equal(rune.plan(ctx, level(), state,
        {}, { ["22:19"] = true }), nil)
end

return test
