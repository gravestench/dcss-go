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
local name_modes = require("constants.name_modes")
local source_names = require("policy.names.source")
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

-- Catalog phrase choices keep their saved cosmetic seed, while a direct
-- make_name fallback delegates spelling to policy.names.source.
local function seeded_random(seed)
    local state = seed

    -- This existing item-local choice stream keeps name database lookups
    -- reproducible from the saved item seed.
    return function(bound)
        state = (state * 1664525 + 1013904223) % 4294967296

        return state % bound
    end
end
-- The saved artefact seed must reproduce the same name after load.
function names.generate(ctx, definition, details)
    details = details or {}
    local seed = ctx:random(streams.ITEM_GENERATION, 2147483647)
    local random = seeded_random(seed)

    -- Source make_name draws one seed from gameplay RNG before spelling
    -- privately. Phrase choices still use the item-local cosmetic stream;
    -- each fallback word spends its own saved item-generation draw.
    local function make_word()
        local word_seed = ctx:random(streams.ITEM_GENERATION, 4294967296)

        return source_names.from_seed(ctx, word_seed,
            name_modes.ORDINARY)
    end

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
        full_name = book_names.title(random, make_word, details.book, facts)
    elseif group then
        full_name = source_database_name(random, definition, group, facts)
    end

    if not full_name then
        local title = make_word()

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
