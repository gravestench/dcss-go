-- Source: ng-wanderer.cc. These are starting gifts, not a runtime item adapter.
local catalog = require("policy.catalog")
local equipment = require("policy.inventory.equipment")
local traits = require("policy.character.traits")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local spells = require("policy.character.wanderer_spells")
local potion_rules = require("policy.character.potion_rules")

local gifts = {}

local weapon_for_skill = {
    SK_AXES = "WPN_HAND_AXE",
    SK_MACES_FLAILS = "WPN_MACE",
    SK_RANGED_WEAPONS = "WPN_SLING",
    SK_POLEARMS = "WPN_SPEAR",
    SK_SHORT_BLADES = "WPN_SHORT_SWORD",
    SK_LONG_BLADES = "WPN_FALCHION",
    SK_STAVES = "WPN_QUARTERSTAFF",
}

local upgrades = {
    WPN_HAND_AXE = "WPN_WAR_AXE",
    WPN_MACE = "WPN_FLAIL",
    WPN_SLING = "WPN_SHORTBOW",
    WPN_SPEAR = "WPN_TRIDENT",
    WPN_SHORT_SWORD = "WPN_RAPIER",
    WPN_FALCHION = "WPN_LONG_SWORD",
}

local auxiliary = {
    "ARM_HAT",
    "ARM_GLOVES",
    "ARM_BOOTS",
    "ARM_CLOAK",
}

local function roll(ctx, bound)
    return ctx:random("character", bound)
end

local function grant(id, quantity, plus, ego, charges)
    return {
        kind_id = id,
        quantity = quantity or 1,
        plus = plus or 0,
        ego = ego or "",
        charges = charges or 0,
    }
end

local function add(grants, id, quantity, plus, ego, charges)
    grants[#grants + 1] = grant(id, quantity, plus, ego, charges)
end

local function weighted(ctx, options)
    local total = 0

    for _, option in ipairs(options) do
        total = total + option.weight
    end

    local choice = roll(ctx, total)

    for _, option in ipairs(options) do
        if choice < option.weight then
            return option.id
        end

        choice = choice - option.weight
    end

    error("wanderer gift choice exhausted")
end

local function consumable(ctx, species, good)
    local no_drink = not potion_rules.can_drink(ctx, ctx:player())
    local stasis = traits.stasis(species)
    local lifeless = species.undead_type == "US_UNDEAD"
    local options

    if good then
        options = {
            {
                id = "SCR_FEAR",
                weight = 4,
            },
            {
                id = "SCR_SUMMONING",
                weight = 1,
            },
            {
                id = "SCR_BLINKING",
                weight = stasis and 0 or 4,
            },
            {
                id = "POT_HEAL_WOUNDS",
                weight = (no_drink or
                    not potion_rules.can_heal(ctx, ctx:player())) and 0 or 2,
            },
            {
                id = "POT_HASTE",
                weight = (no_drink or stasis) and 0 or 2,
            },
            {
                id = "POT_BERSERK_RAGE",
                weight = (stasis or lifeless) and 0 or 2,
            },
            {
                id = "POT_MIGHT",
                weight = no_drink and 0 or 1,
            },
            {
                id = "POT_BRILLIANCE",
                weight = no_drink and 0 or 1,
            },
            {
                id = "POT_INVISIBILITY",
                weight = no_drink and 0 or 1,
            },
        }
    else
        local conceal = roll(ctx, 2) == 0 and "SCR_FOG" or "SCR_BUTTERFLIES"
        options = {
            {
                id = "SCR_TELEPORTATION",
                weight = stasis and 0 or 6,
            },
            {
                id = conceal,
                weight = 6,
            },
            {
                id = "SCR_VULNERABILITY",
                weight = 2,
            },
            {
                id = "SCR_SILENCE",
                weight = 2,
            },
            {
                id = "POT_CURING",
                weight = no_drink and 0 or 5,
            },
            {
                id = "POT_LIGNIFY",
                weight = lifeless and 0 or 5,
            },
            {
                id = "POT_ATTRACTION",
                weight = lifeless and 0 or 5,
            },
            {
                id = "POT_MUTATION",
                weight = lifeless and 0 or 1,
            },
        }
    end

    return grant(weighted(ctx, options))
end

local function random_from(ctx, ids)
    return ids[roll(ctx, #ids) + 1]
end

local function average_sixteen(ctx)
    local total = 0

    for _ = 1, 3 do
        total = total + roll(ctx, 16)
    end

    return math.floor(total / 3)
end

local function good_evoker(ctx, grants)
    if roll(ctx, 3) == 0 then
        local misc = {
            "MISC_BOX_OF_BEASTS",
            "MISC_PHIAL_OF_FLOODS",
            "MISC_PHANTOM_MIRROR",
            "MISC_CONDENSER_VANE",
            "MISC_TIN_OF_TREMORSTONES",
            "MISC_LIGHTNING_ROD",
        }

        add(grants, random_from(ctx, misc))
        return
    end

    local hex = random_from(ctx, { "WAND_CHARMING", "WAND_PARALYSIS" })
    local blast = random_from(ctx, { "WAND_ICEBLAST", "WAND_ROOTS" })
    local beam = random_from(ctx, { "WAND_ACID", "WAND_LIGHT", "WAND_QUICKSILVER" })
    local id = random_from(ctx, {
        hex,
        "WAND_MINDBURST",
        "WAND_POLYMORPH",
        "WAND_FLAME",
        blast,
        beam,
    })
    local strong = {
        WAND_ACID = true,
        WAND_LIGHT = true,
        WAND_QUICKSILVER = true,
        WAND_ICEBLAST = true,
        WAND_ROOTS = true,
    }
    local intense = {
        WAND_CHARMING = true,
        WAND_PARALYSIS = true,
        WAND_MINDBURST = true,
    }
    local charges = 15

    if strong[id] then
        charges = 2 + roll(ctx, 3)
    elseif intense[id] then
        charges = 5 + average_sixteen(ctx)
    elseif id == "WAND_FLAME" or id == "WAND_POLYMORPH" then
        charges = 8 + average_sixteen(ctx)
    end

    add(grants, id, 1, 0, "", charges)
end

local function decent_evoker(ctx, grants)
    if roll(ctx, 3) == 0 then
        add(grants, "MISC_XOMS_CHESSBOARD")
        return
    end

    local id = roll(ctx, 2) == 0 and "WAND_FLAME" or "WAND_POLYMORPH"
    add(grants, id, 1, 0, "", 3 + roll(ctx, 5))
end

local function aux_armour(ctx, species, grants, plus)
    local chosen
    local seen = 0

    for _, id in ipairs(auxiliary) do
        if equipment.can_wear(ctx, ctx:player(), species,
            catalog.get("items", id)) then
            seen = seen + 1

            if roll(ctx, seen) == 0 then
                chosen = id
            end
        end
    end

    if chosen then
        add(grants, chosen, 1, plus)
    end
end

local function weapon(ctx, skill, good, grants)
    if skill == "SK_THROWING" then
        if good then
            add(grants, "MI_DART", 1 + roll(ctx, 4), 0, "curare")
        elseif roll(ctx, 3) == 0 then
            add(grants, "MI_BOOMERANG", 4 + 1 + roll(ctx, 3) + 1 + roll(ctx, 3))
        else
            add(grants, "MI_DART", 5 + 1 + roll(ctx, 5) + 1 + roll(ctx, 5),
                0, "poisoned")
        end
    end

    local id = weapon_for_skill[skill] or "WPN_DAGGER"
    local upgrade = good and roll(ctx, 5) == 0
    local ego = ""

    if upgrade then
        if id == "WPN_QUARTERSTAFF" or id == "WPN_DAGGER" then
            ego = "SPWPN_VORPAL"
        else
            id = upgrades[id] or id
        end
    end

    add(grants, id, 1, good and not upgrade and 2 or 0, ego)
end

local function last_weapon(grants)
    for index = #grants, 1, -1 do
        local entry = grants[index]
        local kind = catalog.get("items", entry.kind_id)

        if kind.class == "OBJ_WEAPONS" then
            return entry
        end
    end

    return nil
end

function gifts.good(ctx, species, skill, grants, weapon_roles)
    if skill == "SK_FIGHTING" then
        skill = weighted(ctx, weapon_roles)
    end

    if weapon_for_skill[skill] or skill == "SK_THROWING" then
        weapon(ctx, skill, true, grants)
    elseif skill == "SK_ARMOUR" then
        local id = roll(ctx, 2) == 0 and "ARM_SCALE_MAIL" or "ARM_CHAIN_MAIL"
        add(grants, id, 1, id == "ARM_SCALE_MAIL" and 2 or 0)
    elseif skill == "SK_DODGING" then
        local plus = roll(ctx, 2) == 0 and 2 or 0

        if equipment.can_wear(ctx, ctx:player(), species,
            catalog.get("items", "ARM_LEATHER_ARMOUR")) then
            add(grants, "ARM_LEATHER_ARMOUR", 1, plus)
        else
            aux_armour(ctx, species, grants, plus)
        end

        if plus == 0 then
            add(grants, "MI_THROWING_NET", 2 + roll(ctx, 3))
        end
    elseif skill == "SK_STEALTH" then
        if roll(ctx, 2) == 0 then
            add(grants, "WPN_DAGGER", 1, 2)
            grants[#grants + 1] = consumable(ctx, species, true)
        else
            add(grants, "WPN_DAGGER")
            add(grants, "MI_DART", 1 + roll(ctx, 2), 0, "blinding")
            add(grants, "MI_DART", 1 + roll(ctx, 2), 0, "frenzy")
        end
    elseif skill == "SK_SHIELDS" then
        if roll(ctx, 3) == 0 then
            add(grants, "ARM_BUCKLER", 1, 0, "SPARM_PROTECTION")
        else
            add(grants, "ARM_BUCKLER", 1, 2)
        end
    elseif skill == "SK_UNARMED_COMBAT" then
        grants[#grants + 1] = consumable(ctx, species, true)
        grants[#grants + 1] = consumable(ctx, species, true)
    elseif skill == "SK_EVOCATIONS" then
        good_evoker(ctx, grants)
    elseif spells.is_magic_skill(skill) then
        return skill, spells.gift(ctx, species, skill, true)
    end

    return skill, {}
end

function gifts.decent(ctx, species, skill, grants, received)
    local current_weapon = last_weapon(grants)
    local weapon_kind = current_weapon and
        catalog.get("items", current_weapon.kind_id) or nil
    local occupied_hands = weapon_kind and
        equipment.needs_second_hand(ctx, ctx:player(), weapon_kind, species)

    if skill == "SK_SHIELDS" and
        (mutation_levels.effective(ctx, ctx:player(),
            mutations.MUT_MISSING_HAND) > 0 or
            received.SK_RANGED_WEAPONS or occupied_hands) then
        skill = roll(ctx, 2) == 0 and "SK_DODGING" or "SK_ARMOUR"
    end

    if received.SK_SHIELDS and
        (skill == "SK_STAVES" or skill == "SK_RANGED_WEAPONS") then
        skill = "SK_FIGHTING"
    end

    if received[skill] or
        (received.SK_ARMOUR and (skill == "SK_DODGING" or skill == "SK_STEALTH")) or
        (received.SK_DODGING and (skill == "SK_ARMOUR" or skill == "SK_STEALTH")) then
        skill = "SK_NONE"
    end

    if weapon_for_skill[skill] or skill == "SK_THROWING" then
        weapon(ctx, skill, false, grants)
    elseif skill == "SK_ARMOUR" then
        local id = roll(ctx, 2) == 0 and "ARM_SCALE_MAIL" or "ARM_RING_MAIL"

        if equipment.can_wear(ctx, ctx:player(), species,
            catalog.get("items", id)) then
            add(grants, id)
        else
            aux_armour(ctx, species, grants)
        end
    elseif skill == "SK_SHIELDS" then
        add(grants, "ARM_BUCKLER")
    elseif skill == "SK_STEALTH" or skill == "SK_DODGING" then
        aux_armour(ctx, species, grants)
    elseif skill == "SK_EVOCATIONS" then
        decent_evoker(ctx, grants)
    elseif skill == "SK_FIGHTING" then
        local current = last_weapon(grants)

        if current then
            current.plus = (current.plus or 0) + 1
        else
            grants[#grants + 1] = consumable(ctx, species, false)
        end
    elseif spells.is_magic_skill(skill) then
        return skill, spells.gift(ctx, species, skill, false)
    else
        grants[#grants + 1] = consumable(ctx, species, false)
    end

    return skill, {}
end

function gifts.extra(ctx, species, grants)
    grants[#grants + 1] = consumable(ctx, species, roll(ctx, 2) == 0)
end

return gifts
