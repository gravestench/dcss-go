-- Crystal Crosses grows harsher with absolute depth. Its DES owns six
-- tagged child arms, geometry, keyed actors, and fixed substitutions; this
-- script calculates only the depth-shaped chamber odds and ambient roster.
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local rules = require("constants.vault_generation_rules")

local handler = {}

-- Retain the source's four threshold terms even when the current four-level
-- Depths range always reaches the later branch of the formula. A modded
-- branch or depth can then still reuse this map's original progression.
local function configure(api)
    local absolute = api:absolute_depth()
    local first = math.max(62 - absolute * 2, 2)
    local second = math.max(60 - absolute * 2, 2)
    local expression = "1 = 1:" .. first .. " 2:" .. second

    if absolute * 5 - 74 > 0 then
        expression = expression .. " 3:" .. absolute * 5 - 74 ..
            " 4:" .. absolute * 5 - 78
    end

    api:emit(directives.SUBST, expression)
    api:emit(directives.MARKER,
        "T = lua:props_marker { portal=1 }")

    local branch = register.get(categories.BRANCHES, api:branch_id())
    local place = branch.abbreviation .. ":" .. api:depth()

    api:record(effects.GENERATION_RULE, {
        rule = rules.RANDOM_MONSTER_LIST,
        expression = "place:" .. place .. " w:210 / rakshasa / " ..
            "dancing weapon / glowing shapeshifter / very ugly thing band",
    })
end

handler.configure = configure

return handler
