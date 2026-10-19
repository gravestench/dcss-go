-- Authored random traps draw uniformly from the regular IDs in catalog order;
-- the source depth gate admits shafts on D:1 and excludes them from D:2.

local harness = require("tests.harness")
local categories = require("constants.catalog")
local catalog = require("policy.catalog")
local ids = require("ids.traps")
local placement = require("policy.traps.placement")
local streams = require("constants.rng_streams")
local effects = require("constants.vault_effects")
local terrain = require("content.terrain_features")

local test = {}

-- Supply an exact trap-stream draw and optional bound assertion, making
-- weighted selection behavior observable without depending on a seed.
local function context(draw, expected_bound)
    local ctx = {}

    -- Assert placement uses the trap stream and eligible-pool size before
    -- returning the requested deterministic selection index.
    function ctx:random(stream, bound)
        harness.equal(stream, streams.TRAPS, "trap RNG stream")
        if expected_bound then
            harness.equal(bound, expected_bound,
                "regular trap draw covers each eligible ID once")
        end
        harness.truthy(draw >= 0 and draw < bound,
            "fixture draw stays in range")

        return draw
    end

    return ctx
end

-- Wrap one DES trap token with source location data so resolution failures
-- can be tied back to the map entry that produced them.
local function record(identity)
    return {
        identity = identity,
        source_id = "fixture",
        source = "^",
        line = 4,
    }
end

-- Resolve named, random, and preselected trap instructions through the same
-- production parser path to guard their distinct draw contracts.
function test.run()
    harness.equal(placement.resolve(context(0),
        record("teleport trap"), 1), ids.TRAP_TELEPORT,
        "named teleport feature")

    harness.equal(placement.resolve(context(0),
        record("DNGN_PASSAGE_OF_GOLUBRIA"), 1),
        ids.TRAP_GOLUBRIA, "source Golubria feature")

    harness.equal(placement.resolve(context(0),
        record("web trap"), 1), ids.TRAP_WEB,
        "vault web alias")

    harness.equal(placement.resolve(context(10),
        record("teleport trap / shaft trap w:20"), 1),
        ids.TRAP_SHAFT, "weighted shaft alternative")

    local regular = {
        ids.TRAP_ALARM,
        ids.TRAP_DISPERSAL,
        ids.TRAP_NET,
        ids.TRAP_SHAFT,
        ids.TRAP_TELEPORT_PERMANENT,
        ids.TRAP_ZOT,
    }
    local definitions = catalog.all(categories.TRAPS)
    local found = {}

    for _, definition in ipairs(definitions) do
        if definition.regular then
            found[#found + 1] = definition.id
        end
    end

    harness.equal(#found, #regular, "regular source trap count")

    -- Exercise every seeded draw at both depths, including the final bound.
    for index, id in ipairs(regular) do
        harness.equal(found[index], id, "regular traps use stable ID order")
        harness.equal(placement.resolve(context(index - 1, #regular),
            record("random_trap"), 1), id,
            "D:1 draw selects each regular trap")
    end

    local depth_two = {
        ids.TRAP_ALARM,
        ids.TRAP_DISPERSAL,
        ids.TRAP_NET,
        ids.TRAP_TELEPORT_PERMANENT,
        ids.TRAP_ZOT,
    }

    for index, id in ipairs(depth_two) do
        harness.equal(placement.resolve(context(index - 1, #depth_two),
            record("random_trap"), 2), id,
            "D:2 draw excludes shafts and selects each remaining trap")
    end

    harness.truthy(placement.is_trap(record("shaft trap / granite_statue")),
        "mixed feature expression can select a trap")
    harness.falsy(placement.is_trap(record("granite_statue")),
        "ordinary source feature stays with terrain policy")

    local floor_record = record("teleport trap / floor")
    floor_record.kind = effects.FEATURE
    floor_record.x = 0
    floor_record.y = 0
    local floor_cells = { { "DNGN_FLOOR" } }
    local floor_remaining = terrain.apply_vault_terrain(
        floor_cells, { floor_record }, context(10), 1)

    harness.equal(#floor_remaining, 0,
        "selected floor feature is applied during generation")
    harness.equal(floor_cells[1][1], "DNGN_FLOOR",
        "selected floor has terrain identity")

    local trap_record = record("teleport trap / floor")
    trap_record.kind = effects.FEATURE
    trap_record.x = 0
    trap_record.y = 0
    local trap_remaining = terrain.apply_vault_terrain(
        { { "DNGN_FLOOR" } }, { trap_record }, context(0), 1)

    harness.equal(trap_remaining[1].identity, ids.TRAP_TELEPORT,
        "selected trap identity persists for population")

    local no_reroll = {
        -- Preselected vault traps must retain their chosen ID; any new draw
        -- here would change seeded placement and violate source intent.
        random = function()
            error("selected trap must not be rerolled")
        end,
    }

    harness.equal(placement.resolve(no_reroll, trap_remaining[1], 1),
        ids.TRAP_TELEPORT, "selected trap resolves without another draw")
end

return test
