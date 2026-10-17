local harness = require("tests.harness")
local ids = require("ids.traps")
local placement = require("policy.traps.placement")
local streams = require("constants.rng_streams")
local effects = require("constants.vault_effects")
local terrain = require("content.terrain_features")

local test = {}

local function context(draw)
    local ctx = {}

    function ctx:random(stream, bound)
        harness.equal(stream, streams.TRAPS, "trap RNG stream")
        harness.truthy(draw >= 0 and draw < bound,
            "fixture draw stays in range")

        return draw
    end

    return ctx
end

local function record(identity)
    return {
        identity = identity,
        source_id = "fixture",
        source = "^",
        line = 4,
    }
end

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

    harness.equal(placement.resolve(context(4),
        record("random_trap"), 1), ids.TRAP_SHAFT,
        "D:1 authored random trap can be a shaft")

    harness.equal(placement.resolve(context(0),
        record("random_trap"), 2), ids.TRAP_TELEPORT_PERMANENT,
        "D:2 authored random trap uses the regular source set")

    harness.equal(placement.resolve(context(4),
        record("random_trap"), 2), ids.TRAP_DISPERSAL,
        "D:2 excludes shafts when no lower floor exists")

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
        random = function()
            error("selected trap must not be rerolled")
        end,
    }

    harness.equal(placement.resolve(no_reroll, trap_remaining[1], 1),
        ids.TRAP_TELEPORT, "selected trap resolves without another draw")
end

return test
