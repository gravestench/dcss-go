-- The mapless source `bailey` controller must select one themed child
-- through the effective catalog. An empty controller cannot be painted
-- as a floor, and changing file discovery order cannot change the draw.
local bailey = require("constants.bailey")
local branches = require("ids.branches")
local catalog = require("policy.generation.vaults.catalog")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local item_specs = require("policy.generation.vaults.specs.item")
local missile_brands = require("constants.missile_brands")
local placement = require("policy.generation.vaults.placement")
local resolve = require("policy.generation.vaults.specs.resolve")
local terrain = require("constants.terrain")

local test = {}

-- Each requested source layout gets an isolated stream; a failed layout
-- therefore reports its own error instead of consuming another test's RNG.
local function random_context()
    local state = 83
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    function context:random(_, bound)
        state = (state * 48271) % 2147483647

        return state % bound
    end

    return context
end

-- A requested child still goes through the dispatcher and ordinary
-- placement, so every source map proves it can become a playable floor.
function test.run()
    -- Source DES calls the canonical missile brands by their dart names.
    -- The real resolver must carry both through as distinct saved egos.
    local darts = catalog.get("bailey_axe_3")
    local dart_operation

    for _, operation in ipairs(darts.operations) do
        if operation.argument and
            operation.argument:find("ego:datura", 1, true) then
            dart_operation = operation
            break
        end
    end

    harness.truthy(dart_operation, "source Bailey datura dart request")

    local site = {
        path = darts.path,
        id = darts.id,
        line = dart_operation.line,
    }
    local dart_choices = item_specs.parse(dart_operation.argument, site)[1]

    harness.equal(resolve.item({}, dart_choices[1], 11, site).ego,
        missile_brands.BLINDING,
        "source atropa resolves to the blinding missile brand")
    harness.equal(resolve.item({}, dart_choices[2], 11, site).ego,
        missile_brands.FRENZY,
        "source datura resolves to the frenzy missile brand")

    local level = require("policy.generation.bailey.level")
    local axe = level.candidates(bailey.AXE, {})
    local polearm = level.candidates(bailey.POLEARM, {})

    harness.equal(#axe, 6, "effective axe Bailey layouts")
    harness.equal(#polearm, 9, "effective polearm Bailey layouts")
    harness.truthy(terrain.DNGN_EXIT_BAILEY,
        "Bailey exit terrain must have a named ID")

    for _, group in ipairs({
        { theme = bailey.AXE, maps = axe },
        { theme = bailey.POLEARM, maps = polearm },
    }) do
        for index, map in ipairs(group.maps) do
            if index > 1 then
                harness.truthy(group.maps[index - 1].id < map.id,
                    "Bailey candidates must follow stable ID order")
            end

            local generated = level.generate(random_context(), {
                theme = group.theme,
                layout_id = map.id,
                species_id = "SP_HUMAN",
                player_name = "Tester",
            })
            local floor = generated.level
            local arrival = floor.cells[floor.entry_y + 1]

            harness.equal(floor.branch_id, branches.BRANCH_BAILEY,
                map.id .. " branch identity")
            harness.equal(floor.vault_id, map.id,
                map.id .. " selected child identity")
            harness.equal(floor.vault_ids[1], "bailey",
                map.id .. " missing source dispatcher history")
            harness.equal(floor.vault_ids[2], map.id,
                map.id .. " missing child history")
            harness.equal(arrival[floor.entry_x + 1],
                terrain.DNGN_EXIT_BAILEY,
                map.id .. " has no safe arrival at its return exit")
        end
    end

    local builder = grid.new(random_context())
    local controller = catalog.get("bailey")
    local direct = pcall(placement.place, random_context(),
        builder, controller, {}, { whole_level = true })

    harness.truthy(not direct,
        "mapless Bailey controller must never reach geometry placement")

    local missing = pcall(level.generate, random_context(), {
        species_id = "SP_HUMAN",
        player_name = "Tester",
    })

    harness.truthy(not missing,
        "Bailey generation requires the entrance's saved theme")
end

return test
