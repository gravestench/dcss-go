local choice = require("policy.generation.vaults.specs.choice")
local attitude = require("constants.vault_attitude")

local monster = {}

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
            if not value:match("^[A-Za-z]+:%d+$") then
                choice.fail(site, expression, "invalid monster place " .. value)
            end

            result.place = value
        elseif key then
            choice.fail(site, expression, "unknown monster modifier " .. key)
        else
            names[#names + 1] = token
        end
    end

    result.name = table.concat(names, " ")

    if result.name == "" then
        choice.fail(site, expression, "missing monster name")
    end

    result.no_spawn = result.name == "nothing"

    return result
end

function monster.parse(expression, site)
    return choice.slots(expression, site, parse_term)
end

return monster
