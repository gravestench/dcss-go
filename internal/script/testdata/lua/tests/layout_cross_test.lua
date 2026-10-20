-- The source cross layout has an uncommon sea/lava window branch. Exercise
-- that branch through its real hook so feature records are not lost.
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local layout = require("policy.generation.layouts.layout_cross")
local stairs = require("policy.generation.layouts.stairs")
local effects = require("constants.vault_effects")
local features = require("content.terrain_features")
local harness = require("tests.harness")

local test = {}

-- Zero draws choose the source window rarity, lava material, and a wide
-- cross; this checks an otherwise hard-to-hit authored feature path.
local function fixed_context()
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "cross layout stream")
        -- Twenty clears the bounded-draw rejection threshold while still
        -- choosing zero for the rarity and material draws used here.
        return 0, 20
    end

    return context
end

-- Varied source draws exercise ordinary rock crosses and spotty growth
-- without maintaining a second implementation of grid randomness.
local function random_context(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "cross layout stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- Keep the DES hook, window feature, and stair pass connected to the same
-- produced grid. No second test-specific layout schema is declared here.
local function source_window()
    local path = "vaults/layout/layout_cross.des"
    local definition = des.parse(path, mod.read(path))

    hooks.validate(definition)

    local result = layout.layout_cross({
        ctx = fixed_context(),
        branch = "D",
        depth = 9,
    })
    local border_feature
    local mask_count = 0

    for _, record in ipairs(result.records) do
        if record.kind == effects.SOURCE_FEATURE and record.source == "L" then
            border_feature = record.identity
        elseif record.kind == effects.MASK then
            mask_count = mask_count + 1
        end
    end

    harness.equal(border_feature, "DNGN_LAVA_SEA", "window sea feature")
    harness.truthy(mask_count > 0, "lava cells mask monster generation")
    harness.equal(#stairs.complete(result.builder), 3, "cross stair pairs")

    local cells = features.decode_source_rows(result.builder:rows())
    features.apply_vault_terrain(cells, result.records, nil, 9)
    harness.equal(cells[1][1], "DNGN_LAVA_SEA", "border feature applied")
end

-- Ordinary cross variants still need one connected playable region for
-- stair completion, whatever spotty growth did to their outer rock.
local function source_ordinary(seed)
    local result = layout.layout_cross({
        ctx = random_context(seed),
        branch = "D",
        depth = 9,
    })

    harness.equal(#stairs.complete(result.builder), 3, "ordinary cross stairs")
    features.decode_source_rows(result.builder:rows())
end

-- One rare branch covers the specific content that the ordinary grid and
-- room layout tests cannot exercise.
function test.run()
    source_window()
    source_ordinary(1)
    source_ordinary(47)
    source_ordinary(891)
end

return test
