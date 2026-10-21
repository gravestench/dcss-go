-- Orc's old corpses and skeletons are source generation intent. These
-- records must survive selection and placement so the live decay owner can
-- materialize them after the floor is saved and revisited.
local branches = require("ids.branches")
local effects = require("constants.vault_effects")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- A tiny deterministic random source drives the production DES fitter.
local function random_context()
    local value = 73
    local context = {}

    function context:random_u64()
        value = (value * 48271) % 2147483647
        local high = value

        value = (value * 48271) % 2147483647

        return high, value
    end

    return context
end

-- Return only typed decay records from one actually placed source map.
local function decays(id)
    local definition = vaults.get(id)
    local player = {
        branch_id = branches.BRANCH_ORC,
        depth = 2,
        branch_bottom = 2,
        absolute_depth = 11,
    }
    local placed = placement.place(nil, grid.new(random_context()),
        definition, player)
    local records = {}

    for _, record in ipairs(placed.records) do
        if record.kind == effects.DELAYED_DECAY then
            records[#records + 1] = record.arguments
        end
    end

    return records
end

-- One source glyph can occur at several transformed map cells. Every
-- matching record still needs the authored corpse and optional debris.
local function has_decay(records, glyph, alternatives, extra_items)
    for _, record in ipairs(records) do
        if record.glyph == glyph and
            record.alternatives == alternatives and
            record.extra_items == extra_items then
            return true
        end
    end

    return false
end

-- The cave-in keeps corpse and debris together; the feast keeps two
-- different skeleton species on their own authored glyphs.
function test.run()
    vaults.load()

    local river = decays("mines_bat_river")

    harness.truthy(has_decay(river, "e", "bat corpse"),
        "bat river source corpse and glyph")

    local rockfall = decays("nicolae_orc_rockfall")

    harness.truthy(has_decay(rockfall, "o", "orc corpse",
        "stone q:1 / nothing, large rock q:1"),
        "rockfall source corpse and debris")

    local feast = decays("grunt_orc_tribal_feast")

    harness.truthy(has_decay(feast, "d", "yak skeleton"),
        "feast yak remains")
    harness.truthy(has_decay(feast, "e", "rat skeleton"),
        "feast rat remains")
end

return test
