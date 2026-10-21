-- Theory of operation: Trog and Sif Muna share a two-altar gift room.
-- Absolute depth selects three complete scenes: a simple enchanted weapon
-- and one-spell book, a mid-depth branded weapon and two-spell book, or a
-- stronger weapon and three-spell book. The map itself owns altar positions.
-- This module preserves the source's weighted item/ego combinations without
-- depending on Lua table iteration order or a legacy DES global.
local catalog = require("policy.catalog")
local directives = require("constants.vault_directives")
local god_names = require("policy.religion.names")
local gods = require("constants.gods")
local items = require("ids.items")

local handler = {}

local early_weapons = {
    items.WPN_SPEAR,
    items.WPN_HAND_AXE,
    items.WPN_MACE,
    items.WPN_FALCHION,
}

local middle_weapons = {
    items.WPN_TRIDENT,
    items.WPN_WAR_AXE,
    items.WPN_FLAIL,
    items.WPN_LONG_SWORD,
}

local late_weapons = {
    items.WPN_TRIDENT,
    items.WPN_WAR_AXE,
    items.WPN_MORNINGSTAR,
    items.WPN_SCIMITAR,
}

local branded_egos = {
    { name = "antimagic", weight = 1 },
    { name = "flaming", weight = 2 },
    { name = "vorpal", weight = 2 },
}

-- The source helper sorted item names before building weighted alternatives.
-- Resolve names from imported catalog IDs so definitions remain authoritative.
local function sorted_weapon_names(ids)
    local names = {}

    for _, id in ipairs(ids) do
        names[#names + 1] = catalog.get("items", id).name
    end

    table.sort(names)

    return names
end

-- Construct every source weapon/ego combination as one KITEM choice list.
-- The weight is the product of its item and ego weights; all listed item
-- types have source weight one in this vault.
local function weapon_choices(ids, enchant, egos)
    local alternatives = {}

    for _, name in ipairs(sorted_weapon_names(ids)) do
        if egos then
            for _, ego in ipairs(egos) do
                alternatives[#alternatives + 1] =
                    name .. " plus:" .. enchant .. " ego:" .. ego.name ..
                    " w:" .. ego.weight
            end
        else
            alternatives[#alternatives + 1] =
                name .. " plus:" .. enchant .. " ego:none w:1"
        end
    end

    return "1 = " .. table.concat(alternatives, " / ")
end

-- The source DES token uses underscores, while its display owner comes
-- from the common god-name catalog rather than a second copied spelling.
local function sif_book(spells, levels)
    local owner = god_names[gods.SIF_MUNA]:gsub(" ", "_")

    return "2 = randbook owner:" .. owner ..
        " numspells:" .. spells .. " slevels:" .. levels
end

-- Emit one complete tier in the source order: monster guards, Trog's
-- weapon, then Sif's book. The mid-tier unique pair uses one separate draw.
local function choose_gifts(api)
    local depth = api:absolute_depth()

    if depth <= 3 then
        local enchant = api:one_in(3) and 3 or 2

        api:emit(directives.KITEM,
            weapon_choices(early_weapons, enchant))
        api:emit(directives.KMONS,
            "1 = gnoll ; animal skin / w:2 Terence")
        api:emit(directives.KMONS,
            "2 = white imp / w:2 Jessica")
        api:emit(directives.KITEM, sif_book(1, 1))
    elseif depth <= 7 then
        if api:one_in(5) then
            api:emit(directives.KMONS, "1 = duvessa")
            api:emit(directives.KMONS, "2 = dowan")
        else
            api:emit(directives.KMONS, "1 = orc warrior")
            api:emit(directives.KMONS, "2 = orc wizard")
        end

        api:emit(directives.KITEM,
            weapon_choices(middle_weapons, 0, branded_egos))
        api:emit(directives.KITEM, sif_book(2, 2))
    else
        api:emit(directives.KMONS, "1 = troll")
        api:emit(directives.KMONS, "2 = ynoxinul")
        api:emit(directives.KITEM,
            weapon_choices(late_weapons, 0, branded_egos))
        api:emit(directives.KITEM, sif_book(3, 4))
    end
end

handler.choose_gifts = choose_gifts

return handler
