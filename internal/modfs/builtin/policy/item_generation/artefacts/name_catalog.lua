local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local markers = require("constants.randart_name_markers")

local name_catalog = {}
local maximum_depth = 10
local maximum_replacements = 100

-- A source key may be a nested weighted group or one of the few fields the
-- game fills from its current player and world. Missing nested groups fail
-- during boot validation instead of leaving @markers@ in an item name.
local function source_group(key)
    local found, definition = pcall(catalog.get,
        categories.RANDART_NAMES, key:lower())

    if found then
        return definition
    end

    return nil
end

-- Select one phrase by the source's default-ten or explicit integer weight.
-- The caller owns the cosmetic RNG, so this lookup never touches game state.
local function choose(random, definition)
    local total = 0

    for _, entry in ipairs(definition.entries) do
        total = total + entry.weight
    end

    local roll = random(total)

    if roll < 0 or roll >= total or roll % 1 ~= 0 then
        error("invalid random-name draw for " .. definition.id)
    end

    for _, entry in ipairs(definition.entries) do
        if roll < entry.weight then
            return entry.text
        end

        roll = roll - entry.weight
    end

    error("random-name group has no selectable phrase " .. definition.id)
end

-- Resolve one source marker after weighted selection. Database references
-- recurse, while player/world placeholders use the explicit supplied facts.
local function replace(random, marker, replacements, state)
    marker = marker:lower()
    state.replacements = state.replacements + 1

    if state.replacements > maximum_replacements then
        error("too many random-name replacements")
    end

    if source_group(marker) then
        return name_catalog.draw(random, marker, replacements, state)
    end

    local replacement = replacements[marker]

    if replacement == nil and replacements.resolve then
        replacement = replacements.resolve(replacements, marker, random)
    end

    if type(replacement) == "function" then
        replacement = replacement(random)
    end

    if type(replacement) ~= "string" or replacement == "" then
        error("missing random-name replacement " .. marker)
    end

    return replacement
end

-- Source book subjects can be supplied outside the weighted catalog. Route
-- them through the same bounded marker expansion as catalog phrases.
local function expand_phrase(random, phrase, replacements, state)
    local output = ""
    local next_position = 1

    while true do
        local first, last, marker = phrase:find("@([^@]+)@", next_position)

        if not first then
            break
        end

        output = output .. phrase:sub(next_position, first - 1) ..
            replace(random, marker, replacements or {}, state)
        next_position = last + 1
    end

    return output .. phrase:sub(next_position)
end

-- Expand a caller-supplied title fragment using the same known marker and
-- nested-group rules as a selected source phrase.
function name_catalog.expand(random, phrase, replacements)
    return expand_phrase(random, phrase, replacements or {}, {
        depth = 0,
        replacements = 0,
    })
end

-- Expand weighted source entries with bounded recursion. The source text DB
-- permits unresolved markers for C++ substitutions; Lua requires those facts
-- explicitly so mods cannot accidentally ship an @token@ to the game UI.
function name_catalog.draw(random, key, replacements, state)
    local definition = source_group(key)

    if not definition then
        error("unknown random-name group " .. tostring(key))
    end

    state = state or {
        depth = 0,
        replacements = 0,
    }
    state.depth = state.depth + 1

    if state.depth > maximum_depth then
        error("too many nested random-name groups")
    end

    local phrase = choose(random, definition)
    local expanded = expand_phrase(random, phrase,
        replacements or {}, state)

    state.depth = state.depth - 1

    return expanded
end

-- Validate every effective group, including mod additions, before any item
-- roll. Missing references and malformed weights are authoring errors.
function name_catalog.validate()
    local groups = catalog.all(categories.RANDART_NAMES)
    local hardcoded = {}

    for _, marker in pairs(markers) do
        hardcoded[marker] = true
    end

    for _, definition in ipairs(groups) do
        if type(definition.entries) ~= "table" or
            #definition.entries == 0 then
            error("random-name group has no phrases " .. definition.id)
        end

        for _, entry in ipairs(definition.entries) do
            if type(entry.weight) ~= "number" or
                entry.weight <= 0 or entry.weight % 1 ~= 0 or
                type(entry.text) ~= "string" or entry.text == "" then
                error("invalid random-name phrase in " .. definition.id)
            end

            for marker in entry.text:gmatch("@([^@]+)@") do
                marker = marker:lower()

                if not source_group(marker) and not hardcoded[marker] then
                    error("missing random-name group " .. marker ..
                        " in " .. definition.id)
                end
            end
        end
    end
end

return name_catalog
