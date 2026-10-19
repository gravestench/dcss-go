-- Example: Shuffle four elements once, then stock two evocables, one staff, and one book from distinct slots.
local directives = require("constants.vault_directives")

local handler = {}

local evocables = {
    "wand of flame",
    "wand of iceblast",
    "lightning rod",
    "tin of tremorstones",
}

local staffs = {
    "staff of fire",
    "staff of cold",
    "staff of air",
    "staff of earth",
}

local randbooks = {
    "randbook disc:fire",
    "randbook disc:ice",
    "randbook disc:air",
    "randbook disc:earth",
}

-- Shuffle four elements once, then stock two evocables, one staff, and one book from distinct slots.
local function configure_elemental_stock(api)
    local choices = { 1, 2, 3, 4 }

    for index = 4, 2, -1 do
        local other = api:random_range(1, index)

        choices[index], choices[other] = choices[other], choices[index]
    end

    local inventory = {
        evocables[choices[1]],
        evocables[choices[2]],
        staffs[choices[3]],
        randbooks[choices[4]],
    }

    api:emit(directives.KFEAT,
        "s = general shop type:Elemental suffix:Accessories " ..
        "count:4 use_all ; " .. table.concat(inventory, " | "))
end

handler.configure_elemental_stock = configure_elemental_stock

return handler
