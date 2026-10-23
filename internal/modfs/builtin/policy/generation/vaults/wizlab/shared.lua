-- Theory of operation: each lab owns its source MAP and local script
-- choices. These helpers port the source wizlab_setup and milestone
-- functions once. They emit typed operations at the caller's hook site;
-- no mutable state or current-lab switch lives in this module.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local rules = require("constants.vault_generation_rules")
local wizlab = require("constants.wizlab")

local shared = {}

-- The source helper made the authored map a whole floor and converted
-- each < into the return arch. Selection metadata is also written in
-- DES so a destination selector sees it before this hook is expanded.
function shared.setup(api)
    api:emit(directives.ORIENT, "encompass")
    api:emit(directives.TAGS, "no_item_gen no_monster_gen")
    api:emit(directives.KFEAT, "< = " .. wizlab.EXIT_FEATURE)
end

-- Shadow-creature and other random-list rules need the source roster
-- even though ambient floor spawning is disabled for Wizard Labs.
function shared.random_monsters(api, expression)
    api:record(effects.GENERATION_RULE, {
        rule = rules.RANDOM_MONSTER_LIST,
        expression = expression,
    })
end

-- Source epilogues announce a lab once. Keep the note and milestone in
-- one typed record, consumed by travel on first entry after staging.
function shared.epilogue(api, description)
    api:record(effects.ENTRY_MESSAGE, {
        text = "Welcome to " .. description .. "!",
        note = "Entered " .. description,
        milestone = "entered " .. description .. ".",
    })
end

return shared
