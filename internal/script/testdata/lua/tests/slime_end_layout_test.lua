-- Slime:5 must use its pinned whole-floor DES map, not a generic cave.
-- The effective layout catalog is the same one normal travel selects.
local availability = require("policy.generation.floor_availability")
local branches = require("ids.branches")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local items = require("ids.items")
local layouts = require("policy.generation.layouts.catalog")
local monsters = require("ids.monsters")
local names = require("constants.slime_pit")

local test = {}

-- Pin every source MAP byte without copying geometry into the fixture.
local function map_checksum(rows)
    local checksum = 0

    for _, row in ipairs(rows) do
        for index = 1, #row do
            checksum = (checksum * 31 + row:byte(index)) % 4294967296
        end

        checksum = (checksum * 31 + 10) % 4294967296
    end

    return checksum
end

-- Give the real DES operation engine a stable bounded layout stream.
local function random_context()
    local state = 847
    local ctx = {}

    function ctx:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return ctx
end

-- The floor's source records, rather than visible glyphs alone, must
-- contain the exact Royal Jelly and rune needed for play and restore.
function test.run()
    local definition = layouts.get(names.MAP_ID)

    harness.equal(#definition.rows, 70, "source Slime Pit height")
    harness.equal(map_checksum(definition.rows), 2306881643,
        "source Slime Pit MAP bytes")

    for _, row in ipairs(definition.rows) do
        harness.equal(#row, 80, "source Slime Pit row width")
    end

    harness.truthy(layouts.has_explicit(branches.BRANCH_SLIME, 5),
        "Slime:5 has an explicit source end")
    harness.truthy(availability.can_build(branches.BRANCH_SLIME, 5),
        "Slime:5 is available")

    local floor = layouts.execute(random_context(), definition,
        branches.BRANCH_SLIME, 5, {
            up = 3,
            down = 0,
        })
    local runes = 0
    local guardians = 0
    local clear_walls = 0

    for _, record in ipairs(floor.records or {}) do
        local arguments = record.arguments or {}

        if record.kind == effects.ITEM and
            arguments.kind_id == items.RUNE_SLIME then
            runes = runes + 1
        elseif record.kind == effects.MONSTER and
            arguments.kind_id == monsters.MONS_ROYAL_JELLY then
            guardians = guardians + 1
        elseif record.kind == effects.SOURCE_FEATURE and
            record.source == "n" then
            clear_walls = clear_walls + 1
        end
    end

    harness.equal(runes, 1, "one historical slimy rune")
    harness.equal(guardians, 1, "one authored Royal Jelly")
    harness.equal(clear_walls, 44, "source clear stone seal walls")
end

return test
