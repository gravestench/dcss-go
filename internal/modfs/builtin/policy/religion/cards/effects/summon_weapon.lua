-- Summon Weapon first places one friendly dancing actor, then equips its
-- source-tier weapon. The ordinary dancing owner builds ghost combat stats
-- and ties the item to summon expiry; this card owns only the item roll.
local cards = require("ids.cards")
local component = require("constants.component")
local constructs = require("policy.combat.monster_summons.dancing_weapons")
local items = require("ids.items")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.cards.effects.summons")
local brands = require("constants.weapon_brands")

local summon_weapon = {}

summon_weapon.uses_tier = true

local kinds = {
    {
        items.WPN_QUARTERSTAFF,
        items.WPN_HAND_AXE,
    },
    {
        items.WPN_LONG_SWORD,
        items.WPN_TRIDENT,
    },
    {
        items.WPN_DEMON_TRIDENT,
        items.WPN_EXECUTIONERS_AXE,
    },
}

local brand_sets = {
    {
        brands.VENOM,
        brands.NORMAL,
    },
    {
        brands.FLAMING,
        brands.FREEZING,
    },
    {
        brands.SPEED,
        brands.ELECTROCUTION,
    },
}

-- Tier zero and two always draw a brand; tier one first flips a coin for
-- whether the weapon is elemental at all. All these rolls use card RNG.
local function brand(ctx, tier)
    if tier == 1 and ctx:random(streams.CARDS, 2) ~= 0 then
        return brands.NORMAL
    end

    local choices = brand_sets[tier + 1]

    return choices[ctx:random(streams.CARDS, #choices) + 1]
end

-- Build one complete source item choice before touching an ECS entity.
-- A failed placement still spends the card but leaves no orphaned weapon.
local function choice(ctx, tier)
    local options = kinds[tier + 1]
    local plus

    if tier == 0 then
        plus = ctx:random(streams.CARDS, 3) - 2
    elseif tier == 1 then
        plus = ctx:random(streams.CARDS, 4) - 1
    else
        plus = ctx:random(streams.CARDS, 4) + 2
    end

    return {
        kind_id = options[ctx:random(streams.CARDS, #options) + 1],
        plus = plus,
        ego = brand(ctx, tier),
        randart = ctx:random(streams.CARDS, 3) == 0,
    }
end

-- Source sets abjuration degree two through four and scales the dancing
-- body with card power / 4. Failure to place yields smoke, as in decks.cc.
function summon_weapon.apply(ctx, player, request)
    local tier = request.tier

    if type(tier) ~= "number" or tier % 1 ~= 0 or
        tier < 0 or tier > 2 then
        error("Summon Weapon requires a source power tier")
    end

    local creature = summons.friendly(ctx, player,
        cards.SUMMON_WEAPON, monsters.MONS_DANCING_WEAPON,
        tier + 2)

    if not creature then
        ctx:emit("religion", "You see a puff of smoke.")

        return
    end

    local selected = choice(ctx, tier)

    constructs.equip_card(ctx, creature, selected,
        request.power)
end

return summon_weapon
