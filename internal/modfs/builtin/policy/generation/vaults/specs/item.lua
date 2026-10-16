local choice = require("policy.generation.vaults.specs.choice")

local item = {}

local function parse_term(text, expression, site)
    local result = {
        weight = 10,
        source = text,
    }
    local names = {}

    for token in text:gmatch("%S+") do
        local key, value = token:match("^([%w_]+):(.*)$")

        if key == "w" or key == "weight" then
            local weight = tonumber(value)

            if not weight or weight % 1 ~= 0 or weight <= 0 then
                choice.fail(site, expression, "invalid item weight " .. token)
            end

            result.weight = weight
        elseif key == "q" then
            local quantity = tonumber(value)

            if not quantity or quantity % 1 ~= 0 or quantity <= 0 then
                choice.fail(site, expression, "invalid item quantity " .. token)
            end

            result.quantity = quantity
        elseif key == "place" then
            if not value:match("^[A-Za-z]+:%d+$") then
                choice.fail(site, expression, "invalid item place " .. value)
            end

            result.place = value
        elseif key then
            choice.fail(site, expression, "unknown item modifier " .. key)
        else
            names[#names + 1] = token
        end
    end

    result.name = table.concat(names, " ")

    if result.name == "" then
        choice.fail(site, expression, "missing item name")
    end

    result.no_spawn = result.name == "nothing"

    return result
end

function item.parse(expression, site)
    return choice.slots(expression, site, parse_term)
end

return item
