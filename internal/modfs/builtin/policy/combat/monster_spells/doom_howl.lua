-- A Doom Hound howls once at the player, creating a saved echo that calls
-- hostile monsters every two to four turns while the player continues.
-- Source: mon-cast.cc:_doom_howl and spl-summoning.cc:doom_howl.
local arrivals = require("policy.combat.monster_doom_howl.arrivals")
local component = require("constants.component")
local ids = require("policy.combat.monster_doom_howl.ids")
local target = require("policy.combat.monster_spell_target")
local target_kind = require("constants.target_kind")

local effect = {}
local MIN_DURATION = 120
local DURATION_SPAN = 61
local MIN_INTERVAL = 20
local INTERVAL_SPAN = 21

-- Source AI refuses a second howl from the same hound, a summoned hound,
-- or a target other than the player. A current echo also prevents overlap.
function effect.plan(ctx, caster, foe)
    if not foe or foe ~= ctx:player() or
        ctx:has(caster, component.SUMMON) or
        ctx:has(caster, ids.MONSTER_DOOM_HOWLED) or
        ctx:has(foe, ids.PLAYER_DOOM_HOWL) then
        return nil
    end

    return {
        kind = target_kind.ENTITY,
        entity = foe,
    }
end

-- One cast transfers the mutable echo to the player; the monster retains
-- only its one-use marker. The next-call draw waits for the first player
-- action, matching the source's lazy timer initialization.
function effect.resolve(ctx, caster, foe, _, plan)
    target.require_entity(plan, foe)

    ctx:add(caster, ids.MONSTER_DOOM_HOWLED, {
        used = true,
    })
    ctx:add(foe, ids.PLAYER_DOOM_HOWL, {
        remaining_aut = MIN_DURATION +
            ctx:random("monster_spell", DURATION_SPAN),
        next_call_aut = 0,
    })
    ctx:emit("spell", "A terrible howl begins to echo in your mind!")
end

-- Each player action ages the echo by its actual aut cost. Long actions
-- may cross several independent 20–40 aut calls; all are resolved before
-- the duration expires, and the countdown is saved between actions.
function effect.tick(ctx, player, elapsed_aut)
    local state = ctx:get(player, ids.PLAYER_DOOM_HOWL)

    if not state or elapsed_aut <= 0 then
        return
    end

    local time = math.min(elapsed_aut, state.remaining_aut)

    if state.next_call_aut <= 0 then
        state.next_call_aut = MIN_INTERVAL +
            ctx:random("monster_spell", INTERVAL_SPAN)
    end

    while time >= state.next_call_aut do
        time = time - state.next_call_aut
        arrivals.call(ctx, player)
        state.next_call_aut = MIN_INTERVAL +
            ctx:random("monster_spell", INTERVAL_SPAN)
    end

    state.next_call_aut = state.next_call_aut - time
    state.remaining_aut = state.remaining_aut -
        math.min(elapsed_aut, state.remaining_aut)

    if state.remaining_aut <= 0 then
        ctx:remove(player, ids.PLAYER_DOOM_HOWL)
        ctx:emit("duration", "The infernal howling subsides.")

        return
    end

    ctx:set(player, ids.PLAYER_DOOM_HOWL, state)
end

return effect
