-- Flay stores only HP that was actually removed. Its saved victim record
-- lets later ghost death or expiry heal without replaying the original hit.
-- Source: mon-cast.cc:_flay, mon-ench.cc:ENCH_FLAYED, mon-death.cc.
local catalog = require("policy.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local causes = require("constants.damage_causes")
local display = require("policy.combat.monster_support.display")
local holiness = require("constants.monster_holiness")
local life = require("policy.combat.life_transfer")
local monster_health = require("policy.combat.monster_health")
local monsters = require("ids.monsters")
local player_holiness = require("policy.character.holiness")
local player_health = require("policy.combat.player_health")
local senses = require("policy.character.senses")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local flay = {}
local SIGHT_RADIUS = 7
local PLAYER_MIN_AUT = 55
local PLAYER_VARIANCE_AUT = 66
local MONSTER_MIN_AUT = 30
local MONSTER_VARIANCE_AUT = 50
local MONSTER_MAX_AUT = 150
local PLAYER_GHOST_FLOOR_AUT = 80
local PLAYER_GHOST_EXTENSION = 50

-- Flay affects natural life, not undead, plants, or constructs. The
-- player's current form can change that answer after character creation.
function flay.natural(ctx, target)
    if ctx:has(target, component.PLAYER) then
        return player_holiness.natural(ctx, target)
    end

    local actor = ctx:get(target, component.ACTOR)

    if not actor then
        return false
    end

    local definition = catalog.get("monsters", actor.kind_id)

    for _, kind in ipairs(definition.holiness or {}) do
        if kind == holiness.NATURAL then
            return true
        end
    end

    return false
end

-- A dead or healed victim cannot gain temporary flay wounds. Source damage
-- is a quarter of current HP minus one, so it cannot itself be lethal.
function flay.damage_amount(ctx, target)
    local health = ctx:get(target, component.HEALTH)

    if not health or health.current <= 0 then
        return 0
    end

    return math.max(0, math.floor(health.current / 4) - 1)
end

-- The health owner applies mitigation, reactions, and death rules. Record
-- only its returned HP loss; otherwise recovery could create extra HP.
local function hurt(ctx, caster, target, amount)
    if ctx:has(target, component.PLAYER) then
        local _, dealt = player_health.damage(ctx, target,
            amount, false, caster, causes.FLAY)

        return dealt
    end

    local _, dealt = monster_health.damage(ctx, target,
        amount, caster, causes.FLAY)

    return dealt
end

-- Repeated player flays keep the longer current timer; monster flays add
-- duration up to the source cap. Both accumulate actual removed HP.
local function duration(ctx, target, previous)
    if ctx:has(target, component.PLAYER) then
        local rolled = PLAYER_MIN_AUT +
            ctx:random(streams.MONSTER_SPELL, PLAYER_VARIANCE_AUT)

        return math.max(previous, rolled)
    end

    local added = MONSTER_MIN_AUT +
        ctx:random(streams.MONSTER_SPELL, MONSTER_VARIANCE_AUT)

    return math.min(MONSTER_MAX_AUT, previous + added)
end

-- A spell may call this after checking its saved target plan. The record
-- stays on the original victim even if another ghost later attacks it.
function flay.apply(ctx, caster, target)
    local amount = flay.damage_amount(ctx, target)

    if amount == 0 or not flay.natural(ctx, target) then
        return 0
    end

    local state = ctx:get(target, component.MONSTER_FLAYED)
    local had_state = state ~= nil
    local was_flayed = had_state and state.remaining_aut > 0

    state = state or {
        source = caster,
        remaining_aut = 0,
        recoverable_hp = 0,
    }

    state.remaining_aut = duration(ctx, target, state.remaining_aut)

    local dealt = hurt(ctx, caster, target, amount)

    state.recoverable_hp = state.recoverable_hp + dealt

    if had_state then
        ctx:set(target, component.MONSTER_FLAYED, state)
    else
        ctx:add(target, component.MONSTER_FLAYED, state)
    end

    if ctx:has(target, component.PLAYER) then
        ctx:emit(channels.SPELL,
            was_flayed and
                "Terrible wounds spread across more of your body!" or
                "Terrible wounds open up all over your body!")
    elseif senses.player_sees_actor(ctx, target) then
        ctx:emit(channels.SPELL,
            "Terrible wounds open up all over the " ..
            display.name(ctx, target) .. "!")
    end

    return dealt
end

-- Source healing never exceeds current missing HP, even if ordinary
-- healing occurred since the flay. Removing the record also ends its timer.
function flay.recover(ctx, target)
    local state = ctx:get(target, component.MONSTER_FLAYED)

    if not state then
        return 0
    end

    local gained = life.heal(ctx, target, state.recoverable_hp)

    ctx:remove(target, component.MONSTER_FLAYED)

    return gained
end

-- A visible hostile flayed ghost suspends decay. Other monsters with the
-- same spell do not keep the wounds open merely by being nearby.
local function ghost_visible(ctx, victim)
    local position = ctx:get(victim, component.POSITION)

    if not position then
        return false
    end

    for _, ghost in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        local actor = ctx:get(ghost, component.ACTOR)

        if actor.kind_id == monsters.MONS_FLAYED_GHOST and
            not targets.aligned(ctx, ghost, victim) then
            local health = ctx:get(ghost, component.HEALTH)
            local site = ctx:get(ghost, component.POSITION)

            if health.current > 0 and
                site.level_id == position.level_id and
                ctx:visible(position.level_id, position.x, position.y,
                    SIGHT_RADIUS, site.x, site.y) then
                return true
            end
        end
    end

    return false
end

-- Preserve the source player's short-duration replenishment while a ghost
-- remains visible; monsters simply pause enchantment decay in that case.
local function sustain_player(ctx, remaining, elapsed_aut)
    if remaining >= PLAYER_GHOST_FLOOR_AUT or elapsed_aut <= 0 then
        return remaining
    end

    local whole = math.floor(PLAYER_GHOST_EXTENSION / elapsed_aut)
    local remainder = PLAYER_GHOST_EXTENSION % elapsed_aut

    if remainder > 0 and
        ctx:random(streams.MONSTER_SPELL, elapsed_aut) < remainder then
        whole = whole + 1
    end

    return remaining + whole
end

-- Age on the victim's own action. Expiry heals exactly the stored wound,
-- while seeing a hostile ghost keeps it available for later recovery.
function flay.tick(ctx, victim, elapsed_aut)
    local state = ctx:get(victim, component.MONSTER_FLAYED)

    if not state then
        return
    end

    if ghost_visible(ctx, victim) then
        if ctx:has(victim, component.PLAYER) then
            state.remaining_aut = sustain_player(ctx,
                state.remaining_aut, elapsed_aut)
            ctx:set(victim, component.MONSTER_FLAYED, state)
        end

        return
    end

    state.remaining_aut = math.max(0,
        state.remaining_aut - elapsed_aut)

    if state.remaining_aut == 0 then
        flay.recover(ctx, victim)
    else
        ctx:set(victim, component.MONSTER_FLAYED, state)
    end
end

-- Ghost death releases all enemies' wounds, as the source does, rather
-- than only wounds attributed to this particular ghost.
function flay.release_for_ghost(ctx, ghost)
    local actor = ctx:get(ghost, component.ACTOR)

    if not actor or actor.kind_id ~= monsters.MONS_FLAYED_GHOST then
        return
    end

    for _, victim in ipairs(ctx:query({ component.MONSTER_FLAYED })) do
        if not targets.aligned(ctx, ghost, victim) then
            flay.recover(ctx, victim)
        end
    end
end

return flay
