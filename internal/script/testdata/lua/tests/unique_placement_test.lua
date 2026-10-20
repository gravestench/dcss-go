-- The unique selector uses real registered maps while a tiny placement
-- callback isolates its source probability gates from grid geometry.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local component = require("constants.component")
local harness = require("tests.harness")
local ids = require("ids.vaults")
local placement = require("policy.generation.vaults.unique.placement")
local vault_placement = require("policy.generation.vaults.placement")
local catalog = require("policy.generation.vaults.catalog")
local grid = require("policy.generation.grid")
local used = require("policy.generation.vaults.used")
local test = {}

-- Restrict the catalog to one real encounter and one source dummy while
-- still letting the production selector calculate depth and weights.
local function request(ctx)
    local excluded = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        if id ~= ids.uniq_jessica and id ~= ids.uniq_dummy then
            excluded[id] = true
        end
    end

    local player = ctx:create()

    ctx:add(player, component.PLAYER_UNIQUE_HISTORY, {
        status = {},
        monsters = {},
    })

    local world = setmetatable({}, { __index = ctx })

    function world:player()
        return player
    end

    return world, {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 2,
        absolute_depth = 2,
        branch_bottom = 15,
        player = {},
        excluded = excluded,
        used = used.new({}),
    }
end

-- A scripted layout stream catches an accidental extra chance or weight
-- draw. The weights still come from the real `.des` catalog.
local function random(draws)
    local index = 0
    local builder = {}

    function builder:roll(bound)
        index = index + 1
        local value = draws[index]

        if not value or value < 0 or value >= bound then
            error("unexpected unique draw " .. index .. " / " .. bound)
        end

        return value
    end

    return builder
end

-- Choosing the weighted dummy ends the source loop without writing a map
-- ID or allocating an actor, even though it counted as available.
local function dummy_ends_attempt(ctx)
    local world, context = request(ctx)
    local placed = {}
    local count = placement.place(world, random({ 0, 0, 0 }),
        context, placed, function()
            error("dummy map must not reach geometry placement")
        end)

    harness.equal(count, 0, "dummy unique count")
    harness.equal(#placed, 0, "dummy leaves no map")
end

-- A real unique passes the available-count gate, consumes its own weight,
-- and enters the same used-map history as other secondary vaults.
local function real_map_uses_history(ctx)
    local world, context = request(ctx)
    local placed = {}
    local count = placement.place(world, random({ 0, 0, 29, 1 }),
        context, placed, function(_, _, vault)
            harness.equal(vault.id, ids.uniq_jessica,
                "weighted real unique chosen")

            return { id = vault.id }
        end)

    harness.equal(count, 1, "one successful unique")
    harness.equal(placed[1].id, ids.uniq_jessica,
        "unique map appended")
    harness.equal(context.used:ids()[1], ids.uniq_jessica,
        "unique map saved in floor history")
end

-- The inline source helper writes a one-cell `overwrite_floor_cell` map.
-- Place it on the only existing floor rather than carving a sealed cell
-- at the center of a wall-filled grid.
local function leader_uses_open_floor()
    local builder = grid.new({})

    function builder:roll()
        return 0
    end

    builder:set(5, 5, ".")

    local map = vault_placement.place(nil, builder,
        catalog.get(ids.uniq_jessica), {
            branch_id = branches.BRANCH_DUNGEON,
            depth = 2,
            absolute_depth = 2,
            branch_bottom = 15,
        })

    harness.equal(map.bounds.x, 5, "unique uses open floor x")
    harness.equal(map.bounds.y, 5, "unique uses open floor y")
end

-- Exercise both source outcomes in one run against production catalog IDs.
function test.run(ctx)
    dummy_ends_attempt(ctx)
    real_map_uses_history(ctx)
    leader_uses_open_floor()
end

return test
