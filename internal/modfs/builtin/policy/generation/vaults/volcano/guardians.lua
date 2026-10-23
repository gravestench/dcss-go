-- Theory of operation: the source selects one themed three-tier guardian
-- roster while placing a Volcano map. DES MONS and KMONS then resolve it
-- on authored cells through ordinary Akara vault population.
local directives = require("constants.vault_directives")

local guardians = {}

local flaming = "ego:flaming ident:type"
local fire_resistance = "ego:fire_resistance ident:type"
local mage_gear = "spear " .. flaming .. " | whip " .. flaming ..
    " . robe " .. fire_resistance
local good_gear = "scimitar " .. flaming ..
    " | halberd " .. flaming ..
    " | broad axe w:8 " .. flaming ..
    " | flail " .. flaming

-- Source humanoid, village, beast, demon, and elemental rosters have
-- separate draw branches. The first 9/20 draw occurs even when a caller
-- forces an intelligent or village roster, matching Lua short-circuit order.
local function choose(api, intelligent, village)
    local humanoid = api:roll(20) < 9 or village or intelligent

    if humanoid then
        local ogre_gear = "great mace " .. flaming ..
            " | giant club w:14 " .. flaming
        local centaur_gear = "shortbow " .. flaming

        if village then
            api:emit(directives.MONS,
                "two-headed ogre ; " .. ogre_gear ..
                " . " .. ogre_gear ..
                " / centaur ; " .. centaur_gear ..
                " / salamander")
            api:emit(directives.MONS,
                "fire bat / hell hound / hell hog w:2")

            return
        end

        local group = api:roll(3)

        if group == 0 then
            api:emit(directives.MONS,
                "two-headed ogre ; " .. ogre_gear ..
                " . " .. ogre_gear)
            api:emit(directives.MONS,
                "ogre mage w:40 ; " .. mage_gear)
        elseif group == 1 then
            api:emit(directives.MONS,
                "centaur ; " .. centaur_gear ..
                " / yaktaur w:5 ; arbalest " .. flaming)
            api:emit(directives.MONS,
                "centaur warrior ; " .. centaur_gear)
        else
            api:emit(directives.MONS, "salamander")
            api:emit(directives.MONS, "salamander mystic")
        end

        api:emit(directives.MONS,
            "hell knight ; " .. good_gear ..
            " . chain mail " .. fire_resistance ..
            " / red draconian ; " .. good_gear .. " . cloak")

        return
    end

    local group = api:roll(11)

    if group < 4 then
        api:emit(directives.MONS,
            "hell hound / steam dragon w:8 / fire bat band w:8")
        api:emit(directives.MONS,
            "hell hog / lindwurm w:12")
        api:emit(directives.MONS,
            "fire crab w:12 / fire dragon")
    elseif group < 8 then
        api:emit(directives.MONS,
            "hell hound / red ugly thing / " ..
            "red devil ; trident " .. flaming)
        api:emit(directives.MONS,
            "sun demon / smoke demon")
        api:emit(directives.MONS,
            "orc sorcerer ; " .. mage_gear ..
            " / hell knight ; " .. good_gear ..
            " . chain mail " .. fire_resistance)
    else
        api:emit(directives.MONS,
            "fire elemental w:12 / earth elemental / gargoyle w:8")
        api:emit(directives.MONS, "efreet")
        api:emit(directives.MONS, "stone giant")
    end
end

-- Normal map calls preserve the natural 9/20 humanoid decision.
local function ordinary(api)
    choose(api, false, false)
end

-- Intelligent temples always choose humanoid guardians after the
-- source's first draw has consumed its RNG value.
local function intelligent(api)
    choose(api, true, false)
end

-- Village source calls use their two groups and no third leader group.
local function village(api)
    choose(api, true, true)
end

guardians.ordinary = ordinary
guardians.intelligent = intelligent
guardians.village = village

return guardians
