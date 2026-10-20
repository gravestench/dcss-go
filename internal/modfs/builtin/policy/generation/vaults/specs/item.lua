-- Example: An item term with no explicit weight receives the default weight.
local choice = require("policy.generation.vaults.specs.choice")

local item = {}

-- Keep a default weight while parsing optional item quantity and special flags.
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
        elseif key == "ego" or key == "disc" then
            if value == "" then
                choice.fail(site, expression, "empty item " .. key)
            end

            result[key] = value
        elseif key == "tile" or key == "wtile" or
            key == "itemname" then
            if value == "" then
                choice.fail(site, expression, "empty item " .. key)
            end

            result[key] = value
        elseif key == "ident" then
            if value ~= "type" and value ~= "all" then
                choice.fail(site, expression, "invalid item identification " .. value)
            end

            result.ident = value
        elseif key == "plus" or key == "charges" or
            key == "numspells" then
            local number = tonumber(value)

            if not number or number % 1 ~= 0 then
                choice.fail(site, expression, "invalid item " .. key .. " " .. token)
            end

            result[key] = number
        elseif token == "mundane" then
            result.mundane = true
        elseif token == "damaged" then
            result.damaged = true
        elseif (token == "good_item" or token == "good") and
            text ~= token then
            result.good_item = true
        elseif token == "randart" then
            result.randart = true
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

-- Split the outer item alternatives before parsing item names that themselves contain commas.
function item.parse(expression, site)
    return choice.slots(expression, site, parse_term)
end

-- Shop stock already has an outer "|" separator. A single stock item may
-- contain commas in its catalog name, such as Great Wizards, Vol. II.
function item.term(expression, site)
    return parse_term(expression, expression, site)
end

return item
