-- The ice serial has one controller and fifteen source-shaped pieces.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local catalog = require("policy.generation.vaults.catalog")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local ids = require("ids.vaults")
local placement = require("policy.generation.vaults.placement")
local tags = require("constants.vault_tags")

local test = {}

-- The source controller rolls four through ten ice pieces, then may ask
-- for a cave entrance only on deep Dungeon floors with an available cave.
local function controller_contract()
    local vault = catalog.get(ids.serial_ice)
    local requests = {}
    local api = {
        context = {
            branch_id = branches.BRANCH_DUNGEON,
        },
    }

    function api:roll(bound)
        return bound - 1
    end

    function api:absolute_depth()
        return 11
    end

    function api:has_tag(tag)
        harness.equal(tag, tags.UNIQ_ICECV, "source cave availability tag")

        return true
    end

    function api:chance(numerator, denominator)
        harness.equal(numerator, 1, "cave coinflip numerator")
        harness.equal(denominator, 2, "cave coinflip denominator")

        return true
    end

    function api:place_maps(tag, count)
        requests[#requests + 1] = {
            tag = tag,
            count = count,
        }
    end

    hooks.run(vault, "place_ice", api)

    harness.equal(#vault.rows, 0, "ice controller has no MAP cells")
    harness.equal(requests[1].tag, tags.SERIAL_ICE, "ice child tag")
    harness.equal(requests[1].count, 10, "maximum ice group size")
    harness.equal(requests[2].tag, tags.CHANCE_ICECAVE,
        "separate cave entry tag")
    harness.equal(requests[2].count, 1, "qualifying cave count")
end

-- The shared named hook changes monster lottery and fog by branch while
-- preserving the same ice surfaces and arch directive on both branches.
local function branch_setup()
    local vault = catalog.get(ids.serial_ice_b)

    for _, branch_id in ipairs({
        branches.BRANCH_DUNGEON,
        branches.BRANCH_COCYTUS,
    }) do
        local emitted = {}
        local markers = {}
        local api = {}

        function api:branch_id()
            return branch_id
        end

        function api:emit(kind, argument)
            emitted[#emitted + 1] = {
                kind = kind,
                argument = argument,
            }
        end

        function api:record(kind, arguments)
            markers[#markers + 1] = {
                kind = kind,
                arguments = arguments,
            }
        end

        hooks.run(vault, "ice_setup.configure", api)

        harness.equal(emitted[1].kind, directives.KMONS,
            "ice monster lottery is first")
        harness.equal(#emitted, 8, "source setup directive count")
        harness.equal(markers[1].kind, effects.MARKER,
            "ice fog remains a typed marker")
        harness.equal(markers[1].arguments.glyph, "!",
            "fog attaches to the authored glyph")

        local monster = branch_id == branches.BRANCH_COCYTUS and
            "ice fiend" or "death yak"
        local cloud = branch_id == branches.BRANCH_COCYTUS and
            "freezing vapour" or "thin mist"

        harness.truthy(emitted[1].argument:find(monster, 1, true),
            "branch-specific monster pool")
        harness.truthy(markers[1].arguments.identity:find(cloud, 1, true),
            "branch-specific fog type")
    end
end

-- Every MAP must parse and place with its shared source setup. The j map
-- alone forces opaque placement so its larger barriers cannot be pierced.
local function every_piece_places()
    local count = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.tags[tags.SERIAL_ICE] then
            count = count + 1
            harness.equal(definition.weight, 2, "source ice weight " .. id)
            harness.truthy(definition.tags.extra, "source extra tag " .. id)
            harness.truthy(definition.tags.mini_float,
                "source mini float tag " .. id)
            harness.equal(not not definition.tags.transparent,
                id ~= ids.serial_ice_j, "source opacity " .. id)

            local vault = catalog.get(id)
            local builder = grid.new({})

            function builder:roll()
                return 0
            end

            local placed = placement.place(nil, builder, vault, {
                branch_id = branches.BRANCH_DUNGEON,
                depth = 10,
                absolute_depth = 10,
                branch_bottom = 15,
                layout_family = "open",
            })

            harness.truthy(placed, "ice piece places " .. id)
            harness.truthy(#vault.rows > 0, "ice piece has MAP rows " .. id)
        end
    end

    harness.equal(count, 15, "complete ice source piece count")
end

-- Cover controller branching, shared setup, and every authored piece.
function test.run()
    controller_contract()
    branch_setup()
    every_piece_places()
end

return test
