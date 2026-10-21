-- Theory of operation: a random Pandemonium lord is one generated creature,
-- not a species with a fixed stat block. Roll its body and spell slots once
-- on a named stream, then save the result on that actor. Combat and AI read
-- the saved profile; restoring a game never rerolls the lord.
-- Source: ghost.cc:ghost_demon::init_pandemonium_lord.
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local traits = require("constants.pan_lord_traits")
local brands = require("constants.weapon_brands")
local attacks = require("constants.monster_attack_types")

local pan_lord = {}

-- The source keeps each spell category separate. Choosing a spell from one
-- category must not make an unrelated category more likely.
local conjurations = {
    spells.SPELL_CALL_DOWN_DAMNATION,
    spells.SPELL_LEHUDIBS_CRYSTAL_SPEAR,
    spells.SPELL_CORROSIVE_BOLT,
    spells.SPELL_QUICKSILVER_BOLT,
    spells.SPELL_IOOD,
    spells.SPELL_ENERGY_BOLT,
    spells.SPELL_MINDBURST,
    spells.SPELL_BOLT_OF_FIRE,
    spells.SPELL_BOLT_OF_COLD,
    spells.SPELL_IRON_SHOT,
    spells.SPELL_POISON_ARROW,
    spells.SPELL_BOLT_OF_DRAINING,
    spells.SPELL_LIGHTNING_BOLT,
}

local area_conjurations = {
    spells.SPELL_SYMBOL_OF_TORMENT,
    spells.SPELL_FIRE_STORM,
    spells.SPELL_GLACIATE,
    spells.SPELL_CHAIN_LIGHTNING,
    spells.SPELL_FREEZING_CLOUD,
    spells.SPELL_POISONOUS_CLOUD,
    spells.SPELL_METAL_SPLINTERS,
    spells.SPELL_ENERGY_BOLT,
    spells.SPELL_ORB_OF_ELECTRICITY,
    spells.SPELL_CONJURE_BALL_LIGHTNING,
}

local self_enchantments = {
    spells.SPELL_HASTE,
    spells.SPELL_SILENCE,
    spells.SPELL_INVISIBILITY,
    spells.SPELL_BLINK,
    spells.SPELL_BLINK_RANGE,
}

local summons = {
    spells.SPELL_HAUNT,
    spells.SPELL_MALIGN_GATEWAY,
    spells.SPELL_SUMMON_DRAGON,
    spells.SPELL_SUMMON_HORRIBLE_THINGS,
    spells.SPELL_SUMMON_EYEBALLS,
    spells.SPELL_SUMMON_VERMIN,
}

local miscellaneous = {
    spells.SPELL_DISPEL_UNDEAD_RANGE,
    spells.SPELL_PARALYSE,
    spells.SPELL_SLEEP,
    spells.SPELL_MASS_CONFUSION,
    spells.SPELL_DRAIN_MAGIC,
    spells.SPELL_PETRIFY,
    spells.SPELL_POLYMORPH,
    spells.SPELL_FORCE_LANCE,
    spells.SPELL_SLOW,
    spells.SPELL_SENTINEL_MARK,
    spells.SPELL_DIMENSION_ANCHOR,
}

local noncaster_spells = {
    spells.SPELL_BLINKBOLT,
    spells.SPELL_BLINK_CLOSE,
    spells.SPELL_HARPOON_SHOT,
}

-- Keep profile generation independent of monster AI's later spell draws.
local function draw(ctx, bound)
    return ctx:random(streams.PAN_LORD, bound)
end

-- Source roll_dice adds one to every zero-based die.
local function dice(ctx, count, sides)
    local total = 0

    for _ = 1, count do
        total = total + draw(ctx, sides) + 1
    end

    return total
end

-- A true one-in-N branch consumes exactly one profile draw.
local function one_in(ctx, bound)
    return draw(ctx, bound) == 0
end

-- Source random2avg uses one [0,max) draw and two [0,max] draws.
local function average_three(ctx, maximum)
    local total = draw(ctx, maximum)

    for _ = 1, 2 do
        total = total + draw(ctx, maximum + 1)
    end

    return math.floor(total / 3)
end

-- Source biased_random2 chooses low values more often, including the
-- variable number of draws made before finding the selected split.
local function biased_split(ctx)
    for value = 0, 3 do
        if draw(ctx, 5 - value) < 2 then
            return value + 1
        end
    end

    return 1
end

-- Round a defense split stochastically so its two sides still sum to the
-- source total, even when the product is not divisible by ten.
local function rounded_tenth(ctx, product)
    local whole = math.floor(product / 10)
    local remainder = product % 10

    if remainder > 0 and draw(ctx, 10) < remainder then
        return whole + 1
    end

    return whole
end

-- Pick uniformly from a source category without sorting or registration
-- order influencing the result.
local function choose(ctx, choices)
    return choices[draw(ctx, #choices) + 1]
end

-- Weighted source tables keep their declaration order. One bounded draw
-- selects exactly one attack form or cloud ring from the original weights.
local function weighted(ctx, entries)
    local total = 0

    for _, entry in ipairs(entries) do
        total = total + entry.weight
    end

    local result = draw(ctx, total)

    for _, entry in ipairs(entries) do
        if result < entry.weight then
            return entry
        end

        result = result - entry.weight
    end

    error("Pan lord weighted draw exceeded its table")
end

-- Fire and cold have the same five source weights, including vulnerability.
-- Electricity has three weights. Save the signed levels on the actor.
local function resistance_rolls(ctx)
    local elemental = {
        {
            weight = 1,
            level = -1,
        },

        {
            weight = 3,
            level = 0,
        },

        {
            weight = 3,
            level = 1,
        },

        {
            weight = 2,
            level = 2,
        },

        {
            weight = 1,
            level = 3,
        },
    }
    local electric = {
        {
            weight = 3,
            level = 0,
        },

        {
            weight = 6,
            level = 1,
        },

        {
            weight = 1,
            level = 3,
        },
    }

    return {
        [traits.fire] = weighted(ctx, elemental).level,
        [traits.cold] = weighted(ctx, elemental).level,
        [traits.electricity] = weighted(ctx, electric).level,
    }
end

-- The first attack-type draw changes only the contact verb. A separate
-- weighted special form grants a weapon brand or a monster attack flavour.
local function attack_roll(ctx, spellcaster)
    local attack_type = attacks.HIT
    local flavour = traits.plain
    local brand = brands.NORMAL

    if one_in(ctx, 4) then
        attack_type = choose(ctx, traits.plain_attack_types)
    end

    if one_in(ctx, 3) or not spellcaster then
        local form = weighted(ctx, traits.special_attacks)

        brand = form.brand or brand
        flavour = form.flavour or flavour

        if brand == brands.VENOM and one_in(ctx, 2) then
            attack_type = attacks.STING
        elseif flavour == traits.trample then
            attack_type = attacks.TRAMPLE
        elseif flavour == traits.drown then
            attack_type = attacks.ENGULF
        end
    end

    return attack_type, flavour, brand
end

-- A branded lord has a matching ring; otherwise the source draws from its
-- weighted cloud family. The saved ring ID determines which cloud the
-- active monster system surrounds the lord with on each later action.
local function cloud_ring(ctx, brand, flavour)
    if brand == brands.ELECTROCUTION then
        return traits.ring_thunder
    elseif brand == brands.FLAMING then
        return traits.ring_flames
    elseif brand == brands.CHAOS then
        return traits.ring_chaos
    elseif brand == brands.FREEZING then
        return traits.ring_ice
    elseif flavour == traits.corrode then
        return traits.ring_acid
    elseif brand == brands.DRAINING then
        return traits.ring_draining
    end

    return weighted(ctx, traits.random_rings).id
end

-- Source ghost spell slots start at zero frequency. Divide the HD-derived
-- casting budget equally after all source branches have added their slots.
local function spell_slots(ctx, spellcaster, hd, friendly,
    brand, flavour, ring_id)
    local selected = {}

    if spellcaster then
        if not one_in(ctx, 10) then
            selected[#selected + 1] = choose(ctx, conjurations)
        end

        if not one_in(ctx, 10) then
            if one_in(ctx, 2) then
                if one_in(ctx, 2) then
                    selected[#selected + 1] = choose(ctx, {
                        spells.SPELL_SUMMON_DEMON,
                        spells.SPELL_SUMMON_GREATER_DEMON,
                    })
                else
                    selected[#selected + 1] = choose(ctx, summons)

                    if one_in(ctx, 2) then
                        selected[#selected + 1] =
                            spells.SPELL_BLINK_ALLIES_ENCIRCLE
                    end
                end
            else
                selected[#selected + 1] = choose(ctx, area_conjurations)

                if not friendly and one_in(ctx, 7) then
                    ring_id = cloud_ring(ctx, brand, flavour)
                end
            end
        end

        if one_in(ctx, 2) then
            selected[#selected + 1] = choose(ctx, self_enchantments)
        end

        if one_in(ctx, 2) then
            selected[#selected + 1] = choose(ctx, miscellaneous)
        end
    elseif one_in(ctx, 3) then
        selected[#selected + 1] = choose(ctx, noncaster_spells)
    end

    local frequencies = {}

    if #selected > 0 then
        local total = hd + 50

        if not spellcaster then
            total = math.floor(total / 3)
        end

        local each = math.floor(total / #selected)

        for index = 1, #selected do
            frequencies[index] = each
        end
    end

    return selected, frequencies, ring_id
end

-- Roll the source body before creating an ECS actor. A failed placement can
-- discard this value without leaving a half-built creature in the world.
function pan_lord.roll(ctx, friendly)
    local spellcaster = draw(ctx, 4) < 3
    local hp = 100 + dice(ctx, 3, 50)
    local total_defense = 10 + average_three(ctx, 40)
    local split = biased_split(ctx)
    local ac = rounded_tenth(ctx, total_defense * split)
    local ev = total_defense - ac

    if one_in(ctx, 2) then
        ac, ev = ev, ac
    end

    local resistances = resistance_rolls(ctx)
    local damage = 20 + dice(ctx, 2, 20)
    local flies = draw(ctx, 3) < 2
    local hd = 10 + dice(ctx, 2, 10)

    if not spellcaster then
        hp = math.floor(hp * 3 / 2)
        ac = ac + 5
        ev = ev + 5
        damage = damage + 10
        hd = hd + 5
    end

    local attack_type_id, flavour_id, brand_id = attack_roll(ctx,
        spellcaster)
    local ring_id = traits.no_ring

    if not friendly and not spellcaster and one_in(ctx, 7) then
        ring_id = cloud_ring(ctx, brand_id, flavour_id)
    end

    local speed

    if not spellcaster then
        speed = 11 + dice(ctx, 2, 4)
    elseif one_in(ctx, 3) then
        speed = 10
    else
        speed = 8 + dice(ctx, 2, 5)
    end

    local spell_ids, frequencies

    spell_ids, frequencies, ring_id = spell_slots(ctx,
        spellcaster, hd, friendly, brand_id, flavour_id, ring_id)

    return {
        hp = hp,
        spellcaster = spellcaster,
        hd = hd,
        ac = ac,
        ev = ev,
        damage = damage,
        flies = flies,
        resistances = resistances,
        attack_type_id = attack_type_id,
        flavour_id = flavour_id,
        brand_id = brand_id,
        ring_id = ring_id,
        speed = speed,
        spell_ids = spell_ids,
        frequencies = frequencies,
    }
end

return pan_lord
