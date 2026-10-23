-- wizlab_golubria keeps the original Wizard Lab MAP in its DES file.
-- Each site method below owns one source Lua declaration group.
local shared = require("policy.generation.vaults.wizlab.shared")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local fill = require("constants.vault_border_fill")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")
local transporter = require("constants.transporter")
local wizlab = require("constants.wizlab")

local map = {}

-- Pair each source teleporter glyph with its destination glyph by a
-- stable local name. The existing transporter owner validates and saves
-- these links after the complete MAP has been projected.
function map.site_1(api)
    local sources = "OPQRSTUVW&{("
    local destinations = "opqrstuvw@})"

    for index = 1, #sources do
        local name = wizlab.GOLUBRIA_TRANSPORT_LINK_PREFIX .. index

        api:emit(directives.MARKER,
            sources:sub(index, index) .. " = " ..
            transporter.SOURCE_CALL .. '("' .. name .. '")')
        api:emit(directives.MARKER,
            destinations:sub(index, index) .. " = " ..
            transporter.DESTINATION_CALL .. '("' .. name .. '")')
    end

    -- The source string ends with an empty slash alternative. Its
    -- nonempty entries are the actual random-monster roster.
    shared.random_monsters(api,
        "rakshasa w:15 / deep elf knight w:15 / wizard w:15 / " ..
        "spatial vortex w:15 / boggart / blink frog w:5 / " ..
        "shadow wraith w:5 / unseen horror / raiju / ynoxinul / " ..
        "neqoxec / chaos spawn / glowing orange brain / " ..
        "large abomination w:15 / small abomination w:15 / " ..
        "skeleton w:20 / hellwing w:5 / smoke demon w:5 / " ..
        "hell hound w:5 / ugly thing w:5 / golden eye w:5 / " ..
        "executioner w:3 / shadow demon w:4 / hellion w:3 / " ..
        "thrashing horror w:25 / tentacled starspawn w:25")
    api:record(effects.BORDER_FILL, {
        style = fill.PERMAROCK_WALL,
    })
    api:record(effects.FEATURE_NAME, {
        feature = features.PERMAROCK_WALL,
        name = names.WIZLAB_DIMENSION_EDGE,
    })
    api:record(effects.FEATURE_NAME, {
        feature = features.CRYSTAL_WALL,
        name = names.WIZLAB_CRYSTAL_WALL,
    })
    shared.setup(api)
end

-- The source epilogue names this room on first entry.
function map.epilogue(api)
    shared.epilogue(api, "The Roulette of Golubria")
end

return map
