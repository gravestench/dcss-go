local streams = require("constants.rng_streams")
local classes = require("ids.object_classes")
local pools = require("constants.appearance_pools")
local item_appearances = require("policy.items.appearances")
local catalog = require("policy.catalog")
local component = require("constants.component")
local items = require("ids.items")
local armour_slots = require("constants.armour_slots")
local markers = require("constants.randart_name_markers")
local groups = require("constants.randart_name_groups")
local name_gods = require("policy.item_generation.artefacts.name_gods")
local name_catalog = require("policy.item_generation.artefacts.name_catalog")
local book_names = require("policy.item_generation.random_book_names")
local names = {}

-- Source naming uses an equipment class for both its true-name database and
-- its unidentified appearance. Jewellery uses a shared true-name group but
-- must keep ring and amulet appearances separate.
local function name_groups(definition)
    if definition.class == classes.OBJ_WEAPONS then
        return groups.WEAPON, groups.WEAPON, definition.name
    end

    if definition.class == classes.OBJ_ARMOUR then
        if definition.id == items.ARM_ROBE then
            return groups.ROBE, groups.ROBE, definition.name
        end

        if definition.armour and
            definition.armour.slot_id == armour_slots.BODY_ARMOUR then
            return groups.BODY_ARMOUR, groups.BODY_ARMOUR,
                definition.name
        end

        return groups.ARMOUR, groups.ARMOUR, definition.name
    end

    if definition.class == classes.OBJ_JEWELLERY then
        if item_appearances.pool(definition) == pools.AMULET then
            return groups.JEWELLERY, groups.AMULET, groups.AMULET
        end

        return groups.JEWELLERY, groups.RING, groups.RING
    end

    if definition.class == classes.OBJ_BOOKS then
        return nil, groups.BOOK, groups.BOOK
    end

    return nil, nil, definition.name
end

-- A cosmetic name may be rolled in an isolated rule test before a player
-- exists. Live sessions read the saved player component when it is present.
local function player_state(ctx)
    if not ctx.player or not ctx.get then
        return nil
    end

    local owner = ctx:player()

    if not owner then
        return nil
    end

    local found, state = pcall(ctx.get, ctx, owner, component.PLAYER)

    return found and state or nil
end

-- Dynamic source tokens are resolved only when a selected phrase uses them;
-- unused player, god, and branch choices consume no cosmetic RNG draws.
local function resolve_marker(facts, marker, random)
    local player = player_state(facts.ctx)
    local player_name = player and player.name ~= "" and
        player.name or "Adventurer"

    if marker == markers.PLAYER_NAME then
        return player_name
    end

    if marker == markers.PLAYER_SPECIES then
        if player and player.species_id then
            return catalog.get("species", player.species_id).name
        end

        return "Human"
    end

    if marker == markers.PLAYER_DEATH then
        return player_name .. name_catalog.draw(random,
            groups.KILLER_NAME, facts)
    end

    if marker == markers.PLAYER_DOOM then
        return player_name .. "'s " .. name_catalog.draw(random,
            groups.DEATH_OR_DOOM, facts)
    end

    if marker == markers.BRANCH_NAME then
        local branches = {}

        for _, branch in ipairs(catalog.all("branches")) do
            if branch.long_name ~= "" then
                branches[#branches + 1] = branch.long_name
            end
        end

        return branches[random(#branches) + 1]
    end

    if marker == markers.GOD_NAME then
        return name_gods.choose(random, facts.definition,
            facts.brand, facts.properties)
    end

    if marker == markers.XOM_NAME then
        return name_gods.xom_name(random)
    end

    error("unsupported random-name marker " .. marker)
end

-- Weapon and armour names use the database half the time; jewellery does
-- so one fifth of the time. The remaining names use source-shaped syllables.
local function source_database_name(random, definition, group, facts)
    local chance = definition.class == classes.OBJ_JEWELLERY and 5 or 2

    if random(chance) ~= 0 then
        return nil
    end

    local phrase

    for _ = 1, 100 do
        phrase = name_catalog.draw(random, group, facts)

        if #phrase <= 25 then
            break
        end
    end

    return definition.name .. " " .. phrase
end

-- Source: crawl-ref/source/item-name.cc.
local vowels = "aeiouaeiouaeiouy  "
local consonants = "bcdfghjklmnpqrstvwxzcdfghlmnrstlmnrst"
local consonant_pairs = {
    "kl", "gr", "cl", "cr", "fr", "pr", "tr", "tw", "br", "pl",
    "bl", "str", "shr", "thr", "sm", "sh", "ch", "th", "ph",
    "pn", "kh", "gh", "mn", "ps", "st", "sk", "sch", "ts",
    "cs", "xt", "nt", "ll", "rr", "ss", "wk", "wn", "ng",
    "cw", "mp", "ck", "nk", "dd", "tt", "bb", "pp", "nn",
    "mm", "kk", "gg", "ff", "pt", "tz", "dgh", "rgh",
    "rph", "rch", "cz", "xk", "zx", "xz", "cv", "vv",
    "nl", "rh", "dw", "nw", "khl",
}

local consonant_lookup = {}

for char in consonants:gmatch(".") do
    consonant_lookup[char] = true
end

-- Example: seeded_random(123) keeps a randart name tied to its saved seed.
-- Return a private LCG so cosmetic syllables reproduce without consuming item-generation draws.
local function seeded_random(seed)
    local state = seed

    -- Advance a private PRNG for each syllable so name spelling cannot perturb item rolls.
    return function(bound)
        -- A local stream keeps cosmetic syllable draws from perturbing
        -- later item-generation decisions.
        state = (state * 1664525 + 1013904223) % 4294967296

        return state % bound
    end
end

-- The seeded generator chooses letters from its current syllable set.
local function choice(random, letters)
    local index = random(#letters) + 1

    return letters:sub(index, index)
end

-- Position-sensitive consonant pairs keep generated names pronounceable.
local function consonant_pair(random, beginning, ending)
    local first = 1
    local last = 67

    if beginning then
        last = 27
    elseif ending then
        first = 15
        last = 56
    end

    return consonant_pairs[first + random(last - first + 1)]
end

-- Vowel choice depends on the growing name to avoid invalid runs.
local function next_vowel(random, name, length)
    local vowel = choice(random, vowels)
    local previous = name:sub(-1)
    local penultimate = name:sub(-2, -2)

    if vowel == " " then
        if length < 7 or #name <= 2 or #name >= length - 3 or
            previous == " " or penultimate == " " or
            (consonant_lookup[previous] and
                consonant_lookup[penultimate]) then
            return nil
        end
    elseif vowel == previous and
        (vowel == "y" or vowel == "i" or random(5) <= 1) then
        return nil
    end

    return vowel
end

-- Consonant choice respects boundary rules while extending the name.
local function next_consonant(random, name, length)
    local beginning = name == "" or name:sub(-1) == " "
    local ending = #name >= length - 2

    if (length > 3 or name ~= "") and
        random(7) <= 1 and
        (not beginning or not ending) then
        return consonant_pair(random, beginning, ending)
    end

    return choice(random, consonants)
end

-- Build a name fragment from the local seeded generator, independent of global RNG.
local function word(random)
    -- Source: crawl-ref/source/item-name.cc. The source uses
    -- a game-seed subgenerator; this port uses an item-local seed.
    local length = 3 + random(5)

    if random(5) == 0 then
        length = length + random(6)
    else
        length = length + 1
    end

    local name = ""
    local has_space = false

    for _ = 1, 150 do
        if #name >= length then
            break
        end

        local previous = name:sub(-1)
        local penultimate = name:sub(-2, -2)
        local added

        if name == "" or previous == " " then
            added = string.char(string.byte("a") + random(26))
        elseif not has_space and #name > 5 and
            #name < length - 4 and random(5) ~= 0 then
            added = " "
        elseif consonant_lookup[previous] or
            (#name > 1 and not consonant_lookup[previous] and
                consonant_lookup[penultimate] and random(5) <= 1) then
            added = next_vowel(random, name, length)
        else
            added = next_consonant(random, name, length)

            if #added > 2 then
                length = length + #added - 2
            end
        end

        if added then
            name = name .. added
            has_space = has_space or added == " "
        end
    end

    local last = name:sub(-1)

    if last ~= "" and last ~= " " and last ~= "y" and
        not consonant_lookup[last] and
        (#name < length or
            (length < 8 and random(3) ~= 0)) then
        name = name .. choice(random, consonants)
    end

    name = name:gsub("%s+$", "")

    if #name < 4 then
        name = "plog"
    end

    return (name:gsub("(%f[%a]%a)", string.upper))
end

-- The saved artefact seed must reproduce the same name after load.
function names.generate(ctx, definition, details)
    details = details or {}
    local seed = ctx:random(streams.ITEM_GENERATION, 2147483647)
    local random = seeded_random(seed)
    local group, appearance_group, shape = name_groups(definition)
    local facts = {
        ctx = ctx,
        definition = definition,
        brand = details.brand,
        properties = details.properties,
        resolve = resolve_marker,
    }
    local full_name

    if details.book then
        full_name = book_names.title(random, word, details.book, facts)
    elseif group then
        full_name = source_database_name(random, definition, group, facts)
    end

    if not full_name then
        local title = word(random)

        if random(3) == 0 then
            full_name = definition.name .. " of " .. title
        else
            full_name = definition.name .. " \"" .. title .. "\""
        end
    end

    local hidden = "non-descript " .. shape

    if appearance_group then
        local adjective = name_catalog.draw(random,
            appearance_group .. " appearance", facts)

        hidden = adjective .. " " .. shape
    end

    return full_name, hidden, seed
end

return names
