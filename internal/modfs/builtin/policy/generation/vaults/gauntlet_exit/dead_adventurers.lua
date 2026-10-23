-- Theory of operation: this source exit scatters themed remains across
-- fixed corpse glyphs while a live minotaur guards the return arch.
-- Each corpse persists until seen, then ordinary decay resumes; its
-- nearby equipment uses the exact source alternatives and weights.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local loot = require("constants.vault_loot")

local module = {}

-- Reuse source armour pools so all twelve dead archetypes refer to
-- one local vocabulary instead of copying alternatives per corpse.
local light_scales = "troll leather armour good_item" ..
    " / steam dragon scales good_item / acid dragon scales good_item"
local medium_scales = "swamp dragon scales good_item" ..
    " / quicksilver dragon scales / fire dragon scales good_item" ..
    " / ice dragon scales good_item / quicksilver dragon scales" ..
    " / pearl dragon scales good_item"
local heavy_scales = "storm dragon scales / shadow dragon scales" ..
    " / gold dragon scales"
local heavy_armour = "scale mail good_item w:50 / chain mail good_item w:50" ..
    " / plate armour good_item w:50 / crystal plate armour good_item"

-- Emit the corpse and every equipment slot at its authored glyph.
-- The sight trigger releases only the corpse's preservation flag.
local function place_remains(api, glyph, corpse, equipment)
    api:emit(directives.KITEM,
        glyph .. " = never_decay " .. corpse .. ", " .. equipment)
    api:record(effects.DELAYED_DECAY, {
        glyph = glyph,
        alternatives = corpse,
    })
end

-- The Dwarven fighter always contributes a weapon; its heavier armour and shield vary.
local function dwarven_fighter(api)
    place_remains(api, "D", "dwarf skeleton",
        "flail randart / morningstar good_item / eveningstar w:2" ..
        "    / demon whip w:2 / dire flail good_item / great mace good_item" ..
        "    / war axe randart / broad axe good_item / battleaxe good_item" ..
        "    / executioner's axe w:2 " ..
        ", ring mail randart w:50 / " .. heavy_armour .. " / " .. medium_scales ..
        "    / " .. heavy_scales ..
        ", kite shield good_item / tower shield good_item / " .. loot.GOOD_AUX_ARMOUR ..
        "    / nothing w:80" ..
        ", any wand w:20 / any misc / gold / any scroll / any potion" ..
        "    / nothing w:60")
end

-- The fallen hunter has a ranged weapon and armour beside the living minotaur.
local function minotaur_hunter(api)
    place_remains(api, "E", "minotaur skeleton",
        "shortbow good_item / longbow w:5 / arbalest good_item" ..
        "    / triple crossbow w:5 / javelin good_item" ..
        ", leather armour good_item w:50 / ring mail good_item w:50" ..
        "    / " .. heavy_armour .. " / " .. medium_scales ..
        "    / " .. heavy_scales ..
        -- The pinned source spells this slot `, / good_aux_armour`, which
        -- has an empty leading alternative. That is a source typo, not a
        -- deliberate no-item outcome; the explicit `nothing` follows.
        ", " .. loot.GOOD_AUX_ARMOUR ..
        "    / nothing w:40" ..
        ", any wand w:20 / any misc / gold / any scroll / any potion" ..
        "    / nothing w:60")
end

-- The Spriggan keeps a light blade and has a chance of magic or a shield.
local function spriggan_stabber(api)
    place_remains(api, "F", "spriggan skeleton",
        "dagger good_item / short sword good_item / rapier good_item" ..
        "    / quick blade w:5" ..
        ", robe good_item w:120 / " .. light_scales .. " / shadow dragon scales" ..
        ", randbook disc:hexes / book of misfortune / nothing w:20" ..
        ", buckler good_item / hat good_item / any wand w:20 / any misc / gold" ..
        "    / any scroll / any potion / nothing w:80")
end

-- The Merfolk has three guaranteed gear slots and a sparse fourth prize.
local function merfolk_gladiator(api)
    place_remains(api, "H", "merfolk skeleton",
        "trident good_item / demon trident / glaive good_item / bardiche" ..
        ", leather armour good_item w:100 / ring mail good_item w:100" ..
        "    / " .. light_scales .. " / " .. medium_scales ..
        -- Give this a 1/4 in chance of placing since we guarantee 3 items above.
        ", buckler good_item / kite shield good_item / tower shield good_item" ..
        "    / " .. loot.GOOD_AUX_ARMOUR .. " / any wand w:20 / any misc / gold" ..
        "    / any scroll / any potion / nothing w:480")
end

-- The Orc has three guaranteed gear slots and a sparse fourth prize.
local function orc_fighter(api)
    place_remains(api, "J", "orc skeleton",
        "long sword good_item / double sword w:5 / demon blade w:5" ..
        "    / flail good_item / morningstar good_item / eveningstar" ..
        "    / war axe good_item / broad axe good_item / trident good_item" ..
        "    / demon trident w:5" ..
        ", kite shield good_item / tower shield good_item w:5" ..
        ", ring mail randart w:50 / " .. heavy_armour .. " / " .. medium_scales ..
        "    / " .. heavy_scales ..
        -- Give this a 1/4 in chance of placing since we guarantee 3 items above.
        ", any wand w:20 / any misc / gold / any scroll / any potion" ..
        "    / " .. loot.GOOD_AUX_ARMOUR ..  " / nothing w:390")
end

-- The Ogre may have a huge weapon, staff, spellbook, or flexible support gear.
local function ogre_caster(api)
    place_remains(api, "K", "ogre skeleton",
        "trident good_item / demon trident / glaive good_item / bardiche" ..
        "    / war axe randart / broad axe good_item / battleaxe good_item" ..
        "    / executioner's axe w:2 / giant club good_item" ..
        "    / giant spiked club good_item / quarterstaff good_item / lajatang" ..
        "    / any magical staff w:20" ..
        ", robe good_item w:200 / " .. light_scales .. " / " .. medium_scales ..
        "    / " .. heavy_scales ..
        ", hat good_item w:20 / cloak good_item w:20 / kite shield good_item" ..
        "    / tower shield good_item / nothing w:60" ..
        ", randbook w:20 / any wand w:20 / any misc / gold / any scroll" ..
        "    / any potion / nothing w:80")
end

-- The wanderer has broad, variable equipment instead of a guaranteed weapon.
local function human_wanderer(api)
    place_remains(api, "L", "human skeleton",
        "any armour good_item, any weapon good_item / randbook / any misc" ..
        ", any book / any jewellery / any wand w:20 / any misc / gold" ..
        "    / any scroll / any potion / nothing w:70" ..
        ", any book / any jewellery / any wand w:20 / any misc / gold" ..
        "    / any scroll / any potion / nothing w:70")
end

-- The Elf has a spellbook and staff with light protective gear.
local function elf_caster(api)
    place_remains(api, "M", "elf skeleton",
        "randbook, any magical staff" ..
        ", robe good_item w:50 / leather armour good_item w:50" ..
        "    / " .. light_scales .. " / buckler good_item" ..
        "    / " .. loot.GOOD_AUX_ARMOUR .. " / nothing" ..
        ", any jewellery w:20 / any wand w:20 / any misc / gold" ..
        "    / any scroll / any potion / nothing w:80")
end

-- The artificer guarantees a wand and misc tool before optional gear.
local function dwarf_artificer(api)
    place_remains(api, "N", "dwarf skeleton",
        "any wand, any misc, any wand / any misc / nothing w:20" ..
        ", any weapon good_item / any armour good_item / gold / any scroll" ..
        "    / any potion / nothing w:50")
end

-- The Octopode guarantees two rings and can leave more jewellery.
local function octopode(api)
    place_remains(api, "O", "octopode corpse",
        "any ring good_item, any ring good_item" ..
        ", any ring w:150 / any magical staff / trident good_item" ..
        "    / demon trident w:5 / glaive good_item w:5 / nothing w:180" ..
        ", any ring w:60 / hat good_item w:20 / buckler good_item w:20" ..
        "    / kite shield good_item / tower shield good_item / any wand w:20" ..
        "    / any misc / gold / any scroll / any potion / nothing w:180")
end

-- The Felid leaves training or magic rewards rather than armour.
local function felid_transmuter(api)
    place_remains(api, "P", "felid skeleton",
        "randbook disc:transmutation / book of changes" ..
        "    / book of transfigurations" ..
        ", any jewellery good_item w:60 / manual of transmutations" ..
        "    / manual of unarmed combat / manual of fighting" ..
        ", any wand w:20 / any misc / gold / any scroll / any potion" ..
        "    / nothing w:60" ..
        ", any wand w:20 / any misc / gold / any scroll / any potion" ..
        "    / nothing w:60")
end

-- The Warper leaves translocation gear and a possible launcher.
local function kobold_warper(api)
    place_remains(api, "Q", "kobold skeleton",
        "randbook disc:translocation / book of spatial translocations" ..
        "    / book of the warp" ..
        ", scroll of blinking / scroll of teleportation q:2" ..
        "    / boomerang ego:dispersal" ..
        ", dagger good_item / short sword good_item / rapier good_item" ..
        "    / long sword good_item / double sword / demon blade" ..
        "    / sling randart / hand crossbow good_item" ..
        "    / shortbow randart / arbalest good_item / triple crossbow" ..
        "    / any armour good_item / nothing w:130" ..
        ", buckler good_item / kite shield good_item / " .. loot.GOOD_AUX_ARMOUR ..
        "    / any wand w:20 / any misc / gold / any scroll / any potion" ..
        "    / nothing w:140")
end

-- The source calls these in glyph order before the MAP is placed.
-- Every corpse receives its own sight-trigger record.
function module.setup(api)
    dwarven_fighter(api)
    minotaur_hunter(api)
    spriggan_stabber(api)
    merfolk_gladiator(api)
    orc_fighter(api)
    ogre_caster(api)
    human_wanderer(api)
    elf_caster(api)
    dwarf_artificer(api)
    octopode(api)
    felid_transmuter(api)
    kobold_warper(api)
end

return module
