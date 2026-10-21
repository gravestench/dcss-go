-- Theory of operation: the same authored holy Pan map holds the demonic
-- rune until pickup, then offers a return exit on later selections. The
-- source feature names and ambient holy monster pool apply either way.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")
local messages = require("constants.pan_messages")
local rules = require("constants.vault_generation_rules")
local runes = require("constants.runes")

local handler = {}

-- One O declaration is emitted from saved rune progress. Leaving both
-- source conditional lines active would put a portal on an unclaimed rune.
local function rune_or_exit(api)
    if api:has_rune(runes.DEMONIC) then
        api:emit(directives.KFEAT, "O = exit_pandemonium")

        return
    end

    api:emit(directives.KITEM, "O = demonic rune of Zot")
end

-- Feature names are typed records so terrain inspection still shows the
-- source's gold and silver descriptions after save and restore.
local function feature_names(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.GOLDEN_STATUE,
    })
    api:record(effects.FEATURE_NAME, {
        feature = features.METAL_WALL,
        name = names.SILVER_WALL,
    })
end

-- This map changes the whole region's background population to holy
-- creatures, not just the monsters keyed in its local MAP cells.
local function population(api)
    api:record(effects.GENERATION_RULE, {
        rule = rules.RANDOM_MONSTER_LIST,
        expression = "angel w:20 / cherub / ophan / daeva / apis w:20",
    })
end

-- The first visit warns that the unusual holy vault contains a Pan rune.
-- Save the message as level data so visiting the region can display it.
local function epilogue(api)
    if not api:has_rune(runes.DEMONIC) then
        api:record(effects.ENTRY_MESSAGE, {
            text = messages.HOLY_RUNE_WARNING,
        })
    end
end

handler.rune_or_exit = rune_or_exit
handler.feature_names = feature_names
handler.population = population
handler.epilogue = epilogue

return handler
