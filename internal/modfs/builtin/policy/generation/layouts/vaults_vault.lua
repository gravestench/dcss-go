-- Theory of operation: the source Vaults:$ MAP is the whole level. Its
-- SHUFFLE operation moves A/B/C/D before this hook picks one prize quadrant
-- and three ordinary ones. A rare mall draw changes all four helper pools.
-- The etched-wall names are typed records; terrain still uses normal walls.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")
local tags = require("constants.vault_tags")

local layout = {}

-- Keep the source's one-in-36 mall variant. A is always the prize selector,
-- but SHUFFLE has already changed which physical quadrant carries A.
local function choose_quadrants(api)
    local mall = api:one_in(36)
    local prize_tag = mall and tags.VAULTS_END_QUADRANT_PRIZE_MALL or
        tags.VAULTS_END_QUADRANT_PRIZE
    local ordinary_tag = mall and tags.VAULTS_END_QUADRANT_MALL or
        tags.VAULTS_END_QUADRANT

    api:emit(directives.SUBVAULT, "A : " .. prize_tag)

    local ordinary_glyphs = {
        "B",
        "C",
        "D",
    }

    for _, glyph in ipairs(ordinary_glyphs) do
        api:emit(directives.SUBVAULT, glyph .. " : " .. ordinary_tag)
    end
end

-- Naming the decorative materials should not alter collision, lighting,
-- or their underlying source feature identities.
local function wall_names(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.METAL_WALL,
        name = names.HEAVILY_ETCHED_METAL_WALL,
    })
    api:record(effects.FEATURE_NAME, {
        feature = features.CRYSTAL_WALL,
        name = names.HEAVILY_ETCHED_CRYSTAL_WALL,
    })
end

layout.choose_quadrants = choose_quadrants
layout.wall_names = wall_names

return layout
