-- Theory of operation: Ice Cave has no ambient floor loot. Each authored
-- reward glyph resolves one of the source's cold-themed requests when the
-- chosen map is populated. Hard caves raise item quality at that point.
local directives = require("constants.vault_directives")
local loot_pools = require("constants.vault_loot")
local weighted = require("policy.generation.vaults.ice_cave.weighted_items")

local loot = {}

local strong_weapons = {
    ["arbalest"] = 5,
    ["bardiche"] = 5,
    ["battleaxe"] = 10,
    ["broad axe"] = 10,
    ["demon blade"] = 5,
    ["demon trident"] = 5,
    ["demon whip"] = 5,
    ["double sword"] = 5,
    ["eveningstar"] = 5,
    ["executioner's axe"] = 5,
    ["frostbite"] = 2,
    ["giant club"] = 5,
    ["giant spiked club"] = 5,
    ["glaive"] = 10,
    ["great mace"] = 10,
    ["great sword"] = 10,
    ["halberd"] = 10,
    ["hand crossbow"] = 10,
    ["lajatang"] = 10,
    ["longbow"] = 10,
    ["maxwell's thermic engine"] = 2,
    ["morningstar"] = 10,
    ["scimitar"] = 10,
    ["triple crossbow"] = 5,
    ["triple sword"] = 5,
}

-- A missing saved difficulty means the entrance and destination have lost
-- their contract. Never silently create an easy cave as a fallback.
local function hard(api)
    local value = api:setting("ice_cave_hard")

    if type(value) ~= "boolean" then
        error("Ice Cave loot needs saved easy/hard difficulty")
    end

    return value
end

-- Three slots progress from auxiliary gear to heavy armour. The source
-- permits Skin of Zhor in the middle slot even though it is an unrand.
local function armour(api, glyphs, is_hard)
    local quality = is_hard and " good_item" or ""
    local cold = " ego:cold_resistance ident:type"
    local resistance = " ego:resistance ident:type"

    api:emit(directives.KITEM,
        glyphs:sub(1, 1) .. " = cloak" .. cold .. quality .. " w:5" ..
        " / scarf" .. resistance .. " w:5" ..
        " / hat" .. quality .. " w:5" ..
        " / helmet" .. quality .. " w:5" ..
        " / pair of gloves" .. quality ..
        " / pair of boots" .. quality ..
        " / buckler" .. cold .. quality)
    api:emit(directives.KITEM,
        glyphs:sub(2, 2) .. " = robe" .. resistance .. quality ..
        " / leather armour" .. resistance .. quality ..
        " / scale mail" .. cold .. quality ..
        " / skin of zhor w:2" ..
        " / kite shield" .. cold .. quality)
    api:emit(directives.KITEM,
        glyphs:sub(3, 3) .. " = ice dragon scales" .. quality ..
        " / chain mail" .. cold .. quality ..
        " / plate armour" .. cold .. quality ..
        " / crystal plate armour" .. cold .. quality ..
        " / tower shield" .. cold .. quality)
end

-- Both weapon slots force freezing. The first is sometimes high quality
-- in an easy cave; the second retains the source's rare unrand weights.
local function weapons(api, glyphs, is_hard)
    local freeze = " ego:freezing ident:type"
    local quality = is_hard and " good_item" or ""
    local first = "any weapon" .. freeze

    if is_hard then
        first = first .. quality
    else
        first = first .. " / any weapon" .. freeze .. " good_item"
    end

    api:emit(directives.KITEM, glyphs:sub(1, 1) .. " = " .. first)
    api:emit(directives.KITEM,
        glyphs:sub(2, 2) .. " = " ..
        weighted.describe(strong_weapons, "freezing",
            "ident:type" .. quality))
end

-- Spellbooks, resistance jewellery, and cold-themed evokables share one
-- final reward slot. Only the two jewellery alternatives gain good_item.
local function magic(api, glyph, is_hard)
    local quality = is_hard and " good_item" or ""

    api:emit(directives.KITEM,
        glyph .. " = book of ice / book of the tundra" ..
        " / ozocubu's autobiography / randbook disc:ice" ..
        " / manual of ice magic / staff of cold / ring of ice" ..
        quality .. " / ring of protection from cold" .. quality ..
        " / wand of iceblast / phial of floods / condenser vane")
end

-- Every normal cave map calls the source six-slot pool. Glyph changes are
-- local to a map, while the content probabilities stay centralized here.
function loot.common(api, glyphs)
    glyphs = glyphs or "defghi"

    if #glyphs ~= 6 then
        error("Ice Cave common loot needs six glyphs")
    end

    local is_hard = hard(api)

    armour(api, glyphs:sub(1, 3), is_hard)
    weapons(api, glyphs:sub(4, 5), is_hard)
    magic(api, glyphs:sub(6, 6), is_hard)
end

-- Necromantic cave maps add an independent book, staff, or artefact ring
-- slot after their ordinary cold loot.
function loot.necro(api, glyph)
    glyph = glyph or "j"

    api:emit(directives.KITEM,
        glyph .. " = book of unlife / randbook disc:ice " ..
        "disc2:necromancy numspells:6 / manual of necromancy w:5" ..
        " / staff of death / ring of positive energy randart")
end

-- Source dungeon.lua owns this fixed potion request; binding it to `j`
-- preserves the small giant's authored reward location.
function loot.potions_j(api)
    api:emit(directives.KITEM, "j = " .. loot_pools.POTIONS)
end

-- The tomb-like map binds its useful-scroll request to two glyphs.
function loot.scrolls_d8(api)
    api:emit(directives.KITEM, "D8 = " .. loot_pools.SCROLLS)
end

-- Cavern maps use one ordinary wand, potion, or scroll item slot.
function loot.cavern_j(api)
    api:emit(directives.KITEM,
        "j = any wand / any potion w:5 / any scroll w:5")
end

-- The other cavern reward combines a miscellaneous item with the source
-- useful potion and scroll pools as weighted alternatives.
function loot.cavern_k(api)
    api:emit(directives.KITEM,
        "k = any misc / " .. loot_pools.POTIONS ..
        " / " .. loot_pools.SCROLLS)
end

return loot
