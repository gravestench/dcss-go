local streams = require("constants.rng_streams")
local catalog = require("policy.catalog")
local component = require("constants.component")
local ids = require("ids.items")
local gods = require("constants.gods")
local schools = require("constants.spell_schools")
local source = require("policy.item_generation.source_roll")
local kinds = require("constants.artefact_kinds")
local names = require("policy.item_generation.artefacts.names")
local player_books = require("policy.magic.player_book_catalog")
local records = require("policy.character.spell_records")

local random_books = {}

-- Acquirement gifts should not spend a book slot on spells the player
-- already owns. Ordinary floor and vault books still use their full pool.
local function available_for(ctx, request)
    local available = player_books.ordered()

    if not request.exclude_known then
        return available
    end

    local known = {}

    for _, entry in ipairs(records.list(ctx, ctx:player())) do
        if entry.state.in_library or entry.state.known_slot > 0 then
            known[entry.state.spell_id] = true
        end
    end

    local filtered = {}

    for _, spell in ipairs(available) do
        if not known[spell.id] then
            filtered[#filtered + 1] = spell
        end
    end

    return filtered
end

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

-- A themed book accepts either selected discipline without counting a spell twice.
local function has_school(spell, first, second)
    for _, school in ipairs(spell.schools or {}) do
        if school == first or school == second then
            return true
        end
    end

    return false
end

-- The source makes an unused discipline match the one represented by the
-- selected spells, so the saved theme and title describe the actual book.
local function represented_schools(spells, first, second)
    local has_first = false
    local has_second = false

    for _, spell_id in ipairs(spells) do
        local spell = catalog.get("spells", spell_id)

        has_first = has_first or has_school(spell, first, first)
        has_second = has_second or has_school(spell, second, second)
    end

    if has_first ~= has_second then
        if has_first then
            second = first
        else
            first = second
        end
    end

    return first, second
end

-- Fill a themed book without repeats within the authored spell-level budget.
local function themed_spells(ctx, request)
    -- Source: crawl-ref/source/randbook.cc, 216-301.
    -- Acquired themes use 2 + random2avg(7, 3): the later two draws
    -- include seven, matching source's rounded average and 2-8 range.
    local count = request.numspells

    if not count then
        local total = ctx:random(streams.ITEM_GENERATION, 7) +
            ctx:random(streams.ITEM_GENERATION, 8) +
            ctx:random(streams.ITEM_GENERATION, 8)

        count = 2 + math.floor(total / 3)
    end
    local first = request.disc or
        school_order[ctx:random(streams.ITEM_GENERATION, #school_order) + 1]
    local second = request.disc2 or request.disc or
        school_order[ctx:random(streams.ITEM_GENERATION, #school_order) + 1]
    local spells = {}
    local used = {}
    local levels = 0
    local level_budget = request.slevels or 20
    local available = available_for(ctx, request)
    local eligible = {}

    -- A god's unknown-only pool can leave a randomly chosen school empty.
    -- Use the first remaining book spell's school before generating an
    -- empty gift; ordinary floor books keep their source school draw.
    if request.exclude_known and #available > 0 then
        local matching = false

        for _, spell in ipairs(available) do
            if has_school(spell, first, second) then
                matching = true
                break
            end
        end

        if not matching then
            first = available[1].schools[1]
            second = first
        end
    end

    for _, spell in ipairs(available) do
        eligible[spell.id] = spell
    end

    -- DES spells: names mandatory contents. Reserve them before random
    -- theme draws; the authored spell can lie outside the chosen school.
    for _, id in ipairs(request.included_spells or {}) do
        local spell = eligible[id]

        if not spell or used[id] or #spells >= count or
            levels + spell.level > level_budget then
            error("invalid mandatory themed-book spell " .. tostring(id))
        end

        spells[#spells + 1] = id
        used[id] = true
        levels = levels + spell.level
    end

    for _ = #spells + 1, count do
        local candidates = {}

        for _, spell in ipairs(available) do
            if not used[spell.id] and
                has_school(spell, first, second) and
                levels + spell.level <= level_budget then
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

    first, second = represented_schools(spells, first, second)

    return spells, first .. "/" .. second, 0, first, second
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
    -- Sif retains the original level-book size. Other generated level
    -- books use source's later 3/5 reduction with random rounding.
    if request.god_id ~= gods.SIF_MUNA then
        local scaled = count * 3

        count = math.max(1, math.floor(scaled / 5) +
            (source.chance(ctx, scaled % 5, 5) and 1 or 0))
    end

    local candidates = {}

    for _, spell in ipairs(available_for(ctx, request)) do
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
    local first
    local second

    if definition.id == ids.BOOK_RANDART_THEME then
        spells, theme, level, first, second = themed_spells(ctx, request)
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

    local title, appearance, seed = names.generate(ctx, definition, {
        book = {
            spells = spells,
            first = first,
            second = second,
            level = level,
            owner = request.owner,
            subject = request.subject,
            god_id = request.god_id,
        },
    })

    result.components[component.ITEM_ARTEFACT] = {
        kind = kinds.RANDOM,
        unique_id = "",
        seed = seed,
        -- DES title: is an authored randbook name. The generated spells,
        -- appearance, and seed still come from the normal book path.
        name = request.title or title,
        appearance = appearance,
        brand = "",
        properties = {},
        known = {},
        flags = {},
    }
end

return random_books
