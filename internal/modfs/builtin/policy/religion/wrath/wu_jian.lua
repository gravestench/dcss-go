-- Wu Jian's wrath surrounds the player with enchanted dancing weapons.
-- Only a successful arrival triggers the second, four-way punishment.
local barbs = require("policy.combat.barbs")
local brands = require("constants.weapon_brands")
local channels = require("constants.message_channels")
local component = require("constants.component")
local corrosion = require("policy.combat.player_corrosion")
local gods = require("constants.gods")
local items = require("ids.items")
local monsters = require("ids.monsters")
local slow = require("policy.character.slow")
local statuses = require("policy.magic.effects.statuses.player")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.wrath.summons")
local weapons = require("policy.combat.monster_summons.dancing_weapons")

local wu_jian = {}

-- Keep the source random_choose order: each attempted weapon draws a kind
-- and brand even when no neighboring cell can receive the summon.
local implements = {
    items.WPN_DIRE_FLAIL,
    items.WPN_QUARTERSTAFF,
    items.WPN_BROAD_AXE,
    items.WPN_GREAT_SWORD,
    items.WPN_RAPIER,
    items.WPN_GLAIVE,
}

local egos = {
    brands.VORPAL,
    brands.FLAMING,
    brands.FREEZING,
    brands.ELECTROCUTION,
    brands.SPEED,
}

-- Placement consumes its own source RNG. Only a placed actor receives the
-- final plus draw; its ghost body uses XL times 50/9 as in god-wrath.cc.
local function summon_weapons(ctx, player)
    local count = 3 + ctx:random(streams.CARDS, 3)
    local level = ctx:get(player, component.PROGRESSION).level
    local created = 0

    for _ = 1, count do
        local kind = implements[ctx:random(streams.CARDS,
            #implements) + 1]
        local ego = egos[ctx:random(streams.CARDS, #egos) + 1]
        local creature = summons.hostile(ctx, player, gods.WU_JIAN,
            monsters.MONS_DANCING_WEAPON)

        if creature then
            weapons.equip_wrath(ctx, creature, {
                kind_id = kind,
                ego = ego,
            }, math.floor(level * 50 / 9),
                ctx:get(player, component.POSITION).level_id)
            created = created + 1
        end
    end

    return created
end

-- The post-summon choice is made once, not once per weapon. Direct Barbs
-- and Slow writes intentionally bypass hit and spell duration arithmetic.
local function after_summon(ctx, player)
    local choice = ctx:random(streams.CARDS, 4)

    if choice == 0 then
        ctx:emit(channels.RELIGION,
            "Wu Jian says: Die by a thousand cuts!")
        barbs.set_duration(ctx, player,
            5 + ctx:random(streams.CARDS, 6))
    elseif choice == 1 then
        ctx:emit(channels.RELIGION,
            "Wu Jian whispers: Nowhere to run...")
        slow.set_duration(ctx, player,
            5 + ctx:random(streams.CARDS, 6))
    elseif choice == 2 then
        ctx:emit(channels.RELIGION,
            "Wu Jian whispers: These will loosen your tongue!")
        statuses.add_silence(ctx, player,
            5 + ctx:random(streams.CARDS, 11), 50)
    else
        ctx:emit(channels.RELIGION,
            "Wu Jian says: Suffer, mortal!")
        corrosion.corrode_equipment(ctx, player, "Wu Jian",
            streams.CARDS, channels.RELIGION, 2)
    end
end

-- Failed placement still counts as wrath and can mollify penance, but it
-- draws no post-summon choice and gives the player no secondary debuff.
function wu_jian.apply(ctx, player)
    if summon_weapons(ctx, player) > 0 then
        after_summon(ctx, player)
    else
        ctx:emit(channels.RELIGION,
            "Wu Jian's divine weapons fail to arrive.")
    end

    return true
end

return wu_jian
