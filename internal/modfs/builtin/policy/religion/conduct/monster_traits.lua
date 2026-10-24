-- Theory of operation: source monster conduct reads the resolved monster
-- profile rather than maintaining a second list of rewardable creatures.
-- Spellbooks and attack flavours contribute to evil, unclean, and chaotic
-- identity; exceptional source species are named here beside the rule.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local flavours = require("constants.attack_flavours")
local flags = require("constants.monster_flags")
local component = require("constants.component")
local gods = require("constants.gods")
local holiness = require("constants.monster_holiness")
local monsters = require("ids.monsters")
local books = require("ids.monster_spellbooks")
local spell_flags = require("constants.spell_flags")
local schools = require("constants.spell_schools")

local traits = {}

-- Imported source fields are lists. Keep membership checks independent of
-- order so mod overlays can replace a profile without changing conduct.
local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- A creature can have several contact flavours. Zin and the good gods
-- care about any one of them, even if it is not the first attack slot.
local function attacks_with(definition, wanted)
    for _, attack in ipairs(definition.attacks or {}) do
        if attack.flavour_id == wanted then
            return true
        end
    end

    return false
end

-- Monster spell conduct uses the same registered spells as casting. A slot
-- only contributes when the monster has a real source spellbook.
local function spells_with(definition, predicate)
    if not definition.spellbook_id or
        definition.spellbook_id == books.MST_NO_SPELLS then
        return false
    end

    local book = catalog.get(categories.MONSTER_SPELLBOOKS,
        definition.spellbook_id)

    for _, slot in ipairs(book.slots or {}) do
        local spell = catalog.get(categories.SPELLS, slot.spell_id)

        if predicate(spell) then
            return true
        end
    end

    return false
end

local evil_gods = {
    [gods.KIKUBAAQUDGHA] = true,
    [gods.MAKHLEB] = true,
    [gods.YREDELEMNUL] = true,
    [gods.BEOGH] = true,
    [gods.LUGONU] = true,
    [gods.DITHMENOS] = true,
    [gods.NAMELESS] = true,
}

local priest_patron = {
    [monsters.MONS_SPRIGGAN_BERSERKER] = gods.TROG,
    [monsters.MONS_DEATH_KNIGHT] = gods.YREDELEMNUL,
    [monsters.MONS_ASTERION] = gods.MAKHLEB,
    [monsters.MONS_SERAPH] = gods.SHINING_ONE,
    [monsters.MONS_DRACONIAN_STORMCALLER] = gods.QAZLAL,
    [monsters.MONS_DEMONSPAWN_BLOOD_SAINT] = gods.MAKHLEB,
    [monsters.MONS_DEMONSPAWN_BLACK_SUN] = gods.KIKUBAAQUDGHA,
    [monsters.MONS_DEMONSPAWN_CORRUPTER] = gods.LUGONU,
    [monsters.MONS_MLIOGLOTL] = gods.LUGONU,
    [monsters.MONS_MENNAS] = gods.ZIN,
}

local object_kinds = {
    [monsters.MONS_TWISTER] = true,
    [monsters.MONS_BALLISTOMYCETE_SPORE] = true,
    [monsters.MONS_LURKING_HORROR] = true,
    [monsters.MONS_DANCING_WEAPON] = true,
    [monsters.MONS_LIGHTNING_SPIRE] = true,
    [monsters.MONS_CREEPING_INFERNO] = true,
}

-- Source mons_is_object excludes conjured bodies and these exceptional
-- constructs from kill-based divine recovery, even if a mod gives XP.
function traits.object(definition)
    return object_kinds[definition.id] == true or
        contains(definition.flags, flags.CONJURED) or
        contains(definition.flags, flags.PROJECTILE) or
        contains(definition.flags, flags.AVATAR)
end

-- Source mon-place.cc gives priests either an explicit authored patron,
-- a species default, or the nameless god. This is only used when the
-- resolved spellbook actually marks the actor as a priest.
function traits.priest_god(ctx, monster, definition)
    local authored = ctx:get(monster, component.VAULT_ACTOR_OVERRIDES)

    if authored and authored.god_id ~= "" then
        return authored.god_id
    end

    if priest_patron[definition.id] then
        return priest_patron[definition.id]
    end

    if definition.genus_id == monsters.MONS_ORC then
        return gods.BEOGH
    elseif definition.genus_id == monsters.MONS_JELLY then
        return gods.JIYVA
    end

    return gods.NAMELESS
end

-- Source evil includes undeath and demons, necromantic or unholy spells,
-- draining or vampiric attacks, and priests of evil or unknown gods.
-- A priest of Zin or another non-evil patron is not evil merely for
-- having a priest spell slot.
function traits.evil(ctx, monster, definition, priest)
    local evil_priest = priest and
        evil_gods[traits.priest_god(ctx, monster, definition)] == true

    if contains(definition.holiness, holiness.UNDEAD) or
        contains(definition.holiness, holiness.DEMONIC) or evil_priest or
        attacks_with(definition, flavours.DRAIN) or
        attacks_with(definition, flavours.VAMPIRIC) then
        return true
    end

    return spells_with(definition, function(spell)
        return contains(spell.flags, spell_flags.UNHOLY) or
            (contains(spell.schools, schools.NECROMANCY) and
                not contains(spell.flags, spell_flags.NOT_EVIL))
    end)
end

local unclean_species = {
    [monsters.MONS_CRAZY_YIUF] = true,
    [monsters.MONS_PSYCHE] = true,
    [monsters.MONS_LOUISE] = true,
    [monsters.MONS_GASTRONOK] = true,
    [monsters.MONS_ANCIENT_ZYME] = true,
}

-- Source uncleanliness covers bodily corruption, theft, and spells that
-- violate Zin's order. Insubstantial undead have no corporeal form to spoil.
function traits.unclean(definition, wizard)
    if unclean_species[definition.id] or
        attacks_with(definition, flavours.DRAIN) or
        attacks_with(definition, flavours.STEAL) or
        attacks_with(definition, flavours.VAMPIRIC) or
        (contains(definition.holiness, holiness.UNDEAD) and
            not contains(definition.flags, flags.INSUBSTANTIAL)) then
        return true
    end

    return spells_with(definition, function(spell)
        return contains(spell.flags, spell_flags.UNCLEAN) or
            (wizard and contains(spell.flags, spell_flags.CHAOTIC))
    end)
end

local chaotic_species = {
    [monsters.MONS_UGLY_THING] = true,
    [monsters.MONS_VERY_UGLY_THING] = true,
    [monsters.MONS_ABOMINATION_SMALL] = true,
    [monsters.MONS_ABOMINATION_LARGE] = true,
    [monsters.MONS_WRETCHED_STAR] = true,
    [monsters.MONS_KILLER_KLOWN] = true,
    [monsters.MONS_TIAMAT] = true,
    [monsters.MONS_BAI_SUZHEN] = true,
    [monsters.MONS_BAI_SUZHEN_DRAGON] = true,
}

-- Source shapeshifter identity follows genus so a changed creature still
-- reports its real kind. Knownness is a separate live flag in later slices.
function traits.shapeshifter(definition)
    return definition.genus_id == monsters.MONS_SHAPESHIFTER
end

-- Zin counts changing forms, chaotic strikes, and chaotic spells. The
-- imported profile contains the inherent cases; live polymorph state can
-- add a further fact without changing this catalog rule.
function traits.chaotic(definition)
    if chaotic_species[definition.id] or
        definition.genus_id == monsters.MONS_DEMONSPAWN or
        traits.shapeshifter(definition) or
        attacks_with(definition, flavours.MUTATE) or
        attacks_with(definition, flavours.CHAOTIC) then
        return true
    end

    return spells_with(definition, function(spell)
        return contains(spell.flags, spell_flags.CHAOTIC)
    end)
end

return traits
