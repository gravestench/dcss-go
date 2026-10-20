-- Example: A monster token's weapon annotation becomes a loadout slot before spawning.
local choice = require("policy.generation.vaults.specs.choice")
local attitude = require("constants.attitude")
local gods = require("constants.gods")
local enchantments = require("constants.vault_monster_enchantments")
local source_spellbook = require("policy.monsters.source_spellbook")

local monster = {}

-- Monster equipment annotations are parsed as slots before catalog lookup or spawning.
local function equipment_slots(text, expression, site)
    if text == nil then
        return nil
    end

    local slots = {}

    for slot_text in (text .. "."):gmatch("(.-)%.") do
        local options = {}

        for item_text in (slot_text .. "|"):gmatch("(.-)|") do
            local name = item_text:match("^%s*(.-)%s*$")

            if name == "" then
                choice.fail(site, expression, "empty equipment option")
            end

            options[#options + 1] = name
        end

        slots[#slots + 1] = options
    end

    return slots
end

-- Separate monster identity from place, depth, and equipment annotations before lookup.
local function parse_term(text, expression, site)
    local books = {}

    -- DES extracts spells: tags before splitting the equipment semicolon.
    -- A semicolon inside a spells: value separates slots in one book.
    local without_spells = text:gsub("spells:(%S+)", function(value)
        local okay, reason = pcall(source_spellbook.parse, value)

        if not okay then
            choice.fail(site, expression, tostring(reason))
        end

        books[#books + 1] = value

        return ""
    end)
    local actor, equipment = without_spells:match("^(.-)%s*;%s*(.+)$")

    if not actor then
        actor = without_spells
    end

    local result = {
        weight = 10,
        source = text,
        equipment = equipment_slots(equipment, expression, site),
        spells = #books > 0 and books or nil,
    }

    local names = {}

    for token in actor:gmatch("%S+") do
        local key, value = token:match("^([%w_]+):(.*)$")

        if key == "w" or key == "weight" then
            local weight = tonumber(value)

            if not weight or weight % 1 ~= 0 or weight <= 0 then
                choice.fail(site, expression, "invalid monster weight " .. token)
            end

            result.weight = weight
        elseif key == "col" then
            if value == "" then
                choice.fail(site, expression, "empty monster colour")
            end

            result.colour = value
        elseif key == "att" then
            if value ~= attitude.HOSTILE and value ~= attitude.FRIENDLY and
                value ~= attitude.NEUTRAL and value ~= attitude.GOOD_NEUTRAL and
                value ~= attitude.FELLOW_SLIME then
                choice.fail(site, expression, "invalid monster attitude " .. value)
            end

            result.attitude = value
        elseif key == "god" then
            local god_id = gods[value:upper()]

            if not god_id then
                choice.fail(site, expression, "unknown monster god " .. value)
            end

            result.god_id = god_id
        elseif key == "dbname" or key == "name" or key == "tile" then
            if value == "" then
                choice.fail(site, expression, "empty monster " .. key)
            end

            if key == "dbname" then
                result.database_name = value:gsub("_", " ")
            elseif key == "name" then
                result.custom_name = value:gsub("_", " ")
            else
                result.tile = value
            end
        elseif key == "hp" or key == "hd" then
            local number = tonumber(value)

            if not number or number % 1 ~= 0 or number < 1 or
                (key == "hd" and number > 100) then
                choice.fail(site, expression, "invalid monster " .. key .. " " .. value)
            end

            result[key] = number
        elseif key == "perm_ench" then
            if not enchantments.VALID[value] then
                choice.fail(site, expression,
                    "unknown permanent monster enchantment " .. value)
            end

            result.permanent_enchantments = result.permanent_enchantments or {}
            result.permanent_enchantments[#result.permanent_enchantments + 1] = value
        elseif key == "place" then
            local fixed_depth = value:match("^[A-Za-z]+:%d+$")
            local branch_bottom = value:match("^[A-Za-z]+:%$$")

            if not fixed_depth and not branch_bottom then
                choice.fail(site, expression, "invalid monster place " .. value)
            end

            result.place = value
        elseif token == "patrolling" then
            -- A patrol is a property of the chosen actor, not a species
            -- named "patrolling quokka". Keep the source flag on the record.
            result.patrolling = true
        elseif token == "name_adjective" then
            result.name_adjective = true
        elseif token == "generate_awake" then
            -- The source modifier is separate from the monster's display
            -- name. The current population starts actors awake by default,
            -- but its typed intent stays on the vault record for saves.
            result.generate_awake = true
        elseif key then
            choice.fail(site, expression, "unknown monster modifier " .. key)
        else
            names[#names + 1] = token
        end
    end

    result.name = table.concat(names, " ")

    if result.name == "" and result.place then
        -- A standalone DES place: term requests a random monster from that
        -- branch and depth. It occupies one MONS array slot.
        result.name = "0"
    elseif result.name == "" then
        choice.fail(site, expression, "missing monster name")
    end

    result.no_spawn = result.name == "nothing"

    return result
end

-- Each DES alternative occupies one slot that placement may choose later.
function monster.parse(expression, site)
    return choice.slots(expression, site, parse_term)
end

return monster
