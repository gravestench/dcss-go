-- The source bazaar's sign suffixes and stock belong to its content, not
-- the generic shop generator. A mod can replace this table or its hook.
local shop = {
    SUFFIXES = {
        "Zone",
        "Stash",
        "Warehouse",
        "Hoard",
        "Trove",
        "Cache",
        "Depot",
        "Stock",
        "Depository",
        "Bin",
        "Store",
        "Supply",
        "Sales",
        "Hole",
        "Deals",
        "Outlet",
        "Market",
        "Inventory",
    },

    RARITIES = "any weapon randart | any armour randart | " ..
        "any jewellery randart | any randbook",
    SUNDRIES = "any | any good_item | star_item",
    ACCESSORIES = "any misc | any wand w:15",
    HARDWARE = "any weapon good_item | any armour good_item",
    INFERNAL = "any weapon good_item ego:draining | " ..
        "any weapon good_item ego:pain | " ..
        "any weapon good_item ego:chaos | " ..
        "any weapon good_item ego:vampirism | " ..
        "demon blade good_item | demon trident good_item | " ..
        "demon whip good_item | staff of death w:3 | " ..
        "scroll of torment q:2 w:5 | scroll of torment q:3 w:5 | " ..
        "randbook disc:necromancy",
}

return shop
