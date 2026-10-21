-- Theory of operation: Big Baal Hell advertises an eleven-item shop
-- with two picks for each Hell branch, two broadly useful picks, and one
-- holy weapon. The lists retain source duplicates as intentional weights;
-- each list is drawn without replacement in source order at placement time.
local directives = require("constants.vault_directives")

-- Dis buyers need direct damage, armour, and corrosion answers.
local dis_items = {
    "any weapon good_item ego:vorpal",
    "any weapon randart ego:vorpal",
    "ring of slaying randart",
    "ring of protection randart",
    "any weapon good_item ego:protection",
    "any weapon randart ego:protection",
    "crystal plate armour randart",
    "gold dragon scales randart",
    "tower shield randart",
    "ring of resist corrosion randart",
    "amulet of reflection randart",
    "scroll of enchant weapon q:10",
    "scroll of enchant armour q:10",
    "potion of might q:10",
    "randbook disc:conjuration slevels:12",
    "randbook disc:earth slevels:12",
    "staff of earth",
    "staff of conjuration",
}

-- Gehenna stocks fire protection and cold attacks for its lava fights.
local gehenna_items = {
    "any weapon good_item ego:freezing",
    "any weapon randart ego:freezing",
    "ring of protection from fire randart",
    "ring of fire randart",
    "fire dragon scales randart",
    "wand of iceblast charges:25",
    "any armour good_item ego:fire_resistance",
    "any armour randart ego:fire_resistance",
    "potion of invisibility q:10",
    "randbook disc:ice slevels:12",
    "randbook disc:translocation slevels:12",
    "staff of fire",
}

-- Cocytus reverses those elements and adds willpower for narguns.
local cocytus_items = {
    "any weapon good_item ego:flaming",
    "any weapon randart ego:flaming",
    "ring of protection from cold randart",
    "ring of ice randart",
    "ice dragon scales randart",
    "wand of flame charges:55",
    "any armour good_item ego:cold_resistance",
    "any armour randart ego:cold_resistance",
    "ring of willpower randart",
    "randbook disc:fire slevels:12",
    "staff of air",
    "staff of cold",
}

-- Tartarus emphasizes willpower, negative-energy defence, and fog.
local tartarus_items = {
    "ring of willpower randart",
    "ring of positive energy randart",
    "any armour randart ego:positive_energy",
    "any armour randart ego:willpower",
    "pearl dragon scales randart",
    "scroll of fog q:10",
    "any armour good_item ego:positive_energy",
    "any armour good_item ego:willpower",
    "quicksilver dragon scales randart",
    "staff of death",
}

-- These supplies help in any Hell. Repeated entries bias the source draw.
local general_items = {
    "scroll of blinking q:10",
    "scroll of magic mapping q:10",
    "scroll of silence q:10",
    "scroll of summoning q:10",
    "scroll of teleportation q:10",
    "potion of brilliance q:10",
    "potion of cancellation q:10",
    "potion of curing q:10",
    "potion of haste q:10",
    "potion of heal wounds q:10",
    "potion of magic q:10",
    "potion of experience",
    "potion of resistance q:10",
    "any weapon randart",
    "any armour randart",
    "any jewellery randart",
    "any weapon randart",
    "any armour randart",
    "any jewellery randart",
    "any wand charges:25",
    "ring of positive energy randart",
    "ring of willpower randart",
    "randbook good_item",
    "randbook good_item",
    "ring of wizardry randart",
    "any magical staff",
    "scroll of acquirement",
    "any manual",
    "demon trident randart",
    "demon whip randart",
    "demon blade randart",
    "javelin ego:silver q:25",
    "any misc",
}

-- One holy randart is guaranteed as a final, separate shelf.
local holy_weapons = {
    "quick blade randart ego:holy_wrath",
    "rapier randart ego:holy_wrath",
    "eudemon blade randart ego:holy_wrath",
    "great sword randart ego:holy_wrath",
    "battleaxe randart ego:holy_wrath",
    "executioner's axe randart ego:holy_wrath",
    "trishula randart ego:holy_wrath",
    "sacred scourge randart ego:holy_wrath",
    "eveningstar randart ego:holy_wrath",
    "bardiche randart ego:holy_wrath",
    "lajatang randart ego:holy_wrath",
    "hand crossbow randart ego:holy_wrath",
    "longbow randart ego:holy_wrath",
    "arbalest randart ego:holy_wrath",
    "triple crossbow randart ego:holy_wrath",
}

local handler = {}

-- Draw branch-specific shelves independently so a change to one list cannot
-- consume another list's choices. The final expression is a normal keyed
-- shop feature, processed by the shared DES placement and shop owners.
local function setup_shop(api)
    local dis = api:subset(dis_items, 2)
    local gehenna = api:subset(gehenna_items, 2)
    local cocytus = api:subset(cocytus_items, 2)
    local tartarus = api:subset(tartarus_items, 2)
    local general = api:subset(general_items, 2)
    local holy = api:subset(holy_weapons, 1)

    local inventory = {
        table.concat(dis, " | "),
        table.concat(gehenna, " | "),
        table.concat(cocytus, " | "),
        table.concat(tartarus, " | "),
        table.concat(general, " | "),
        holy[1],
    }
    local stock = table.concat(inventory, " | ")
    local shop = "S = general shop name:Big_Baal_Hell type:Store " ..
        "suffix: count:11 use_all greed:66 ; " .. stock

    api:emit(directives.KFEAT, shop)
end

handler.setup_shop = setup_shop

return handler
