-- Theory of operation: every Volcano map requests the same four source
-- reward pools. The glyph positions stay in each DES; this module only
-- defines the alternatives from which normal vault population chooses.
local directives = require("constants.vault_directives")
local pools = require("constants.vault_loot")

local loot = {}

local armour = {
    "leather armour w:65 ego:fire_resistance ident:type good_item",
    "ring mail w:25 ego:fire_resistance ident:type good_item",
    "scale mail w:25 ego:fire_resistance ident:type good_item",
    "chain mail w:40 ego:fire_resistance ident:type good_item",
    "plate armour w:25 ego:fire_resistance ident:type good_item",
    "cloak w:11 ego:fire_resistance ident:type good_item",
    "tower shield w:1 ego:fire_resistance ident:type good_item",
    "kite shield w:2 ego:fire_resistance ident:type good_item",
    "buckler w:1 ego:fire_resistance ident:type good_item",
    "pair of gloves good_item w:6",
    "helmet good_item w:4",
    "hat good_item w:2",
    "pair of boots good_item w:6",
    "fire dragon scales w:8",
}

local weapons = {
    "rapier w:10",
    "quick blade w:5",
    "eveningstar w:2",
    "demon whip w:2",
    "great mace w:16",
    "demon blade w:2",
    "great sword w:16",
    "triple sword w:2",
    "broad axe w:3",
    "battleaxe w:16",
    "executioner's axe w:1",
    "demon trident w:2",
    "glaive w:16",
    "bardiche w:2",
    "longbow w:8",
    "arbalest w:8",
    "hand crossbow w:8",
    "quarterstaff",
    "lajatang w:5",
}

-- Add the source's forced flaming brand to each weapon alternative
-- before vault population chooses one. The brand is visible on pickup.
local function flaming_weapons()
    local alternatives = {}

    for _, weapon in ipairs(weapons) do
        alternatives[#alternatives + 1] = weapon ..
            " ego:flaming ident:type"
    end

    return table.concat(alternatives, " / ")
end

-- Item quality belongs to the source expression and is resolved by the
-- ordinary item generator after the whole floor has been chosen.
local function setup(api)
    api:emit(directives.ITEM, table.concat(armour, " / "))
    api:emit(directives.ITEM, pools.POTIONS)
    api:emit(directives.ITEM, flaming_weapons())
    api:emit(directives.ITEM, "any / star_item w:4")
end

loot.setup = setup

return loot
