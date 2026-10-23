-- Source dgn.random_item_def sorts the item names, then builds one
-- weighted alternative for each name. Keeping this pure helper local to
-- Ice Cave preserves source request order without a mutable DES global.
local weighted = {}

-- The separator is '/' for a floor item or '|' for one monster's gear.
-- The source appends arguments before ego and weight in every alternative.
function weighted.describe(items, ego, arguments, separator)
    local names = {}

    for name in pairs(items) do
        names[#names + 1] = name
    end

    table.sort(names)

    local alternatives = {}

    for _, name in ipairs(names) do
        local entry = name

        if arguments and arguments ~= "" then
            entry = entry .. " " .. arguments
        end

        if ego then
            entry = entry .. " ego:" .. ego
        end

        alternatives[#alternatives + 1] = entry .. " w:" .. items[name]
    end

    return table.concat(alternatives, " " .. (separator or "/") .. " ")
end

return weighted
