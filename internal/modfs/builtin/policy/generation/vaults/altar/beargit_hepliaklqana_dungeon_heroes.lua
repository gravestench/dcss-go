-- Theory of operation: Hepliaklqana's altar chooses one source hero
-- group for the current Dungeon depth, or the stronger Depths group.
-- Only that group emits MONS/KMONS slots, so the DES array keeps at most
-- three active entries and its 1/2/3 shuffle retains its source meaning.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- One ancestor on D:3; early wand users carry charming.
local dungeon_3 = {
    {
        kind = directives.KMONS,
        argument = [[
            1 = orc wizard; quarterstaff . robe
        ]],
    },
    {
        kind = directives.KMONS,
        argument = [[
            2 = jessica; dagger . robe . wand of charming / kobold brigand ; dagger .
            wand of charming , kobold brigand ; dagger . wand of charming
        ]],
    },
    {
        kind = directives.KMONS,
        argument = [[
            3 = orc ; flail . kite shield . chain mail
        ]],
    },
    {
        kind = directives.NSUBST,
        argument = [[
            123 = 2=.
        ]],
    },
}

-- One ancestor on D:4–6, with stronger named heroes.
local dungeon_4_to_6 = {
    {
        kind = directives.KMONS,
        argument = [[
            1 = blork the orc ; quarterstaff good_item . robe / orc wizard ;
            quarterstaff good_item . robe , orc wizard ; quarterstaff good_item . robe
        ]],
    },
    {
        kind = directives.KMONS,
        argument = [[
            2 = sigmund; halberd itemname:scythe tile:wpn_scythe wtile:scythe
            ego:draining . robe / kobold brigand ; dagger ego:draining . wand of
            charming , kobold brigand ; dagger ego:draining . wand of charming
        ]],
    },
    {
        kind = directives.KMONS,
        argument = [[
            3 = edmund ; flail good_item . kite shield . chain mail / orc warrior ;
            flail good_item . kite shield . chain mail / gnoll sergeant ; flail
            good_item . kite shield . chain mail , orc warrior ; flail good_item . kite
            shield . chain mail / gnoll sergeant ; flail good_item . kite shield .
            chain mail
        ]],
    },
    {
        kind = directives.NSUBST,
        argument = [[
            123 = 2=.
        ]],
    },
}

-- One ancestor on D:7–9, using the source mid-Dungeon gear.
local dungeon_7_to_9 = {
    {
        kind = directives.MONS,
        argument = [[
            gargoyle ; quarterstaff good_item
        ]],
    },
    {
        kind = directives.MONS,
        argument = [[
            kobold brigand ; dagger ego:draining good_item . wand of paralysis . dart
            ego:atropa / spriggan ; dagger ego:draining good_item . robe good_item .
            buckler . wand of paralysis / vampire ; dagger ego:draining good_item .
            robe good_item
        ]],
    },
    {
        kind = directives.MONS,
        argument = [[
            orc warrior ; flail good_item . kite shield . chain mail good_item / gnoll
            sergeant ; flail good_item . kite shield . chain mail good_item
        ]],
    },
    {
        kind = directives.NSUBST,
        argument = [[
            123 = 2=.
        ]],
    },
}

-- Two ancestors on D:10–12, selected by NSUBST.
local dungeon_10_to_12 = {
    {
        kind = directives.MONS,
        argument = [[
            gargoyle ; quarterstaff good_item / molten gargoyle w:5 ; quarterstaff
            good_item
        ]],
    },
    {
        kind = directives.MONS,
        argument = [[
            kobold brigand ; dagger ego:draining good_item . wand of paralysis . dart
            ego:atropa . potion of haste / spriggan ; dagger ego:draining good_item .
            robe good_item . buckler . wand of paralysis . potion of haste / vampire ;
            dagger ego:draining good_item . robe good_item . potion of haste
        ]],
    },
    {
        kind = directives.MONS,
        argument = [[
            orc warrior ; flail good_item . kite shield . chain mail good_item / gnoll
            sergeant ; flail good_item . kite shield . chain mail good_item / skeletal
            warrior ; flail good_item . kite shield . chain mail good_item
        ]],
    },
    {
        kind = directives.NSUBST,
        argument = [[
            123 = 1=.
        ]],
    },
}

-- All three ancestors on D:13 and deeper.
local dungeon_13_plus = {
    {
        kind = directives.MONS,
        argument = [[
            ogre mage; lajatang ego:freezing . potion of haste / molten gargoyle ;
            lajatang ego:flaming . potion of haste
        ]],
    },
    {
        kind = directives.MONS,
        argument = [[
            spriggan ; dagger ego:draining good_item . robe good_item . buckler
            good_item . wand of paralysis . potion of haste / vampire ; dagger
            ego:draining good_item . robe good_item . buckler . wand of paralysis .
            potion of haste
        ]],
    },
    {
        kind = directives.MONS,
        argument = [[
            orc knight; broad axe ego:flaming . chain mail good_item . tower shield
            ego:reflection . potion of haste / tengu warrior ; broad axe ego:flaming .
            chain mail good_item . tower shield ego:reflection . potion of haste / naga
            warrior ; broad axe ego:flaming . chain mail good_item . tower shield
            ego:reflection . potion of haste / skeletal warrior ; broad axe ego:flaming
            . chain mail good_item . tower shield ego:reflection . potion of haste
        ]],
    },
}

-- All three Depths ancestors use the source high-tier equipment.
local depths = {
    {
        kind = directives.MONS,
        argument = [[
            tengu reaver ; lajatang ego:freezing good_item | lajatang ego:freezing
            randart . scale mail . potion of haste . potion of haste / ancient champion
            ; lajatang ego:freezing good_item | lajatang ego:freezing randart . scale
            mail
        ]],
    },
    {
        kind = directives.MONS,
        argument = [[
            vampire knight; quick blade ego:antimagic . buckler good_item . shadow
            dragon scales good_item . potion of haste . potion of haste / spriggan
            defender; quick blade ego:antimagic w:20 . robe good_item . buckler
            good_item . wand of paralysis . potion of haste . potion of haste
        ]],
    },
    {
        kind = directives.MONS,
        argument = [[
            minotaur ; broad axe ego:speed good_item | broad axe ego:speed randart |
            arga w:1 . plate armour good_item . tower shield ego:reflection good_item .
            potion of haste . potion of haste / orc warlord ; broad axe ego:speed
            good_item | broad axe ego:speed randart | arga w:1 . plate armour good_item
            . tower shield ego:reflection good_item . potion of haste . potion of haste
        ]],
    },
}

-- Insert only the selected group at this hook position in the .des file.
-- This keeps map geometry in DES while Lua owns its source depth policy.
local function choose_heroes(api)
    local group

    if api:branch_id() == branches.BRANCH_DEPTHS then
        group = depths
    elseif api:depth() < 4 then
        group = dungeon_3
    elseif api:depth() < 7 then
        group = dungeon_4_to_6
    elseif api:depth() < 10 then
        group = dungeon_7_to_9
    elseif api:depth() < 13 then
        group = dungeon_10_to_12
    else
        group = dungeon_13_plus
    end

    for _, operation in ipairs(group) do
        api:emit(operation.kind, operation.argument)
    end
end

handler.choose_heroes = choose_heroes

return handler
