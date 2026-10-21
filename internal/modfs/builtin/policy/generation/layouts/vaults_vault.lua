-- Theory of operation: the source Vaults:$ MAP is the whole level. Its
-- SHUFFLE operation moves A/B/C/D before this hook picks one prize quadrant
-- and three ordinary ones. A rare mall draw changes all four helper pools.
-- The etched-wall names are typed records; terrain still uses normal walls.
local categories = require("constants.catalog")
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

-- A generated end floor is only valid if the composed helper tree owns
-- four quadrants and the single collectible silver rune. Fail at generation
-- rather than recording a broken floor that restore would later reject.
local function require_rune(result)
    -- The shared placement engine first validates the local DES cells,
    -- before its child maps and typed records exist. The catalog calls
    -- this method again with the composed result, and save restore calls
    -- it with historical records. Only those later calls can count runes.
    if result.cells and not result.records and
        not result.vault_records then
        return true
    end

    local rune_item = require("ids.items").RUNE_VAULTS
    local quadrant_count = 0
    local rune_helper_count = 0
    local rune_item_count = 0

    for _, id in ipairs(result.vault_ids or {}) do
        local helper = register.get(categories.VAULTS, id)

        if helper.tags[tags.VAULTS_END_QUADRANT] or
            helper.tags[tags.VAULTS_END_QUADRANT_PRIZE] then
            quadrant_count = quadrant_count + 1
        end

        if helper.tags[tags.VAULTS_END_RUNE] then
            rune_helper_count = rune_helper_count + 1
        end
    end

    -- Generation and save projection name the same typed list differently.
    -- The source validator reads either without duplicating rune rules.
    for _, record in ipairs(result.records or result.vault_records or {}) do
        if record.kind == effects.ITEM and record.arguments and
            record.arguments.kind_id == rune_item then
            rune_item_count = rune_item_count + 1
        end
    end

    if rune_item_count ~= 1 or rune_helper_count ~= 1 then
        error(string.format("Vaults end needs exactly one silver rune item and helper (items=%d, helpers=%d)",
            rune_item_count, rune_helper_count))
    end

    if quadrant_count ~= 4 then
        error("Vaults end needs exactly four source quadrants")
    end

    return true
end

layout.choose_quadrants = choose_quadrants
layout.wall_names = wall_names
layout.require_rune = require_rune

return layout
