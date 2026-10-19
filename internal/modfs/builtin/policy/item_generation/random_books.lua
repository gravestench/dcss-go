local streams = require("constants.rng_streams")
local catalog = require("policy.catalog")
local component = require("constants.component")
local ids = require("ids.items")
local schools = require("constants.spell_schools")
local source = require("policy.item_generation.source_roll")
local kinds = require("constants.artefact_kinds")
local names = require("policy.item_generation.artefacts.names")

local random_books = {}

-- Source: crawl-ref/source/spl-util.h. The source iterates this
-- bitfield order when selecting a random discipline.
local school_order = {
    schools.CONJURATION,
    schools.HEXES,
    schools.FIRE,
    schools.ICE,
    schools.TRANSMUTATION,
    schools.NECROMANCY,
    schools.SUMMONING,
    schools.TRANSLOCATION,
    schools.POISON,
    schools.EARTH,
    schools.AIR,
}

-- Rebuild the defined player-book pool after overlays, then sort by numeric spell ID for seeded draws.
local function available_spells()
    local selected = {}

    -- A source player-book spell appears in at least one fixed template.
    -- Derive this set from the effective layered catalog on every roll.
    for _, definition in ipairs(catalog.all("items")) do
        for _, spell_id in ipairs(definition.generation.spells or {}) do
            selected[spell_id] = catalog.get("spells", spell_id)
        end
    end

    local ordered = {}

    for _, spell in pairs(selected) do
        if spell.status == "defined" then
            ordered[#ordered + 1] = spell
        end
    end

    -- Numeric spell ID order keeps equivalent effective catalogs on the same seeded candidate sequence.
    table.sort(ordered, function(left, right)
        return left.numeric_id < right.numeric_id
    end)

    return ordered
end

-- A themed book accepts either selected discipline without counting a spell twice.
local function has_school(spell, first, second)
    for _, school in ipairs(spell.schools or {}) do
        if school == first or school == second then
            return true
        end
    end

    return false
end

-- Fill a themed book without repeats while capping the sum of spell levels at twenty.
local function themed_spells(ctx, request)
    -- Source: crawl-ref/source/randbook.cc, 216-301.
    local count = request.numspells or source.average(ctx, 4, 3) + 2
    local first = request.disc or
        school_order[ctx:random(streams.ITEM_GENERATION, #school_order) + 1]
    local second = request.disc or
        school_order[ctx:random(streams.ITEM_GENERATION, #school_order) + 1]
    local spells = {}
    local used = {}
    local levels = 0
    local available = available_spells()

    for _ = 1, count do
        local candidates = {}

        for _, spell in ipairs(available) do
            if not used[spell.id] and
                has_school(spell, first, second) and
                levels + spell.level <= 20 then
                candidates[#candidates + 1] = spell
            end
        end

        if #candidates == 0 then
            break
        end

        local chosen = candidates[ctx:random(streams.ITEM_GENERATION, #candidates) + 1]

        spells[#spells + 1] = chosen.id
        levels = levels + chosen.level
        used[chosen.id] = true
    end

    if #spells == 0 then
        error("themed book has no eligible player spells")
    end

    return spells, first .. "/" .. second, 0
end

-- Choose one depth-scaled spell level, then remove each selected spell from its candidate pool.
local function level_spells(ctx, request)
    -- Source: crawl-ref/source/makeitem.cc and
    -- randbook.cc. Ordinary generated books use all player-book
    -- spells at the chosen level, without acquirement's known-spell filter.
    local maximum = math.min(9, math.max(1, math.floor(request.depth / 3)))
    local level = request.acquirement_level or source.between(ctx, 1,
        maximum)
    local count = math.max(1, math.min(5 + math.floor((level - 1) / 3),
        18 - 2 * level))
    local scaled = count * 3

    count = math.max(1, math.floor(scaled / 5) +
        (source.chance(ctx, scaled % 5, 5) and 1 or 0))

    local candidates = {}

    for _, spell in ipairs(available_spells()) do
        if spell.level == level then
            candidates[#candidates + 1] = spell.id
        end
    end

    if #candidates == 0 then
        error("level book has no player spells at level " .. level)
    end

    local spells = {}

    for _ = 1, math.min(count, #candidates) do
        local index = ctx:random(streams.ITEM_GENERATION, #candidates) + 1

        spells[#spells + 1] = table.remove(candidates, index)
    end

    return spells, "", level
end

-- Example: random_books.roll(ctx, book_kind, request, result) stores a generated spell list.
-- Route themed and level books to separate selectors, then persist spells and a seeded artefact name together.
function random_books.roll(ctx, definition, request, result)
    local spells
    local theme
    local level

    if definition.id == ids.BOOK_RANDART_THEME then
        spells, theme, level = themed_spells(ctx, request)
    elseif definition.id == ids.BOOK_RANDART_LEVEL then
        spells, theme, level = level_spells(ctx, request)
    else
        return
    end

    result.components[component.ITEM_RANDOM_BOOK] = {
        spells = spells,
        theme = theme,
        level = level,
    }

    local title, appearance, seed = names.generate(ctx, {
        name = "book",
    })

    result.components[component.ITEM_ARTEFACT] = {
        kind = kinds.RANDOM,
        unique_id = "",
        seed = seed,
        name = title,
        appearance = appearance,
        brand = "",
        properties = {},
        known = {},
        flags = {},
    }
end

return random_books
