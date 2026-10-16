local categories = require("constants.catalog")

local selection = {}

local function eligible(definition)
    return definition.tags and definition.tags.arrival and definition.weight > 0
end

function selection.choose(random, definitions)
    local total = 0

    for _, definition in ipairs(definitions) do
        if eligible(definition) then
            total = total + definition.weight
        end
    end

    if total == 0 then
        error("arrival vault catalog has no weighted candidates")
    end

    local draw = random:roll(total)

    for _, definition in ipairs(definitions) do
        if eligible(definition) then
            if draw < definition.weight then
                return definition
            end

            draw = draw - definition.weight
        end
    end

    error("arrival vault weight selection exceeded the catalog")
end

function selection.eligible_ids()
    local result = {}

    for _, id in ipairs(register.ordered_ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if eligible(definition) then
            result[#result + 1] = id
        end
    end

    return result
end

function selection.choose_catalog(random)
    local definitions = {}

    for _, id in ipairs(selection.eligible_ids()) do
        definitions[#definitions + 1] = register.get(categories.VAULTS, id)
    end

    return selection.choose(random, definitions)
end

return selection
