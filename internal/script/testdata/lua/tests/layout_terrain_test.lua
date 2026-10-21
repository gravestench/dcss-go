-- Generated layouts and placed vaults must interpret the same source glyphs.
-- This test imports the production vocabulary instead of maintaining a
-- separate table of expected DES syntax.
local features = require("content.terrain_features")
local glyphs = require("constants.vault_glyphs")
local effects = require("constants.vault_effects")
local generated = require("policy.generation.generated")
local harness = require("tests.harness")

local test = {}

-- Every currently supported vault terrain glyph must decode on a generated
-- floor too, including alternate walls, pools, and stair variants.
local function decodes_layout_glyphs()
    for glyph, identity in pairs(glyphs.terrain) do
        local effective = features.vault_terrain[identity]

        if effective then
            local cells = features.decode_source_rows({ glyph })

            harness.equal(cells[1][1], effective, "source glyph " .. glyph)
        end
    end
end

-- The basic layout's plain glyphs keep their established meanings while
-- new DES glyphs are admitted through the common source table.
local function keeps_basic_layout_features()
    local cells = features.decode_source_rows({ "#.+'<>" })

    harness.equal(cells[1][1], "DNGN_ROCK_WALL", "basic rock")
    harness.equal(cells[1][2], "DNGN_FLOOR", "basic floor")
    harness.equal(cells[1][3], "DNGN_CLOSED_DOOR", "basic closed door")
    harness.equal(cells[1][4], "DNGN_OPEN_DOOR", "basic open door")
    harness.equal(cells[1][5], "DNGN_STONE_STAIRS_UP_I", "basic up stair")
    harness.equal(cells[1][6], "DNGN_STONE_STAIRS_DOWN_I", "basic down stair")
end

-- A source typo must still fail with a precise coordinate.
local function rejects_unknown_glyph()
    local ok, message = pcall(features.decode_source_rows, { "#?" })

    harness.falsy(ok, "unknown layout glyph")
    harness.truthy(tostring(message):find("(1,0)", 1, true), "glyph coordinate")
end

-- A later authored vault may cover a layout wall. Its floor must win over
-- the older wall's source record, while an unobstructed water record still
-- upgrades the floor placeholder into its intended terrain.
local function skips_overwritten_source_features()
    local cells = features.decode_source_rows({ ".." })
    local records = {
        {
            kind = effects.SOURCE_FEATURE,
            identity = "DNGN_ROCK_WALL",
            source = "x",
            base_glyph = "#",
            x = 0,
            y = 0,
        },
        {
            kind = effects.SOURCE_FEATURE,
            identity = "DNGN_SHALLOW_WATER",
            source = "W",
            base_glyph = ".",
            x = 1,
            y = 0,
        },
    }

    features.apply_vault_terrain(cells, records)

    harness.equal(cells[1][1], "DNGN_FLOOR", "new authored floor wins")
    harness.equal(cells[1][2], "DNGN_SHALLOW_WATER", "surviving water intent")
end

-- A new authored map owns every non-space source cell, even when it paints
-- the same placeholder glyph as an older water record. Connector carving
-- also takes ownership of any older source feature it opens.
local function tracks_later_map_ownership()
    local water = {
        kind = effects.SOURCE_FEATURE,
        identity = "DNGN_SHALLOW_WATER",
        source = "W",
        base_glyph = ".",
        x = 0,
        y = 0,
    }
    local rock = {
        kind = effects.SOURCE_FEATURE,
        identity = "DNGN_ROCK_WALL",
        source = "x",
        base_glyph = "#",
        x = 1,
        y = 0,
    }
    local records = {}

    generated.append_vault_records(records, {
        {
            records = { water, rock },
        },
        {
            records = {},
            occupied = {
                { x = 0, y = 0 },
            },
            carved = {
                ["1:0"] = true,
            },
        },
    })

    harness.truthy(water.overridden, "same-glyph authored overlay")
    harness.truthy(rock.overridden, "connector carve owns old wall")
end

-- Check the common decoder as a unit before live weighted layout selection.
function test.run()
    decodes_layout_glyphs()
    keeps_basic_layout_features()
    rejects_unknown_glyph()
    skips_overwritten_source_features()
    tracks_later_map_ownership()
end

return test
