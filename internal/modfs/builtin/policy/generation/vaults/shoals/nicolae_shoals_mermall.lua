-- Theory of operation: all four market stalls belong to one generated
-- merfolk proprietor. Their stock lists are source-authored, while one
-- layout-stream name ties the storefronts together for the player.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit named shop features at this source script position. The J shop sells
-- escape supplies so non-merfolk can reach the other flooded stalls.
local function configure_shops(api)
    local owner = api:random_name():gsub(" ", "_")

    api:emit(directives.KFEAT,
        "D = weapon shop name:" .. owner ..
        " type:Merfolk suffix:Weapons ; spear | trident | halberd | " ..
        "demon trident | bardiche | glaive | dagger | quick blade | " ..
        "short sword | rapier | dart | javelin | throwing net | boomerang")

    api:emit(directives.KFEAT,
        "E = armour shop name:" .. owner ..
        " type:Merfolk suffix:Armours ; robe | leather armour | " ..
        "helmet | hat | pair of boots | cloak | scarf | pair of gloves | buckler")

    api:emit(directives.KFEAT,
        "F = general shop name:" .. owner ..
        " type:Merfolk suffix:Magic ; ring of dexterity | ring of evasion | " ..
        "ring of ice | ring of protection | ring of see invisible | " ..
        "ring of willpower | amulet of reflection | amulet of the acrobat | " ..
        "randbook disc:poison | randbook disc:hexes | randbook disc:ice | " ..
        "randbook disc:summoning | phial of floods | condenser vane | " ..
        "lightning rod | wand of charming | wand of iceblast | wand of roots | " ..
        "randbook disc:transmutation")

    api:emit(directives.KFEAT,
        "J = general shop name:" .. owner ..
        " type:Visitors' suffix:Centre greed:100 count:2 use_all ; " ..
        "potion of flight q:1 | scroll of teleportation q:1")
end

handler.configure_shops = configure_shops

return handler
