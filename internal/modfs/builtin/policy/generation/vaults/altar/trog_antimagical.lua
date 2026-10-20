-- Theory of operation: Trog's antimagic guard has two source equipment
-- pools. The shallow pool equips ordinary orcs, kobolds, goblins, or gnolls;
-- beyond absolute depth five it equips ogres, orc warriors, or brigands.
-- Each alternative remains inside one KMONS slot keyed to glyph 1.
local directives = require("constants.vault_directives")

local shallow_guard = table.concat({
    "1 = orc god:trog ; spear ego:antimagic ident:type |",
    "hand axe ego:antimagic ident:type | war axe ego:antimagic ident:type |",
    "any weapon / kobold god:trog ; short sword ego:antimagic ident:type |",
    "hand axe ego:antimagic ident:type | club ego:antimagic ident:type |",
    "whip ego:antimagic ident:type | any weapon / goblin god:trog ;",
    "dagger ego:antimagic ident:type | short sword ego:antimagic ident:type /",
    "gnoll god:trog ; spear ego:antimagic ident:type |",
    "trident ego:antimagic ident:type | halberd ego:antimagic ident:type |",
    "whip ego:antimagic ident:type | halberd | any weapon",
}, " ")

local deep_guard = table.concat({
    "1 = ogre god:trog ; giant club ego:antimagic ident:type |",
    "w:3 giant club / ogre god:trog ;",
    "giant spiked club ego:antimagic ident:type | w:5 giant spiked club /",
    "orc warrior god:trog ; halberd ego:antimagic ident:type |",
    "war axe ego:antimagic ident:type | flail ego:antimagic ident:type |",
    "great mace ego:antimagic ident:type | any weapon /",
    "kobold brigand god:trog ; short sword ego:antimagic ident:type |",
    "dagger ego:antimagic ident:type | rapier ego:antimagic ident:type |",
    "rapier",
}, " ")

local handler = {}

-- Choose the source equipment pool without changing its internal weights.
local function choose_guard(api)
    if api:absolute_depth() > 5 then
        api:emit(directives.KMONS, deep_guard)
    else
        api:emit(directives.KMONS, shallow_guard)
    end
end

handler.choose_guard = choose_guard

return handler
