-- wizlab_yara keeps the original Wizard Lab MAP in its DES file.
-- Each site method below owns one source Lua declaration group.
local shared = require("policy.generation.vaults.wizlab.shared")
local directives = require("constants.vault_directives")

local map = {}

-- The students' weapon and armour pools are authored as equipment slots
-- on two MONS requests. One common slot stays shared across ten casters;
-- the stronger slot belongs to the three senior warriors.
function map.site_1(api)
    local antimagic = "ego:antimagic ident:all"
    local willpower = "ego:willpower ident:all"
    local student_weapons =
        "halberd " .. antimagic .. " | scimitar " .. antimagic ..
        " | morningstar " .. antimagic ..
        " | dire flail " .. antimagic
    local student_armour =
        "ring mail " .. willpower .. " w:3 | scale mail | chain mail"
    local student_gear = student_weapons .. " . " .. student_armour
    local senior_weapons =
        "double sword " .. antimagic ..
        " | demon blade " .. antimagic ..
        " | great sword " .. antimagic ..
        " | glaive " .. antimagic ..
        " | demon trident " .. antimagic ..
        " | bardiche " .. antimagic ..
        " | eveningstar " .. antimagic ..
        " | demon whip " .. antimagic ..
        " | great mace " .. antimagic ..
        " | quick blade " .. antimagic
    local senior_armour =
        "chain mail " .. willpower ..
        " | plate armour " .. willpower ..
        " | plate armour w:20 | crystal plate armour w:3"

    api:emit(directives.MONS,
        "tengu conjurer ; " .. student_gear ..
        " / ogre mage ; " .. student_gear ..
        " / deep elf knight ; " .. student_gear ..
        " / naga mage ; " .. student_gear ..
        " / salamander mystic ; " .. student_gear ..
        " / wizard ; " .. student_gear ..
        " / hell knight ; " .. student_gear ..
        " / necromancer ; " .. student_gear ..
        " / vampire mage ; " .. student_gear ..
        " / spriggan air mage ; rapier " .. antimagic ..
        " . acid dragon scales")
    api:emit(directives.MONS,
        "tengu reaver ; " .. senior_weapons .. " . " .. senior_armour ..
        " / draconian knight ; " .. senior_weapons ..
        " / vampire knight ; " .. senior_weapons ..
        " . " .. senior_armour)
end

-- The Head Instructor's personal name is a per-map seeded draw. Its
-- fixed antimagic sword and willpower armour remain on the keyed actor.
function map.site_2(api)
    local name = api:random_name():gsub(" ", "_")

    api:emit(directives.KMONS,
        "5 = patrolling Head Instructor dbname:Head_Instructor name:" ..
        name .. " ; triple sword ego:antimagic " ..
        ". triple sword ego:antimagic . plate armour ego:willpower")
end

-- Preserve the source spellcaster roster for random summons without
-- adding ambient monster generation to the complete academy map.
function map.site_3(api)
    shared.random_monsters(api,
        "mana viper / tengu conjurer / ogre mage / " ..
        "deep elf knight / wizard / naga mage / " ..
        "salamander mystic / necromancer / vampire mage / " ..
        "tengu reaver w:1 / quicksilver dragon w:1")
    shared.setup(api)
end

-- The source epilogue names this room on first entry.
function map.epilogue(api)
    shared.epilogue(api, "Yara's Duelist Academy")
end

return map
