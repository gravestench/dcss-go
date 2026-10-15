-- Source: ng-setup.cc:_setup_innate_spells. Future Djinni spells are chosen
-- when the character starts and saved, so leveling never rerolls them.
local traits = require("policy.character.traits")
local player_books = require("data.player_book_spells")

local innate = {}

local minimum = { 1, 2, 2, 3, 4, 5, 6, 6, 6, 7, 7, 8, 9 }
local maximum = { 1, 2, 3, 4, 5, 5, 6, 7, 7, 8, 8, 9, 9 }

local function forbidden_flags(spell)
    for _, flag in ipairs(spell.flags or {}) do
        if flag == "monster" or flag == "testing" then
            return true
        end
    end

    return false
end

function innate.generate(ctx, species, known)
    local seen = {}

    for _, id in ipairs(known) do
        seen[id] = true
    end

    local future = {}
    local catalog = require("data.spells").spells

    for index = 1, #minimum do
        local chosen
        local candidates = 0

        for _, spell in ipairs(catalog) do
            if player_books[spell.id] and spell.status == "defined" and
                not seen[spell.id] and not forbidden_flags(spell) and
                traits.start_spell_usable(species, spell.id) and
                spell.level >= minimum[index] and
                spell.level <= maximum[index] then
                candidates = candidates + 1

                if ctx:random("character", candidates) == 0 then
                    chosen = spell.id
                end
            end
        end

        if not chosen then
            error("no innate spell candidate at index " .. index)
        end

        seen[chosen] = true
        future[#future + 1] = chosen
    end

    return future
end

return innate
