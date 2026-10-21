-- Theory of operation: Davey Jones splits its living and spectral guards
-- with the authored DES shuffle. The first hook supplies weighted, branded
-- merfolk weapons; the second leaves old skeletons and ghost-vault metadata.
-- Generic ghost identity still comes from the live monster catalog.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")

local handler = {}

-- Expand the source dgn.monster_weapon tables into DES equipment choices.
-- Source dungeon.lua accidentally forwards an undefined quality variable;
-- use the source caller's one-in-three quality choice as intended here.
local function equip_merfolk(api)
    local quality = api:one_in(3) and "randart" or "good_item"

    api:emit(directives.KMONS,
        "F = merfolk ; spear ego:draining w:10 | " ..
        "trident ego:draining w:10 | halberd ego:draining w:5 | " ..
        "glaive ego:draining w:5 . throwing net w:3 | nothing w:9")

    api:emit(directives.KMONS,
        "3 = merfolk aquamancer ; rapier " .. quality ..
        " ego:electrocution w:20 | quick blade " .. quality ..
        " ego:electrocution w:5 . robe good_item")

    api:emit(directives.KMONS,
        "4 = merfolk impaler ; trident " .. quality ..
        " ego:draining w:15 | demon trident " .. quality ..
        " ego:draining w:5 . robe good_item | leather armour good_item")
end

-- The source ghost_setup selection tags and 10% chance are static DES
-- declarations because the catalog must know them before drawing a vault.
-- Only the source's delayed skeleton effect belongs at this script site.
local function configure_ghost(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "-",
        alternatives = "minotaur skeleton / elf skeleton / dwarf skeleton / " ..
            "human skeleton / kobold skeleton / felid skeleton / " ..
            "orc skeleton / ogre skeleton",
    })
end

handler.equip_merfolk = equip_merfolk
handler.configure_ghost = configure_ghost

return handler
