-- Beogh chooses smiting, a thrown weapon, or an orc army. The shared
-- hostile-summon path preserves permanent god attribution for the army.
local component = require("constants.component")
local constructs = require("policy.combat.monster_summons.dancing_weapons")
local gods = require("constants.gods")
local health = require("policy.combat.player_health")
local items = require("ids.items")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.wrath.summons")
local brands = require("constants.weapon_brands")

local beogh = {}

-- Source random_choose lists thirteen weapon subtypes in this order. The
-- shared dancing weapon owner attaches the item and derives combat stats.
local implements = {
    items.WPN_CLUB,
    items.WPN_MACE,
    items.WPN_FLAIL,
    items.WPN_MORNINGSTAR,
    items.WPN_DAGGER,
    items.WPN_SHORT_SWORD,
    items.WPN_LONG_SWORD,
    items.WPN_SCIMITAR,
    items.WPN_GREAT_SWORD,
    items.WPN_HAND_AXE,
    items.WPN_BATTLEAXE,
    items.WPN_SPEAR,
    items.WPN_HALBERD,
}

-- god-wrath.cc:_god_smites_you rolls 10–19 plus five level-sided draws.
-- Divine smiting bypasses ordinary armour but keeps player damage reactions.
local function smite(ctx, player, level)
    local amount = 10 + ctx:random(streams.CARDS, 10)

    for _ = 1, 5 do
        amount = amount + ctx:random(streams.CARDS, level)
    end

    ctx:emit("religion", "Beogh smites you!")
    health.damage(ctx, player, amount)
end

-- Source point thresholds select one increasingly dangerous orc leader.
-- The common summon owner gives it a durable hostile god source.
local function send_orcs(ctx, player, level)
    local points = level + 3 + ctx:random(streams.CARDS, level * 3)
    local kind

    if points >= 30 then
        kind = monsters.MONS_ORC_WARLORD
    elseif points >= 24 then
        kind = monsters.MONS_ORC_HIGH_PRIEST
    elseif points >= 18 then
        kind = monsters.MONS_ORC_KNIGHT
    elseif points > 10 then
        kind = monsters.MONS_ORC_WARRIOR
    else
        kind = monsters.MONS_ORC
    end

    local created = summons.hostile(ctx, player, gods.BEOGH, kind)

    ctx:emit("religion", created and
        "Beogh sends forth an army of orcs." or
        "Beogh is still gathering forces against you.")
end

-- One or two electrical weapons inherit Beogh's permanent hostile source.
-- A completely blocked placement follows the C++ fallthrough to orcs.
local function throw_weapons(ctx, player, level)
    local attempts = 1 + ctx:random(streams.CARDS, 2)
    local created = 0

    for _ = 1, attempts do
        local subtype = implements[ctx:random(streams.CARDS,
            #implements) + 1]
        local weapon = summons.hostile(ctx, player, gods.BEOGH,
            monsters.MONS_DANCING_WEAPON)

        if weapon then
            local power = 4 * math.floor(level * 50 / 9)

            constructs.equip_card(ctx, weapon, {
                kind_id = subtype,
                plus = ctx:random(streams.CARDS, 3),
                ego = brands.ELECTROCUTION,
            }, power)
            created = created + 1
        end
    end

    if created > 0 then
        ctx:emit("religion", created == 1 and
            "Beogh throws an implement of electrocution at you." or
            "Beogh throws implements of electrocution at you.")
    end

    return created > 0
end

-- Two of eight rolls smite. A follower-abandonment branch needs Beogh's
-- saved follower owner; non-followers proceed to the source orc branch.
function beogh.apply(ctx, player)
    local progression = ctx:get(player, component.PROGRESSION)
    local level = math.max(1, progression.level)
    local choice = ctx:random(streams.CARDS, 8)

    if choice <= 1 then
        smite(ctx, player, level)
    elseif choice == 2 then
        if not throw_weapons(ctx, player, level) then
            send_orcs(ctx, player, level)
        end
    elseif choice <= 4 and
        ctx:get(player, component.RELIGION_WORSHIP).god_id == gods.BEOGH then
        error("unimplemented Beogh follower abandonment wrath")
    else
        send_orcs(ctx, player, level)
    end

    return true
end

return beogh
