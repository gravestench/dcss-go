-- Theory of operation: each parent Gauntlet map lays out the visible
-- choices, while its named `compose` hook places the source arena and exit
-- helpers in the same order. This module only names the repeated steps.
-- The hook's local tier and prize pattern are passed to each child; no
-- process-global source script variables survive between floor builds.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local encounters = require("content.gauntlet.encounters")
local gauntlet = require("constants.gauntlet")
local rules = require("constants.vault_generation_rules")
local transporter = require("constants.transporter")

local shared = {}

-- Shadow monsters and other source substitutions use the first-tier
-- encounter pool. Keep this list derived from the same table that actual
-- arena rolls use, avoiding a second copied monster-name registry.
local function random_monsters(api)
    local expressions = {}

    for _, encounter in ipairs(encounters.first) do
        for _, slot in ipairs({ "first", "second", "third" }) do
            local entry = encounter[slot]

            if entry then
                expressions[#expressions + 1] = entry.mons
            end
        end
    end

    api:record(effects.GENERATION_RULE, {
        rule = rules.RANDOM_MONSTER_LIST,
        expression = table.concat(expressions, " / "),
    })
end

-- The source lists parent entry glyphs and return landing glyphs in
-- child declaration order. Every numbered pair links one arena route.
function shared.setup(api, entries, exits)
    if #entries ~= #exits then
        error("Gauntlet parent has mismatched transporter lists")
    end

    for index = 1, #entries do
        local entry = entries:sub(index, index)
        local exit = exits:sub(index, index)
        local suffix = tostring(index)

        api:emit(directives.MARKER,
            entry .. " = " .. transporter.SOURCE_CALL ..
            '("gauntlet_arena_entry_' .. suffix .. '")')
        api:emit(directives.MARKER,
            exit .. " = " .. transporter.DESTINATION_CALL ..
            '("gauntlet_arena_exit_' .. suffix .. '")')
    end

    random_monsters(api)
end

-- The parent passes its exact source tag, including the 7x7 arena family,
-- and the prize pattern effective at this statement. A later pattern
-- change cannot rewrite an earlier arena's chosen reward distribution.
function shared.arena(api, glyph, tag, extra_items)
    if tag ~= gauntlet.FIRST_TIER_TAG and
        tag ~= gauntlet.SECOND_TIER_TAG and
        tag ~= gauntlet.FIRST_TIER_77_TAG and
        tag ~= gauntlet.SECOND_TIER_77_TAG then
        error("unknown Gauntlet arena tag " .. tostring(tag))
    end

    api:emit(directives.SUBVAULT,
        glyph .. " : " .. tag,
        { extra_items = extra_items })
end

-- Each complete Gauntlet has one minotaur exit helper chosen by the
-- source tag pool. Its own MAP supplies loot, walls, and the final arch.
function shared.exit(api, glyph)
    api:emit(directives.SUBVAULT,
        glyph .. " : " .. gauntlet.EXIT_TAG)
end

-- Source `gauntlet_appearance` turns the parent's < into the return arch.
function shared.appearance(api)
    api:emit(directives.KFEAT,
        "< = " .. gauntlet.EXIT_FEATURE)
end

return shared
