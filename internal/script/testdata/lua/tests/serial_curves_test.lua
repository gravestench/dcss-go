-- Source curved corridors are one controller plus four playable child maps.
local branches = require("ids.branches")
local chance_units = require("constants.vault_chance")
local catalog = require("policy.generation.vaults.catalog")
local chance = require("policy.generation.vaults.chance")
local controller = require("policy.generation.vaults.controller")
local extra = require("policy.generation.vaults.extra")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local ids = require("ids.vaults")
local used = require("policy.generation.vaults.used")

local test = {}
local EXTRA_OPPORTUNITY_ROLL = 8

local names = {
    ids.serial_curves,
    ids.eino_curves_01,
    ids.eino_curves_02,
    ids.eino_curves_03,
    ids.eino_curves_04,
}

-- The family is discovered as separate effective DES maps. No alternate
-- Lua table may become a second authority for these source definitions.
local function registered_source_family()
    local paths = mod.paths("vaults/serial", ".des")

    harness.equal(#paths, #names, "complete curved-corridor family")

    for _, name in ipairs(names) do
        harness.equal(catalog.get(name).id, name,
            "catalog registers source map " .. name)
    end

    harness.equal(#catalog.get(ids.serial_curves).rows, 0,
        "controller has no MAP cells")
    harness.truthy(chance.layout_allowed(
        catalog.get(ids.serial_curves), "rooms"),
        "controller is eligible on rooms layouts")
    harness.falsy(chance.layout_allowed(
        catalog.get(ids.serial_curves), "halls"),
        "controller does not run on unrelated layouts")
end

-- Source chooses two to four corridors before its post-place hook. Draws
-- from one layout stream keep the later child map choices reproducible.
local function controller_requests_source_count()
    local requested_tag
    local requested_count
    local api = {}

    -- Both source count factors receive one, producing three children.
    function api:roll()
        return 1
    end

    -- Capture the controller request without replacing the production hook.
    function api:place_maps(tag, count)
        requested_tag = tag
        requested_count = count
    end

    hooks.run(catalog.get(ids.serial_curves),
        "place_serial_curves", api)

    harness.equal(requested_tag, ids.serial_curves,
        "controller requests its child family")
    harness.equal(requested_count, 3,
        "source two plus product of two draws")
end

-- Every child must fit a normal Dungeon grid through the same geometric
-- path used by chance and ordinary secondary placement.
local function children_place_on_dungeon_floor()
    for index = 2, #names do
        local builder = grid.new({})

        for y = 1, 68 do
            for x = 1, 78 do
                builder:set(x, y, ".")
            end
        end

        -- Keep each child at one predictable unprotected origin.
        function builder:roll()
            return 0
        end

        local placed = extra.place(nil, builder,
            catalog.get(names[index]), {
                branch_id = branches.BRANCH_DUNGEON,
                depth = 4,
                branch_bottom = 15,
                protected = {},
                required = {},
                player = {
                    branch_id = branches.BRANCH_DUNGEON,
                    depth = 4,
                    branch_bottom = 15,
                    map_tag = ids.serial_curves,
                },
            })

        harness.truthy(placed,
            "curved-corridor child fits " .. names[index])
    end
end

-- Source dgn.place_maps counts successful fits and leaves a geometrically
-- rejected child out of the level. A tight floor must not abort generation.
local function rejected_child_does_not_abort_controller()
    local builder = grid.new({})

    -- Choose the first real child so only geometric rejection is tested.
    function builder:roll()
        return 0
    end

    local placed = {}
    local context = {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 4,
        branch_bottom = 15,
        used = used.new({}),
        player = {},
    }

    -- Force a placement miss without changing the real selector, so the
    -- controller's return value tests source dgn.place_maps behavior.
    local function reject_fit()
        return nil, "no geometric fit"
    end

    local api = controller.new(builder, context, placed, reject_fit)

    harness.equal(api:place_maps(ids.serial_curves, 2), 0,
        "failed children are counted but do not abort")
    harness.equal(#placed, 0, "failed children have no placed records")
end

-- A one-percent roll on a rooms layout runs the empty-map controller,
-- records its ID, and places the requested child corridors through Lua.
local function chance_stage_runs_curves_controller()
    local builder = grid.new({})

    for y = 1, 68 do
        for x = 1, 78 do
            builder:set(x, y, ".")
        end
    end

    local chance_draws = 0
    local other_draws = 0

    -- Admit the first one-percent map, reject the later shop controller,
    -- and vary geometric draws so tagged children can fit apart.
    function builder:roll(bound)
        if bound == chance_units.ROLL then
            chance_draws = chance_draws + 1

            return chance_draws == 1 and 0 or chance_units.ROLL - 1
        end

        if bound == EXTRA_OPPORTUNITY_ROLL then
            return 1
        end

        other_draws = other_draws + 1

        return other_draws % bound
    end

    local placed, primary, vault_ids = extra.generate(nil, builder, {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 4,
        branch_bottom = 15,
        absolute_depth = 4,
        layout_family = "rooms",
        protected = {},
        required = {},
        player = {
            branch_id = branches.BRANCH_DUNGEON,
            depth = 4,
            branch_bottom = 15,
        },
    })

    harness.equal(primary, ids.serial_curves,
        "chance stage selected curved-corridor controller")
    harness.equal(vault_ids[1], primary,
        "empty-map controller enters saved history")
    harness.truthy(#placed > 0,
        "controller placed at least one tagged corridor")

    local children = {}

    for index = 2, #names do
        children[names[index]] = true
    end

    for _, map in ipairs(placed) do
        harness.truthy(children[map.id],
            "controller children come from the curved family")
    end
end

-- Keep catalog, controller, and geometric checks together: a registered
-- serial family is only useful when all of its children can run.
function test.run()
    registered_source_family()
    controller_requests_source_count()
    children_place_on_dungeon_floor()
    rejected_child_does_not_abort_controller()
    chance_stage_runs_curves_controller()
end

return test
