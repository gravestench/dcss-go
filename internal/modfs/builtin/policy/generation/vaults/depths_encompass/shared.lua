-- The source profane and radiant helpers are shared by several distinct
-- DES maps. Their ordered directives live in these named Lua methods so
-- modders can replace one module without copying the map geometry.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local rules = require("constants.vault_generation_rules")

local shared = {}

-- Keep the source's three guardian tiers dependent on whether this floor
-- owns Zot. The flame marker and percent substitutions are common to all
-- profane temples, loot rooms, and the enclosing hall.
local function profane_setup(api)
    if api:branch_entry(branches.BRANCH_ZOT) then
        api:emit(directives.KMONS,
            "1 = base draconian / nothing w:25")
        api:emit(directives.KMONS,
            "2 = nonbase draconian / base draconian w:20")
        api:emit(directives.KMONS,
            "3 = draconian stormcaller / draconian monk w:2")
    else
        api:emit(directives.KMONS,
            "1 = tengu warrior / tengu conjurer / glowing orange brain / " ..
            "spriggan berserker w:5 / spriggan air mage w:5 / " ..
            "deep elf demonologist w:5 / nothing w:68")
        api:emit(directives.KMONS,
            "2 = spriggan berserker / tengu warrior w:20")
        api:emit(directives.KMONS, "3 = deep elf high priest")
    end

    api:emit(directives.SUBST, "% = * %:20 .")
    api:emit(directives.MARKER,
        ': = lua:fog_machine { cloud_type = "flame", pow_min = 10, ' ..
        'pow_max = 10, delay = 10, size = 1, spread_rate = 0, ' ..
        'walk_dist = 0, excl_rad = 0 }')
end

-- The two Radiant Caverns maps share one monster roster. The source assigns
-- these MONS slots before keyed creatures so the numbered MAP cells refer
-- to the same choices in both different geometries.
local function radiant_monsters(api)
    api:emit(directives.MONS,
        "raiju band / spriggan air mage band / titan w:5 / " ..
        "storm dragon w:5 / shock serpent w:5 / blizzard demon w:15")
    api:emit(directives.MONS,
        "w:20 obsidian statue / w:1 orange crystal statue")
    api:emit(directives.MONS, "glowing shapeshifter")
    api:emit(directives.MONS, "very ugly thing / ugly thing w:5")
    api:emit(directives.MONS, "ball lightning")
    api:emit(directives.MONS, "crystal guardian")

    local keyed = {
        "8 = dancing weapon",
        "9 = war gargoyle",
        "0 = glowing shapeshifter hd:15",
        "EW = water elemental",
        "e = earth elemental",
        "f = fire elemental",
        "a = air elemental",
        "o = iron golem",
        "r = war gargoyle / molten gargoyle / nothing w:20",
        "t = glowing orange brain / wind drake w:5",
    }

    for _, expression in ipairs(keyed) do
        api:emit(directives.KMONS, expression)
    end
end

-- Source transformations run in order: shuffle the two wings, assign
-- special item cells, then vary the dense elemental encounters and walls.
local function radiant_substitutions(api)
    api:emit(directives.KFEAT, "A = stone_arch")
    api:emit(directives.KFEAT, "W = deep_water")

    for _, expression in ipairs({
        "wKLMN / lghij",
        "KLMN",
        "ghij",
        "JH",
        "34",
    }) do
        api:emit(directives.SHUFFLE, expression)
    end

    for _, expression in ipairs({
        "p = potion of mutation ident:type",
        "P = any jewellery good_item",
        "Q = potion of mutation ident:type",
        "R = potion of mutation ident:type / nothing",
    }) do
        api:emit(directives.KITEM, expression)
    end

    for _, expression in ipairs({
        "u = 2:Q / 1:P / 1:R / *:u",
        "G = 1:G / *:2",
        "H = 2:8 / 2:3",
        "J = 2:3 / 2:4",
        "w = 4:W / *:w",
        "1 = 3:1 / *:.",
    }) do
        api:emit(directives.NSUBST, expression)
    end

    for _, expression in ipairs({
        "s = ..$*p|",
        "u = ..$||",
        "3 = 3.",
        "5 = 5 .:4",
        "g = E:30 3 .:30",
        "h = a:30 3 .:30",
        "K = r:20 f e:40 .:70",
        "iL = e.",
        "jM = 79 o:1 .:21",
        "m = 4:15 .:25",
        "N = ef..",
        "n = 0 8:5 .:25",
        "q = 379e",
        "S = r:20 9:1 .:21",
        "t = 5fa t:20 .:75",
        "y = 0:20 78",
        "z = 7 8:30",
        "x = x:595 b:405",
    }) do
        api:emit(directives.SUBST, expression)
    end
end

-- The shared setup keeps the source's rare weight in DES where the catalog
-- can see it before selection. This method supplies the remaining dynamic
-- placement directives and the floor's separate ambient monster pool.
local function radiant_setup(api)
    radiant_monsters(api)
    radiant_substitutions(api)
    api:emit(directives.MARKER, "A = lua:props_marker { portal=1 }")
    api:record(effects.GENERATION_RULE, {
        rule = rules.RANDOM_MONSTER_LIST,
        expression = "glowing shapeshifter w:100 / air elemental / " ..
            "water elemental / earth elemental / crystal guardian / " ..
            "molten gargoyle / war gargoyle / dancing weapon / " ..
            "very ugly thing band",
    })
end

shared.profane_setup = profane_setup
shared.radiant_setup = radiant_setup

return shared
