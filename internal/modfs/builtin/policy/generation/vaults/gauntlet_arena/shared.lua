-- Theory of operation: each arena is a source MAP with slots for one
-- encounter theme, up to four prizes, a transporter pair, and terrain
-- variations. The parent SUBVAULT call supplies its tier and ordinal.
-- This hook makes all source choices on the staged builder's RNG stream;
-- no module global remembers a previous arena or another generation.
local directives = require("constants.vault_directives")
local encounters = require("content.gauntlet.encounters")
local gauntlet = require("constants.gauntlet")
local loot = require("constants.vault_loot")
local transporter = require("constants.transporter")

local shared = {}

-- The selected source tag, rather than a prior script side effect, owns
-- the arena's difficulty. This remains true for sparse replacement maps.
local function tier_for(api)
    local tag = api:subvault_tag()

    if tag == gauntlet.FIRST_TIER_TAG or
        tag == gauntlet.FIRST_TIER_77_TAG then
        return 1
    end

    if tag == gauntlet.SECOND_TIER_TAG or
        tag == gauntlet.SECOND_TIER_77_TAG then
        return 2
    end

    error("Gauntlet arena needs a first or second tier SUBVAULT tag")
end

-- Source `util.random_weighted_from` defaults every omitted weight to ten.
-- Iterate the authored table, since its order is an explicit roll order.
local function encounter_for(api, tier)
    local options = tier == 1 and encounters.first or encounters.second
    local total = 0

    for _, option in ipairs(options) do
        total = total + (option.weight or 10)
    end

    local draw = api:roll(total)

    for _, option in ipairs(options) do
        local weight = option.weight or 10

        if draw < weight then
            return option
        end

        draw = draw - weight
    end

    error("Gauntlet encounter draw exceeded its source table")
end

-- The parent and arena name the same numbered station. P is where a
-- player lands; Q is the return station reached after the fight.
local function transporters(api)
    local ordinal = api:subvault_ordinal()

    if not ordinal then
        error("Gauntlet arena needs a parent SUBVAULT ordinal")
    end

    api:emit(directives.MARKER,
        'P = ' .. transporter.DESTINATION_CALL ..
        '("gauntlet_arena_entry_' .. ordinal .. '")')
    api:emit(directives.MARKER,
        'Q = ' .. transporter.SOURCE_CALL ..
        '("gauntlet_arena_exit_' .. ordinal .. '")')
end

-- The source turns all unused 1/2/3 positions into floor. An entry's
-- count is an inclusive uniform roll, after its weighted theme draw.
local function monsters(api, entry, glyph)
    if not entry then
        api:emit(directives.SUBST, glyph .. " = .")

        return
    end

    api:emit(directives.KMONS, glyph .. " = " .. entry.mons)

    local count = entry.min + api:roll(entry.max - entry.min + 1)

    if count == 0 then
        api:emit(directives.SUBST, glyph .. " = .")
    else
        api:emit(directives.NSUBST,
            glyph .. " = " .. count .. "=" .. glyph .. " / .")
    end
end

-- Source item slots d/e/f/g must be declared in that order. The
-- `no_pickup` flag keeps monsters from taking prizes; players may take
-- them normally once they physically reach an arena.
local function items(api, tier, custom_loot)
    api:emit(directives.NSUBST, "d = d / X")
    api:emit(directives.KITEM, "* = star_item no_pickup")
    api:emit(directives.KITEM, "| = superb_item no_pickup")
    api:emit(directives.KITEM, "% = any no_pickup")
    api:emit(directives.KITEM, "$ = gold no_pickup")

    if custom_loot then
        api:emit(directives.ITEM, custom_loot .. " no_pickup")
    else
        api:emit(directives.ITEM, "nothing")
    end

    local scrolls = loot.SCROLLS:gsub("scroll of",
        "no_pickup scroll of")
    local potions = loot.POTIONS:gsub("potion of",
        "no_pickup potion of")

    api:emit(directives.ITEM, scrolls .. " / " .. potions)

    if not custom_loot then
        api:emit(directives.SUBST, "d = e*")
    end

    local aux = loot.GOOD_AUX_ARMOUR

    if tier == 2 and api:one_in(3) then
        aux = loot.RANDART_AUX_ARMOUR
    end

    aux = aux:gsub("/", "no_pickup /") .. " no_pickup"
    api:emit(directives.ITEM, aux)

    if tier == 1 then
        api:emit(directives.ITEM,
            "any jewellery good_item no_pickup")
    else
        api:emit(directives.ITEM,
            "any jewellery good_item w:20 no_pickup / " ..
            "any jewellery randart no_pickup")
    end

    local pattern = api:subvault_setting("extra_items")

    if not pattern and tier == 1 then
        pattern = "fg|*|* / ."
    elseif not pattern then
        pattern = "fg / |* / ."
    end

    api:emit(directives.NSUBST, "X = " .. pattern)
end

-- Source wall, liquid, trap, and plant choices follow item and monster
-- rolls. Their order matters to a seeded build and to sparse replacements.
local function terrain(api, tier, entry, rock_unchanged)
    if not rock_unchanged then
        local walls = tier == 1 and "xxc" or "cccvvb"

        api:emit(directives.SUBST, "x : " .. walls)
    end

    if entry.liquid == "lava" then
        api:emit(directives.SUBST, "w = l")
    elseif entry.liquid == "water" then
        api:emit(directives.SUBST, "l = w")
    else
        api:emit(directives.SUBST, "w : wwwl")
    end

    local trap_odds = tier == 1 and "^....." or "^..."

    api:emit(directives.SUBST, "^ : " .. trap_odds)
    api:emit(directives.KFEAT,
        "^ = dispersal trap / net trap")

    if entry.plant == "demonic" then
        api:emit(directives.KMONS, "p = demonic plant")
    elseif entry.plant == "withered" then
        api:emit(directives.KMONS, "p = withered plant")
    else
        api:emit(directives.KMONS, "p = plant w:30 / fungus")
    end
end

-- One arena setup runs for each selected helper, even when the same
-- source template is picked on a different level or in another mod.
local function setup(api, rock_unchanged)
    local tier = tier_for(api)

    transporters(api)

    local entry = encounter_for(api, tier)

    items(api, tier, entry.loot)
    monsters(api, entry.first, "1")
    monsters(api, entry.second, "2")
    monsters(api, entry.third, "3")
    terrain(api, tier, entry, rock_unchanged)
end

-- Ordinary arena walls can be randomized by tier as in the source.
function shared.setup(api)
    setup(api, false)
end

-- The source museum keeps its authored rock walls unchanged.
function shared.setup_unchanged(api)
    setup(api, true)
end

return shared
