-- Throw Barbs leaves a saved wound that hurts its owner on movement.
-- Source: beam.cc, movement.cc, mon-act.cc, and player-reacts.cc.
local catalog = require("policy.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local health = require("policy.combat.monster_health")
local monsters = require("ids.monsters")
local player_health = require("policy.combat.player_health")
local zap_ids = require("policy.magic.effects.zaps.ids")
local streams = require("constants.rng_streams")

local barbs = {}
local AUT = 10

-- Throw Barbs uses the monster spell stream; direct melee contact passes
-- its melee stream so the two source actions do not share a draw sequence.
local function range(ctx, low, high, stream)
    return low + ctx:random(stream or streams.MONSTER_SPELL,
        high - low + 1)
end

-- Source allows a jelly to hold barbs even when its body is insubstantial;
-- other insubstantial monsters cannot keep the spikes lodged.
local function can_lodge(ctx, target)
    if ctx:has(target, component.PLAYER) then
        return true
    end

    local actor = ctx:get(target, component.ACTOR)
    local definition = actor and catalog.get("monsters", actor.kind_id)

    if not definition then
        return false
    end

    if definition.genus_id == monsters.MONS_JELLY then
        return true
    end

    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.INSUBSTANTIAL then
            return false
        end
    end

    return true
end

-- A landed, damaging hit starts or strengthens the target's barbs. Player
-- and monster durations differ in the source, but share one ECS record.
function barbs.lodge(ctx, source, target, damage, stream)
    if damage <= 0 or not can_lodge(ctx, target) then
        return false
    end

    local current = ctx:get(target, component.BARBS)
    local player = ctx:has(target, component.PLAYER)
    local state

    if player then
        local added = current and range(ctx, 2, 4, stream) or
            range(ctx, 4, 8, stream)

        state = {
            remaining_aut = current and
                math.min(12 * AUT, current.remaining_aut + added * AUT) or
                added * AUT,
            -- beam.cc assigns min(6, power++) back into power, so the
            -- source's postincrement leaves repeated hits at four.
            power = current and current.power or 4,
            source = source,
        }
        ctx:emit("combat", "The barbed spikes become lodged in your body.")
    else
        state = {
            remaining_aut = (current and current.remaining_aut or 0) +
                range(ctx, 5, 7, stream) * AUT,
            -- mon_enchant::operator+= stacks degree, capped at four.
            power = current and math.min(4, current.power + 1) or 1,
            source = source,
        }
    end

    if current then
        ctx:set(target, component.BARBS, state)
    else
        ctx:add(target, component.BARBS, state)
    end

    return true
end

-- Wu Jian writes DUR_BARBS directly. This replaces the timer without the
-- wound-strength increase or RNG of a physical Throw Barbs hit.
function barbs.set_duration(ctx, player, turns)
    local current = ctx:get(player, component.BARBS)
    local state = current or {
        remaining_aut = 0,
        power = 0,
        source = player,
    }

    state.remaining_aut = turns * AUT

    if current then
        ctx:set(player, component.BARBS, state)
    else
        ctx:add(player, component.BARBS, state)
    end
end

-- Two source dice are rolled independently; armour does not prevent a
-- lodged spike from tearing its victim during movement.
local function movement_damage(ctx, power)
    if power <= 0 then
        return 0
    end

    return range(ctx, 1, power) + range(ctx, 1, power)
end

-- Only a completed move triggers barbs. Player movement normally offsets
-- this action's duration decay; a one-in-three extraction roll can loosen
-- the spikes instead. Monster movement can shorten its enchantment.
function barbs.moved(ctx, actor, elapsed_aut)
    local state = ctx:get(actor, component.BARBS)

    if not state or state.remaining_aut <= 0 then
        return
    end

    if ctx:has(actor, component.PLAYER) then
        ctx:emit("combat", "The barbed spikes dig painfully into your body as you move.")
        player_health.damage(ctx, actor,
            movement_damage(ctx, state.power), false)

        if ctx:random(streams.MONSTER_SPELL, 3) == 0 then
            state.remaining_aut = math.max(0,
                state.remaining_aut - elapsed_aut)
        else
            state.remaining_aut = state.remaining_aut + elapsed_aut
        end
    else
        health.damage(ctx, actor,
            movement_damage(ctx, state.power * 2 + 2), state.source)

        if ctx:random(streams.MONSTER_SPELL, 2) == 0 then
            state.remaining_aut = state.remaining_aut - 1
        end
    end

    if state.remaining_aut <= 0 then
        ctx:remove(actor, component.BARBS)

        if ctx:has(actor, component.PLAYER) then
            ctx:emit("duration", "The barbed spikes snap loose.")
        end
    else
        ctx:set(actor, component.BARBS, state)
    end
end

-- Ordinary actions age the wound; moving players already received a
-- compensating duration increase unless an extraction attempt succeeded.
function barbs.tick(ctx, actor, elapsed_aut)
    local state = ctx:get(actor, component.BARBS)

    if not state then
        return
    end

    if ctx:has(actor, component.PLAYER) then
        local sleep = ctx:get(actor, component.PLAYER_SLEEP)
        local paralysis = ctx:get(actor, component.PLAYER_PARALYSIS)
        local petrification = ctx:get(actor,
            component.PLAYER_PETRIFICATION)
        local confusion = ctx:get(actor,
            zap_ids.component.PLAYER_CONFUSION)

        -- player-reacts.cc extracts spikes only when the player can act
        -- and is clear-headed; involuntary waits preserve the wound.
        if (sleep and sleep.remaining_aut > 0) or
            (paralysis and paralysis.remaining_aut > 0) or
            (petrification and petrification.petrified_aut > 0) or
            (confusion and confusion.remaining_aut > 0) then
            return
        end
    end

    state.remaining_aut = state.remaining_aut - elapsed_aut

    if state.remaining_aut <= 0 then
        ctx:remove(actor, component.BARBS)

        if ctx:has(actor, component.PLAYER) then
            ctx:emit("duration", "The barbed spikes snap loose.")
        end
    else
        ctx:set(actor, component.BARBS, state)
    end
end

return barbs
