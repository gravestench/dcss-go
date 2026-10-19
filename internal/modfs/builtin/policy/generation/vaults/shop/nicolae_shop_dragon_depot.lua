-- Example: Choose scale stock, then draw a mythic dragon owner for the generated depot name.
local directives = require("constants.vault_directives")
local dragon_names = require("policy.generation.vaults.shop.dragon_names")

local handler = {}

local scales = {
    "steam dragon scales",
    "acid dragon scales",
    "swamp dragon scales",
    "fire dragon scales",
    "ice dragon scales",
    "pearl dragon scales",
    "shadow dragon scales",
    "storm dragon scales",
    "gold dragon scales",
    "quicksilver dragon scales",
}

-- Choose scale stock, then draw a mythic dragon owner for the generated depot name.
local function configure_dragon_depot(api)
    local inventory = {}

    for index, scale in ipairs(scales) do
        if api:coinflip() then
            inventory[index] = scale .. " good_item"
        else
            inventory[index] = scale
        end
    end

    local owner = api:random_from(dragon_names)

    api:emit(directives.KFEAT,
        "P = armour shop name:" .. owner ..
        " type:Dragon-Slaying suffix:Spoils count:10 use_all ; " ..
        table.concat(inventory, " | "))
end

handler.configure_dragon_depot = configure_dragon_depot

return handler
