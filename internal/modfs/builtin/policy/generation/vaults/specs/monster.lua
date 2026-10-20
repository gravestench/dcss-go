-- Example: A monster token's weapon annotation becomes a loadout slot before spawning.
local choice = require("policy.generation.vaults.specs.choice")
local attitude = require("constants.attitude")

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
    local actor, equipment = text:match("^(.-)%s*;%s*(.+)$")

    if not actor then
        actor = text
    end

    local result = {
        weight = 10,
        source = text,
        equipment = equipment_slots(equipment, expression, site),
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
        elseif key == "spells" then
            result.spells = {}

            for spell in (value .. "|"):gmatch("(.-)|") do
                result.spells[#result.spells + 1] = spell
            end
        elseif key == "place" then
            local fixed_depth = value:match("^[A-Za-z]+:%d+$")
            local branch_bottom = value:match("^[A-Za-z]+:%$$")

            if not fixed_depth and not branch_bottom then
                choice.fail(site, expression, "invalid monster place " .. value)
            end

            result.place = value
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
