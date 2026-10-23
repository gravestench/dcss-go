-- Trog's physical punishments use saved stat, paralysis, and Slow owners.
-- Hostile berserk summons use the ordinary permanent god-summon owner.
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local avatar = require("policy.religion.wrath.avatar")
local attributes = require("policy.character.attributes")
local component = require("constants.component")
local gods = require("constants.gods")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local slow = require("policy.character.slow")
local stat_loss = require("policy.character.stat_loss")
local stats = require("constants.stats")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.wrath.summons")

local trog = {}

-- spl-summoning.cc consumes a duration draw before choosing a monster,
-- including permanent god-sourced wrath summons whose duration is zero.
local function summon_berserker(ctx, player, cost)
    local power = cost * 20
    ctx:random(streams.CARDS, power)

    local kind

    if power <= 100 then
        kind = ctx:random(streams.CARDS, 2) == 0 and
            monsters.MONS_BLACK_BEAR or monsters.MONS_POLAR_BEAR
    elseif power <= 140 then
        kind = ctx:random(streams.CARDS, 3) == 0 and
            monsters.MONS_TWO_HEADED_OGRE or monsters.MONS_OGRE
    elseif power <= 180 then
        local index = ctx:random(streams.CARDS, 8)

        kind = index < 3 and monsters.MONS_TROLL or
            index < 6 and monsters.MONS_DEEP_TROLL or
            monsters.MONS_IRON_TROLL
    else
        kind = ctx:random(streams.CARDS, 2) == 0 and
            monsters.MONS_CYCLOPS or monsters.MONS_STONE_GIANT
    end

    local creature = summons.hostile(ctx, player, gods.TROG, kind)

    if creature then
        allegiance.start_berserk(ctx, creature)
    end

    return creature ~= nil
end

-- Source random2avg takes two rolls. The quick reduction drops ten extra
-- points before replacing cost with a rounded half-level roll.
local function summon_cost(ctx, level, points)
    local bound = 1 + math.floor(level / 3)
    local first = ctx:random(streams.CARDS, bound)
    local second = ctx:random(streams.CARDS, bound)
    local cost = math.min(10,
        math.floor((first + second) / 2) + 3, points)

    if points > 20 and ctx:random(streams.CARDS, 2) == 0 then
        points = points - 10
        local half = math.floor(level / 2)

        if level % 2 > 0 and ctx:random(streams.CARDS, 2) == 0 then
            half = half + 1
        end

        cost = math.min(1 + half, 10)
    end

    return cost, points
end

-- Summon point spending is source ordered; successful placement affects
-- only the final message, not subsequent cost rolls.
local function send_berserkers(ctx, player, level)
    local points = 3 + level * 3
    local count = 0

    while points > 0 do
        local cost
        cost, points = summon_cost(ctx, level, points)
        points = points - cost

        if summon_berserker(ctx, player, cost) then
            count = count + 1
        end
    end

    ctx:emit("religion", count > 1 and
        "Trog sends monsters to punish you." or
        count == 1 and "Trog sends a monster to punish you." or
        "Trog has no time to punish you... now.")

    return true
end

-- The source's six cases are three Strength drains, one paralysis, and
-- two Slow outcomes. Paralysis returns false to suppress bonus debility.
local function physical(ctx, player)
    ctx:emit("religion", "Trog's voice booms out, \"Feel my wrath!\"")

    local choice = ctx:random(streams.CARDS, 6)

    if choice <= 2 then
        local strength = attributes.current(ctx, player).strength
        local bound = math.floor(strength / 5)
        local amount = 1

        if bound > 0 then
            amount = amount + ctx:random(streams.CARDS, bound)
        end

        stat_loss.drain(ctx, player, stats.STRENGTH, amount)
    elseif choice == 3 then
        if not ctx:has(player, component.PLAYER_PARALYSIS) then
            local turns = 2 + ctx:random(streams.CARDS, 6)

            ctx:add(player, component.PLAYER_PARALYSIS, {
                remaining_aut = math.min(turns, 13) * 10,
            })
            ctx:emit("warning", "You suddenly pass out!")
        end

        return false
    else
        ctx:emit("warning", "You suddenly feel lethargic!")
        slow.apply(ctx, player, 91 + ctx:random(streams.CARDS, 10))
    end

    return true
end

-- god-wrath.cc first chooses army versus direct wrath, then gives direct
-- wrath a two-in-three physical branch. Fireball uses the temporary avatar.
function trog.apply(ctx, player)
    local level = math.max(1,
        ctx:get(player, component.PROGRESSION).level)

    if ctx:random(streams.CARDS, 2) == 0 then
        return send_berserkers(ctx, player, level)
    end

    if ctx:random(streams.CARDS, 3) ~= 0 then
        return physical(ctx, player)
    end

    return avatar.cast(ctx, player, gods.TROG, spells.SPELL_FIREBALL,
        "Trog hurls fiery rage upon you!")
end

return trog
