-- Source: ng-wanderer.cc. Magic gifts draw from the committed spell catalog.
local spells = {}
local player_books = require("data.player_book_spells")
local traits = require("policy.character.traits")

local schools = {
    SK_CONJURATIONS = "conjuration",
    SK_HEXES = "hexes",
    SK_SUMMONINGS = "summoning",
    SK_NECROMANCY = "necromancy",
    SK_TRANSLOCATIONS = "translocation",
    SK_TRANSMUTATIONS = "transmutation",
    SK_FIRE_MAGIC = "fire",
    SK_ICE_MAGIC = "ice",
    SK_AIR_MAGIC = "air",
    SK_EARTH_MAGIC = "earth",
    SK_POISON_MAGIC = "poison",
}

function spells.is_magic_skill(id)
    return id == "SK_SPELLCASTING" or schools[id] ~= nil
end

local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

local function eligible(species, spell, school, minimum, maximum, seen)
    if spell.status ~= "defined" or not player_books[spell.id] or
        not traits.start_spell_usable(species, spell.id) or seen[spell.id] or
        spell.level < minimum or spell.level > maximum then
        return false
    end

    if contains(spell.flags, "monster") or contains(spell.flags, "testing") then
        return false
    end

    return not school or contains(spell.schools, school)
end

local function pick(ctx, species, school, minimum, maximum, seen)
    local chosen
    local count = 0

    for _, spell in ipairs(require("policy.catalog").all("spells")) do
        if eligible(species, spell, school, minimum, maximum, seen) then
            count = count + 1

            if ctx:random("character", count) == 0 then
                chosen = spell.id
            end
        end
    end

    if chosen then
        seen[chosen] = true
    end

    return chosen
end

function spells.gift(ctx, species, skill, good)
    local school = schools[skill]
    local chosen = {}
    local seen = {}

    if good then
        local count = skill == "SK_SPELLCASTING" and 4 or 3
        local maximum = skill == "SK_SPELLCASTING" and 3 or 4

        for index = 1, count do
            local limit = index == 1 and 1 or maximum
            local id = pick(ctx, species, school, 1, limit, seen)

            if id then
                chosen[#chosen + 1] = id
            end
        end
    else
        -- The source makes a themed two-spell book totaling four levels.
        local first = pick(ctx, species, school, 1, 1, seen)
        local second = first and pick(ctx, species, school, 3, 3, seen)

        if first and second then
            chosen = { first, second }
        else
            seen = {}
            first = pick(ctx, species, school, 2, 2, seen)
            second = first and pick(ctx, species, school, 2, 2, seen)

            if first and second then
                chosen = { first, second }
            end
        end
    end

    return chosen
end

return spells
