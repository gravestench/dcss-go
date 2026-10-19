local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local gods = require("constants.gods")
local god_names = require("constants.randart_name_gods")
local groups = require("constants.randart_name_groups")
local markers = require("constants.randart_name_markers")
local school_names = require("constants.spell_school_names")
local schools = require("constants.spell_schools")
local name_catalog = require("policy.item_generation.artefacts.name_catalog")

local book_names = {}

-- DCSS gives the spell list to the book generator, then chooses a title
-- from that list's level or disciplines. All random choices here use the
-- one private cosmetic generator owned by artefact naming. A mod changes
-- phrases by replacing individual content/randart_names files.
local level_words = {
    "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
}

local display_gods = {}

for _, entry in ipairs(god_names) do
    display_gods[entry.id] = entry.name
end

-- A single-level book can mention its spell level inside a weighted phrase.
local function title_facts(facts, level)
    local titled = {}

    for key, value in pairs(facts) do
        titled[key] = value
    end

    titled[markers.LEVEL] = level_words[level]

    return titled
end

-- A group absent from a source fallback lookup means "try the next key".
-- Missing references inside an existing group still fail at boot.
local function maybe_draw(random, key, facts)
    local present = pcall(catalog.get, categories.RANDART_NAMES,
        key:lower())

    if not present then
        return ""
    end

    return name_catalog.draw(random, key, facts)
end

-- Source author rows may explicitly say that no owner is suitable.
local function valid_owner(owner)
    return owner ~= "" and owner ~= "__NONE"
end

-- A possessive author prefix helps a title read like a named physical book.
local function owner_prefix(owner)
    if owner == "" then
        return ""
    end

    return owner .. "'s "
end

-- Remove an article after adding an author: "Nyx's The Manual" is not a
-- source-style title, while "Nyx's Manual" is.
local function without_article(title)
    for _, article in ipairs({ "The ", "An ", "A " }) do
        if title:sub(1, #article) == article then
            return title:sub(#article + 1)
        end
    end

    return title
end

-- Capitalize a source phrase that started lowercase in randbook.txt.
local function uppercase_first(phrase)
    return phrase:sub(1, 1):upper() .. phrase:sub(2)
end

-- Four difficulty families describe the level of every spell in a level
-- book. At level four, the source deliberately flips between two families.
function book_names.level_group(level, random)
    if level == 1 then
        return groups.STARTING_LEVEL_BOOK
    end

    if level <= 3 or (level == 4 and random(2) == 0) then
        return groups.EASY_LEVEL_BOOK
    end

    if level <= 6 then
        return groups.MODERATE_LEVEL_BOOK
    end

    return groups.DIFFICULT_LEVEL_BOOK
end

-- God gifts name their giver. Other level books occasionally name Sif Muna
-- or a generated author and usually stay anonymous.
local function level_owner(random, make_word, god_id)
    if god_id and god_id ~= gods.NO_GOD then
        return display_gods[god_id] or error("unknown book god " .. god_id)
    end

    if random(30) == 0 then
        return display_gods[gods.SIF_MUNA]
    end

    if random(3) == 0 then
        return make_word(random)
    end

    return ""
end

-- First try an author-specific title group, then the general difficulty
-- group. Both groups may embed a source @level@ marker.
local function level_title(random, make_word, details, facts)
    local owner = details.owner

    if owner == nil or owner == "" then
        owner = level_owner(random, make_word, details.god_id)
    end

    -- Xom sometimes discards the difficulty title for an absurd subject.
    -- The source applies this only to Xom-gifted level books.
    if details.god_id == gods.XOM and random(2) == 0 then
        return owner_prefix(owner) ..
            name_catalog.draw(random, groups.BOOK_NOUN, facts) ..
            " of " ..
            name_catalog.draw(random, groups.XOM_BOOK_TITLE, facts)
    end

    local key = book_names.level_group(details.level, random)
    local titled = title_facts(facts, details.level)
    local phrase = ""

    if owner ~= "" then
        phrase = maybe_draw(random, key .. " owner", titled)
    end

    if phrase == "" then
        phrase = maybe_draw(random, key, titled)
    end

    if phrase == "" then
        phrase = name_catalog.draw(random, groups.BOOK, titled)
    end

    phrase = uppercase_first(phrase)

    if owner ~= "" then
        phrase = without_article(phrase)
    end

    return owner_prefix(owner) .. phrase
end

-- A themed author's high-level eligibility depends on the actual spells,
-- not just on the originally requested disciplines.
local function theme_facts(random, details)
    local highest = 0
    local lowest = 27
    local all_first = true

    for _, spell_id in ipairs(details.spells) do
        local spell = catalog.get(categories.SPELLS, spell_id)

        highest = math.max(highest, spell.level)
        lowest = math.min(lowest, spell.level)

        local matches = false

        for _, school in ipairs(spell.schools) do
            matches = matches or school == details.first
        end

        all_first = all_first and matches
    end

    local highlevel = highest >= 7 + random(3) and
        (lowest > 1 or random(2) == 0)

    return highlevel, all_first
end

-- Try the source's pair and primary-school author groups in priority
-- order. The C++ single-school fallback omits a space before "owner";
-- the committed database actually defines the spaced group.
local function theme_owner_from_groups(random, details, facts,
                                        highlevel, all_first)
    local first = school_names[details.first]
    local second = school_names[details.second]
    local lookups = {}

    if first ~= second then
        local pair = first .. " " .. second

        if highlevel then
            lookups[#lookups + 1] = "highlevel " .. pair .. " owner"
        end

        lookups[#lookups + 1] = pair .. " owner"
    end

    if all_first then
        if highlevel then
            lookups[#lookups + 1] = "highlevel " .. first .. " owner"
        end

        lookups[#lookups + 1] = first .. " owner"
    end

    for _, key in ipairs(lookups) do
        local owner = maybe_draw(random, key, facts)

        if valid_owner(owner) then
            return owner
        end
    end

    return ""
end

-- The source favours a gifting god, then a school-linked author, then a
-- random author, and only rarely an appropriate god for an ordinary book.
local function themed_owner(random, make_word, details, facts)
    local god_id = details.god_id
    local gift = god_id and god_id ~= gods.NO_GOD
    local highlevel, all_first = theme_facts(random, details)

    if gift and random(4) ~= 0 then
        return display_gods[god_id] or error("unknown book god " .. god_id)
    end

    if (gift and random(3) == 0) or random(5) == 0 then
        local owner = theme_owner_from_groups(random, details, facts,
            highlevel, all_first)

        if owner ~= "" then
            return owner
        end
    end

    if gift or random(5) == 0 then
        return make_word(random)
    end

    if random(9) == 0 then
        if details.first == schools.NECROMANCY and all_first and
            random(6) ~= 0 then
            return display_gods[gods.KIKUBAAQUDGHA]
        end

        if details.first == schools.CONJURATION and all_first and
            random(4) ~= 0 then
            return display_gods[gods.VEHUMET]
        end

        return display_gods[gods.SIF_MUNA]
    end

    return ""
end

-- Xom almost always supplies an absurd subject. Other books only rarely
-- replace their discipline theme with a wholly random subject.
local function themed_subject(random, owner, facts)
    if owner == display_gods[gods.XOM] and random(20) ~= 0 then
        return name_catalog.draw(random, groups.XOM_BOOK_TITLE, facts)
    end

    if random(20) == 0 and (owner == "" or random(3) == 0) then
        return name_catalog.draw(random, groups.RANDOM_BOOK_TITLE, facts)
    end

    return ""
end

-- Combine school nouns, or use a secondary-school adjective when one is
-- available. The adjective form carries a leading "the" with the noun.
local function school_title(random, details, facts)
    local first = school_names[details.first]
    local second = school_names[details.second]
    local adjective = ""

    if first ~= second and random(3) ~= 0 then
        adjective = maybe_draw(random, second .. " adj", facts)
    end

    local first_noun = maybe_draw(random, first, facts)

    if first_noun == "" then
        first_noun = first
    end

    if adjective == "" then
        if first == second then
            return first_noun
        end

        local second_noun = maybe_draw(random, second, facts)

        if second_noun == "" then
            second_noun = second
        end

        return first_noun .. " and " .. second_noun
    end

    if first_noun:find("the ", 1, true) then
        first_noun = first_noun:gsub("the ", "")
        return "the " .. adjective .. " " .. first_noun
    end

    return adjective .. " " .. first_noun
end

-- An explicit subject wins; otherwise authors and subjects come from the
-- source odds before the book noun and discipline title are assembled.
local function themed_title(random, make_word, details, facts)
    local owner = details.owner

    if owner == nil or owner == "" then
        owner = themed_owner(random, make_word, details, facts)
    end

    local subject = details.subject

    if subject == nil or subject == "" then
        subject = themed_subject(random, owner, facts)
    end

    if subject ~= "" then
        return owner_prefix(owner) ..
            name_catalog.draw(random, groups.BOOK_NOUN, facts) ..
            " of " .. subject
    end

    return owner_prefix(owner) ..
        name_catalog.draw(random, groups.BOOK_NAME, facts) ..
        " " .. school_title(random, details, facts)
end

-- Route books by the spell-list shape, keeping every title draw inside the
-- cosmetic seed rather than changing later gameplay random choices.
function book_names.title(random, make_word, details, facts)
    local title

    if details.level and details.level > 0 then
        title = level_title(random, make_word, details, facts)
    else
        title = themed_title(random, make_word, details, facts)
    end

    -- Authored subjects may contain source placeholders; catalog phrases
    -- have already expanded, so this pass usually leaves them unchanged.
    return name_catalog.expand(random, title, facts)
end

return book_names
