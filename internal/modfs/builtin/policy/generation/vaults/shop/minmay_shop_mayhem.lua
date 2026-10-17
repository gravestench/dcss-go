local directives = require("constants.vault_directives")

local handler = {}

local stock = table.concat({
    "hand axe w:5",
    "war axe",
    "broad axe w:5",
    "battleaxe",
    "executioner's axe w:2",
    "book of fire w:5",
    "the unrestrained analects w:5",
    "wand of iceblast",
}, " | ")

-- Port of builder/shops.des:950-973.
local function configure_mayhem_stock(api)
    local choices = stock

    if not api:unique_generated("devastator") then
        choices = choices .. " | devastator w:1"
    end

    if not api:unique_generated("firestarter") then
        choices = choices .. " | firestarter w:1"
    end

    api:emit(directives.KFEAT,
        "S = general shop type:Mayhem suffix:Merchandise ; " .. choices)
end

handler.configure_mayhem_stock = configure_mayhem_stock

return handler
