-- Example: A rolled potion gift records quantity and charges before the item is created.
-- Source: ng-wanderer.cc. These are starting gifts, not a runtime item adapter.
local catalog = require("policy.catalog")
local equipment = require("policy.inventory.equipment")
local traits = require("policy.character.traits")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local skill_ids = require("ids.skills")
local item_ids = require("ids.items")
local categories = require("constants.catalog")
local classes = require("ids.object_classes")
local missile_brands = require("constants.missile_egos")
local weapon_brands = require("constants.weapon_brands")
local armour_egos = require("constants.armour_egos")
local undead_states = require("constants.undead_states")
local spells = require("policy.character.wanderer_spells")
local potion_rules = require("policy.character.potion_rules")
local item_sets = require("policy.item_generation.item_sets")
local set_ids = require("constants.item_sets")
local streams = require("constants.rng_streams")
local wanderer_ids = require("constants.wanderer")

local gifts = {}

-- DCSS Wanderer chooses a strong gift, a weaker gift and an extra consumable
-- from its rolled training. These tables map a skill to gear, then the rules
-- below reject gifts a species cannot use or that duplicate earlier gifts.

local weapon_for_skill = {
    [skill_ids.SK_AXES] = item_ids.WPN_HAND_AXE,
    [skill_ids.SK_MACES_FLAILS] = item_ids.WPN_MACE,
    [skill_ids.SK_RANGED_WEAPONS] = item_ids.WPN_SLING,
    [skill_ids.SK_POLEARMS] = item_ids.WPN_SPEAR,
    [skill_ids.SK_SHORT_BLADES] = item_ids.WPN_SHORT_SWORD,
    [skill_ids.SK_LONG_BLADES] = item_ids.WPN_FALCHION,
    [skill_ids.SK_STAVES] = item_ids.WPN_QUARTERSTAFF,
}

local upgrades = {
    [item_ids.WPN_HAND_AXE] = item_ids.WPN_WAR_AXE,
    [item_ids.WPN_MACE] = item_ids.WPN_FLAIL,
    [item_ids.WPN_SLING] = item_ids.WPN_SHORTBOW,
    [item_ids.WPN_SPEAR] = item_ids.WPN_TRIDENT,
    [item_ids.WPN_SHORT_SWORD] = item_ids.WPN_RAPIER,
    [item_ids.WPN_FALCHION] = item_ids.WPN_LONG_SWORD,
}

local auxiliary = {
    item_ids.ARM_HAT,
    item_ids.ARM_GLOVES,
    item_ids.ARM_BOOTS,
    item_ids.ARM_CLOAK,
}

-- The source uses a Wanderer subgenerator. A named persisted stream keeps
-- gift choices independent of ordinary character and item-set draws.
local function roll(ctx, bound)
    return ctx:random(streams.WANDERER, bound)
end

-- Normalize optional quantity, plus, ego, and charges before item creation.
local function grant(id, quantity, plus, ego, charges)
    return {
        kind_id = id,
        quantity = quantity or 1,
        plus = plus or 0,
        ego = ego or "",
        charges = charges or 0,
    }
end

-- Append normalized gifts in their draw order so occupied slots are resolved consistently.
local function add(grants, id, quantity, plus, ego, charges)
    grants[#grants + 1] = grant(id, quantity, plus, ego, charges)
end

-- All gift draws use the saved Wanderer RNG stream, including weighted
-- choices. A restored start must reproduce the same grants for the seed.
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

-- Filter gifts the species cannot use before weighting the remaining consumables.
local function consumable(ctx, species, good)
    local no_drink = not potion_rules.can_drink(ctx, ctx:player())
    local stasis = traits.stasis(species)
    local lifeless = species.undead_type == undead_states.UNDEAD
    local options

    if good then
        options = {
            {
                id = item_ids.SCR_FEAR,
                weight = 4,
            },
            {
                id = item_ids.SCR_SUMMONING,
                weight = 1,
            },
            {
                id = item_ids.SCR_BLINKING,
                weight = stasis and 0 or 4,
            },
            {
                id = item_ids.POT_HEAL_WOUNDS,
                weight = (no_drink or
                    not potion_rules.can_heal(ctx, ctx:player())) and 0 or 2,
            },
            {
                id = item_ids.POT_HASTE,
                weight = (no_drink or stasis) and 0 or 2,
            },
            {
                id = item_ids.POT_BERSERK_RAGE,
                weight = (stasis or lifeless) and 0 or 2,
            },
            {
                id = item_ids.POT_MIGHT,
                weight = no_drink and 0 or 1,
            },
            {
                id = item_ids.POT_BRILLIANCE,
                weight = no_drink and 0 or 1,
            },
            {
                id = item_ids.POT_INVISIBILITY,
                weight = no_drink and 0 or 1,
            },
        }
    else
        local conceal = item_sets.choice(ctx, ctx:player(),
            set_ids.CONCEALMENT_SCROLLS)
        options = {
            {
                id = item_ids.SCR_TELEPORTATION,
                weight = stasis and 0 or 6,
            },
            {
                id = conceal,
                weight = 6,
            },
            {
                id = item_ids.SCR_VULNERABILITY,
                weight = 2,
            },
            {
                id = item_ids.SCR_SILENCE,
                weight = 2,
            },
            {
                id = item_ids.POT_CURING,
                weight = no_drink and 0 or 5,
            },
            {
                id = item_ids.POT_LIGNIFY,
                weight = lifeless and 0 or 5,
            },
            {
                id = item_ids.POT_ATTRACTION,
                weight = lifeless and 0 or 5,
            },
            {
                id = item_ids.POT_MUTATION,
                weight = lifeless and 0 or 1,
            },
        }
    end

    return grant(weighted(ctx, options))
end

-- Index one-based Lua lists from zero-based creation-stream draws.
local function random_from(ctx, ids)
    return ids[roll(ctx, #ids) + 1]
end

-- Source random2avg(16, 3) draws once below 16 and twice below 17.
-- This keeps the mean while narrowing the extremes without changing its
-- integer division or stream draw order.
local function average_sixteen(ctx)
    local total = roll(ctx, 16)

    total = total + roll(ctx, 17)
    total = total + roll(ctx, 17)

    return math.floor(total / 3)
end

-- A strong evoker gift chooses from higher-impact tools before charge calculation.
local function good_evoker(ctx, grants)
    if roll(ctx, 3) == 0 then
        local misc = {
            item_ids.MISC_BOX_OF_BEASTS,
            item_ids.MISC_PHIAL_OF_FLOODS,
            item_ids.MISC_PHANTOM_MIRROR,
            item_ids.MISC_CONDENSER_VANE,
            item_ids.MISC_TIN_OF_TREMORSTONES,
            item_ids.MISC_LIGHTNING_ROD,
        }

        add(grants, random_from(ctx, misc))
        return
    end

    local hex = item_sets.choice(ctx, ctx:player(), set_ids.HEX_WANDS)
    local blast = item_sets.choice(ctx, ctx:player(), set_ids.BLAST_WANDS)
    local beam = item_sets.choice(ctx, ctx:player(), set_ids.BEAM_WANDS)
    local id = random_from(ctx, {
        hex,
        item_ids.WAND_MINDBURST,
        item_ids.WAND_POLYMORPH,
        item_ids.WAND_FLAME,
        blast,
        beam,
    })
    local strong = {
        [item_ids.WAND_ACID] = true,
        [item_ids.WAND_LIGHT] = true,
        [item_ids.WAND_QUICKSILVER] = true,
        [item_ids.WAND_ICEBLAST] = true,
        [item_ids.WAND_ROOTS] = true,
    }
    local intense = {
        [item_ids.WAND_CHARMING] = true,
        [item_ids.WAND_PARALYSIS] = true,
        [item_ids.WAND_MINDBURST] = true,
    }
    local charges = 15

    if strong[id] then
        charges = 2 + roll(ctx, 3)
    elseif intense[id] then
        charges = 5 + average_sixteen(ctx)
    elseif id == item_ids.WAND_FLAME or id == item_ids.WAND_POLYMORPH then
        charges = 8 + average_sixteen(ctx)
    end

    add(grants, id, 1, 0, "", charges)
end

-- The weaker evoker path can give a chessboard or wand without the strong pool.
local function decent_evoker(ctx, grants)
    if roll(ctx, 3) == 0 then
        add(grants, item_ids.MISC_XOMS_CHESSBOARD)
        return
    end

    local id = roll(ctx, 2) == 0 and
        item_ids.WAND_FLAME or item_ids.WAND_POLYMORPH
    add(grants, id, 1, 0, "", 3 + roll(ctx, 5))
end

-- Pick a usable secondary armour slot not already occupied by an earlier gift.
local function aux_armour(ctx, species, grants, plus)
    local chosen
    local seen = 0

    for _, id in ipairs(auxiliary) do
        if equipment.can_wear(ctx, ctx:player(), species,
            catalog.get(categories.ITEMS, id)) then
            seen = seen + 1

            if roll(ctx, seen) == 0 then
                chosen = id
            end
        end
    end

    if chosen then
        -- The source chooses Hat for the reservoir but requests Helmet;
        -- the ordinary starting-gear owner adapts it for a hat-only body.
        local actual = chosen == item_ids.ARM_HAT and
            item_ids.ARM_HELMET or chosen

        add(grants, actual, 1, plus)
    end
end

-- A good weapon gift may upgrade or brand the skill's base item before slot assignment.
local function weapon(ctx, skill, good, grants)
    if skill == skill_ids.SK_THROWING then
        if good then
            add(grants, item_ids.MI_DART, 1 + roll(ctx, 4),
                0, missile_brands.CURARE)
        elseif roll(ctx, 3) == 0 then
            local count = 4 + 1 + roll(ctx, 3) + 1 + roll(ctx, 3)

            add(grants, item_ids.MI_BOOMERANG, count)
        else
            local count = 5 + 1 + roll(ctx, 5) + 1 + roll(ctx, 5)

            add(grants, item_ids.MI_DART, count,
                0, missile_brands.POISONED)
        end
    end

    local id = weapon_for_skill[skill] or item_ids.WPN_DAGGER
    local upgrade = good and roll(ctx, 5) == 0
    local ego = ""

    if upgrade then
        if id == item_ids.WPN_QUARTERSTAFF or id == item_ids.WPN_DAGGER then
            ego = weapon_brands.VORPAL
        else
            id = upgrades[id] or id
        end
    end

    add(grants, id, 1, good and not upgrade and 2 or 0, ego)
end

-- Replay the equipment owner's first-legal-slot rule over proposed gifts.
-- Fighting must upgrade the weapon the player will wield, not a later
-- carried weapon or one rejected by species anatomy.
local function equipped_weapon(ctx, species, grants)
    local shield = false

    for _, entry in ipairs(grants) do
        local kind = catalog.get(categories.ITEMS, entry.kind_id)

        if kind.slot == "shield" and
            equipment.can_wear(ctx, ctx:player(), species, kind) then
            shield = true
        end

        if kind.class == classes.OBJ_WEAPONS and
            equipment.can_wield(ctx, ctx:player(), species, kind) and
            (not shield or
                not equipment.needs_second_hand(ctx, ctx:player(),
                    kind, species)) then
            return entry
        end
    end

    return nil
end

-- The strong gift follows the selected skill. Fighting delegates to a
-- weighted weapon role because it does not identify one weapon family.
function gifts.good(ctx, species, skill, grants, weapon_roles)
    if skill == skill_ids.SK_FIGHTING then
        skill = weighted(ctx, weapon_roles)
    end

    if skill == skill_ids.SK_SPELLCASTING and
        mutation_levels.effective(ctx, ctx:player(),
            mutations.MUT_INNATE_CASTER) > 0 then
        skill = spells.djinni_skill(ctx)
    end

    if weapon_for_skill[skill] or skill == skill_ids.SK_THROWING then
        weapon(ctx, skill, true, grants)
    elseif skill == skill_ids.SK_ARMOUR then
        local id = roll(ctx, 2) == 0 and
            item_ids.ARM_SCALE_MAIL or item_ids.ARM_CHAIN_MAIL

        if not equipment.can_wear(ctx, ctx:player(), species,
            catalog.get(categories.ITEMS, id)) then
            id = item_ids.ARM_ACID_DRAGON_ARMOUR
        end

        add(grants, id, 1, id == item_ids.ARM_SCALE_MAIL and 2 or 0)
    elseif skill == skill_ids.SK_DODGING then
        local plus = roll(ctx, 2) == 0 and 2 or 0

        if equipment.can_wear(ctx, ctx:player(), species,
            catalog.get(categories.ITEMS, item_ids.ARM_LEATHER_ARMOUR)) then
            add(grants, item_ids.ARM_LEATHER_ARMOUR, 1, plus)
        else
            aux_armour(ctx, species, grants, plus)
        end

        if plus == 0 then
            add(grants, item_ids.MI_THROWING_NET, 2 + roll(ctx, 3))
        end
    elseif skill == skill_ids.SK_STEALTH then
        if roll(ctx, 2) == 0 then
            add(grants, item_ids.WPN_DAGGER, 1, 2)
            grants[#grants + 1] = consumable(ctx, species, true)
        else
            add(grants, item_ids.WPN_DAGGER)
            add(grants, item_ids.MI_DART, 1 + roll(ctx, 2),
                0, missile_brands.BLINDING)
            add(grants, item_ids.MI_DART, 1 + roll(ctx, 2),
                0, missile_brands.FRENZY)
        end
    elseif skill == skill_ids.SK_SHIELDS then
        if roll(ctx, 3) == 0 then
            add(grants, item_ids.ARM_BUCKLER, 1, 0, armour_egos.PROTECTION)
        else
            add(grants, item_ids.ARM_BUCKLER, 1, 2)
        end
    elseif skill == skill_ids.SK_UNARMED_COMBAT then
        grants[#grants + 1] = consumable(ctx, species, true)
        grants[#grants + 1] = consumable(ctx, species, true)
    elseif skill == skill_ids.SK_EVOCATIONS then
        good_evoker(ctx, grants)
    elseif spells.is_magic_skill(skill) then
        return skill, spells.gift(ctx, species, skill, true)
    end

    return skill, {}
end

-- The second gift first resolves incompatible or repeated skills. This
-- avoids giving unusable shields or redundant equipment after the good gift.
-- The weaker gift checks already received gear so a duplicate weapon can become a useful fallback.
function gifts.decent(ctx, species, skill, grants, received)
    local current_weapon = equipped_weapon(ctx, species, grants)
    local weapon_kind = current_weapon and
        catalog.get(categories.ITEMS, current_weapon.kind_id) or nil
    local occupied_hands = weapon_kind and
        equipment.needs_second_hand(ctx, ctx:player(), weapon_kind, species)

    if skill == skill_ids.SK_SHIELDS and
        (mutation_levels.effective(ctx, ctx:player(),
            mutations.MUT_MISSING_HAND) > 0 or
            received[skill_ids.SK_RANGED_WEAPONS] or occupied_hands) then
        skill = roll(ctx, 2) == 0 and
            skill_ids.SK_DODGING or skill_ids.SK_ARMOUR
    end

    if received[skill_ids.SK_SHIELDS] and
        (skill == skill_ids.SK_STAVES or skill == skill_ids.SK_RANGED_WEAPONS) then
        skill = skill_ids.SK_FIGHTING
    end

    if skill == skill_ids.SK_SPELLCASTING and
        mutation_levels.effective(ctx, ctx:player(),
            mutations.MUT_INNATE_CASTER) > 0 then
        skill = spells.djinni_skill(ctx)
    end

    local duplicate_armour = received[skill_ids.SK_ARMOUR] and
        (skill == skill_ids.SK_DODGING or
            skill == skill_ids.SK_STEALTH)
    local duplicate_dodge = received[skill_ids.SK_DODGING] and
        (skill == skill_ids.SK_ARMOUR or
            skill == skill_ids.SK_STEALTH)

    if received[skill] or duplicate_armour or duplicate_dodge then
        skill = wanderer_ids.NO_GIFT_SKILL
    end

    if weapon_for_skill[skill] or skill == skill_ids.SK_THROWING then
        weapon(ctx, skill, false, grants)
    elseif skill == skill_ids.SK_ARMOUR then
        local id = roll(ctx, 2) == 0 and
            item_ids.ARM_SCALE_MAIL or item_ids.ARM_RING_MAIL

        if equipment.can_wear(ctx, ctx:player(), species,
            catalog.get(categories.ITEMS, id)) then
            add(grants, id)
        else
            aux_armour(ctx, species, grants)
        end
    elseif skill == skill_ids.SK_SHIELDS then
        add(grants, item_ids.ARM_BUCKLER)
    elseif skill == skill_ids.SK_STEALTH or skill == skill_ids.SK_DODGING then
        aux_armour(ctx, species, grants)
    elseif skill == skill_ids.SK_EVOCATIONS then
        decent_evoker(ctx, grants)
    elseif skill == skill_ids.SK_FIGHTING then
        local current = equipped_weapon(ctx, species, grants)

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

-- The final consumable is chosen after both equipment gifts have settled.
function gifts.extra(ctx, species, grants)
    grants[#grants + 1] = consumable(ctx, species, roll(ctx, 2) == 0)
end

return gifts
