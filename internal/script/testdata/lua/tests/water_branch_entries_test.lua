-- These source Lair gates are separate DES maps, but one scheduled entry
-- selector must choose each branch's complete weighted pool.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local entry = require("policy.generation.vaults.branch_entry")
local features = require("constants.vault_features")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local tags = require("constants.vault_tags")
local vaults = require("policy.generation.vaults.catalog")
local placement = require("policy.generation.vaults.placement")
local rooms = require("policy.generation.vaults.shoals_entry.elwin_shoals_entry_rooms")

local test = {}

-- A water substitution that seals O must redraw this particular Shoals
-- room, while a surviving walkable route to an edge can be placed.
local function room_validator()
    local sealed = {
        { "x", "x", "x", "x", "x" },
        { "x", ".", "w", ".", "x" },
        { "x", "w", "O", "w", "x" },
        { "x", ".", "w", ".", "x" },
        { "x", "x", "x", "x", "x" },
    }
    local open = {
        { "x", "x", ".", "x", "x" },
        { "x", ".", ".", ".", "x" },
        { "x", "w", "O", "w", "x" },
        { "x", ".", "w", ".", "x" },
        { "x", "x", "x", "x", "x" },
    }

    harness.falsy(rooms.has_exit({ cells = sealed }),
        "sealed Shoals gate should redraw")
    harness.truthy(rooms.has_exit({ cells = open }),
        "open Shoals gate should fit")
end

-- Each map receives its own stream so a source substitution failure names
-- that map rather than depending on which candidate happened to run first.
local function random_context()
    local state = 59
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- Run the production DES placement path, including keyed features and
-- MARKER records, with the same parent-branch facts used for live gates.
local function place(definition)
    local builder = grid.new(random_context())
    local player = {
        branch_id = branches.BRANCH_LAIR,
        depth = 3,
        branch_bottom = 5,
        absolute_depth = 11,
    }

    return placement.place(nil, builder, definition, player)
end

-- An entry must have exactly one keyed gate and preserve each authored
-- Swamp fog marker for population's existing ECS fog-machine owner.
local function check_family(family, tag, feature, expected)
    local count = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if definition.family == family then
            count = count + 1

            harness.truthy(definition.tags[tag],
                id .. " lost its source entrance tag")

            local placed = place(definition)
            local gates = 0
            local fog = 0

            for _, record in ipairs(placed.records) do
                if record.kind == effects.FEATURE and
                    record.directive == directives.KFEAT and
                    record.identity == feature then
                    gates = gates + 1
                end

                if record.kind == effects.MARKER and
                    record.identity:find("lua:fog_machine", 1, true) then
                    fog = fog + 1
                end
            end

            harness.equal(gates, 1, id .. " keyed entrance count")

            if family == "swamp_entry" then
                harness.truthy(fog > 0, id .. " lost its source fog marker")
            end
        end
    end

    harness.equal(count, expected, family .. " source definition count")
end

-- Source weights and IDs enter the same stable selector as other Lair
-- branches; neither the test nor Go code supplies a parallel roster.
function test.run()
    vaults.load()
    room_validator()

    check_family("swamp_entry", tags.SWAMP_ENTRY,
        features.ENTER_SWAMP, 10)
    check_family("shoals_entry", tags.SHOALS_ENTRY,
        features.ENTER_SHOALS, 8)

    harness.equal(#entry.candidates(branches.BRANCH_SWAMP), 10,
        "all source Swamp gates are weighted candidates")
    harness.equal(#entry.candidates(branches.BRANCH_SHOALS), 8,
        "all source Shoals gates are weighted candidates")
end

return test
