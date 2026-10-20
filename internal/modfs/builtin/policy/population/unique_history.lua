-- Theory of operation: the player owns a saved record of named monsters
-- that have ever spawned in this run. Their actor can die, move, or be
-- removed while this claim remains. Vault and ambient placement consult
-- the same owner before placing another instance.
local catalog = require("policy.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local decisions = require("constants.pan_unique_decision")
local monsters = require("ids.monsters")
local history = {}

-- A catalog flag determines whether a monster consumes unique history;
-- mods can add a unique kind without changing a hardcoded ID switch.
function history.is_unique(kind_id)
    local definition = catalog.get("monsters", kind_id)

    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.UNIQUE then
            return true
        end
    end

    return false
end

-- Missing history is possible only while D:1 terrain is generated before
-- its player actor exists. No source unique placement happens on D:1.
function history.seen(ctx, kind_id)
    if not ctx.player then
        return false
    end

    local player = ctx:player()

    if not player then
        return false
    end

    local state = ctx:get(player, component.PLAYER_UNIQUE_HISTORY)

    return state and state.monsters[kind_id] or false
end

-- Record only after an actor has been placed successfully. A failed map
-- fit or malformed equipment request must never consume a unique claim.
function history.mark(ctx, kind_id)
    if not history.is_unique(kind_id) then
        return
    end

    local player = ctx:player()
    local state = ctx:get(player, component.PLAYER_UNIQUE_HISTORY)

    if not state then
        error("player unique history is missing")
    end

    if state.monsters[kind_id] then
        error("unique monster was already generated " .. kind_id)
    end

    state.monsters[kind_id] = true
    ctx:set(player, component.PLAYER_UNIQUE_HISTORY, state)
end

-- Ignacio's first successful Pan chance chooses one permanent allow/forbid
-- outcome. Reading it later consumes no RNG and survives save/restore.
function history.pan_state(ctx, kind_id)
    local player = ctx:player()
    local state = ctx:get(player, component.PLAYER_UNIQUE_HISTORY)

    return state and state.pan_states[kind_id] or nil
end

-- Commit the one-time Pan decision after its chance and coinflip rolls.
function history.set_pan_state(ctx, kind_id, decision)
    if decision ~= decisions.ALLOW and decision ~= decisions.FORBID then
        error("invalid Pan unique decision " .. tostring(decision))
    end

    local player = ctx:player()
    local state = ctx:get(player, component.PLAYER_UNIQUE_HISTORY)

    if not state or state.pan_states[kind_id] then
        error("Pan unique decision was already made " .. kind_id)
    end

    state.pan_states[kind_id] = decision
    ctx:set(player, component.PLAYER_UNIQUE_HISTORY, state)
end

-- A saved ID must name a current unique profile, not an ordinary monster
-- or arbitrary string injected into the player history map.
function history.validate(state)
    if not state or not state.monsters then
        error("player monster unique history is missing")
    end

    for kind_id, seen in pairs(state.monsters) do
        if not seen or not history.is_unique(kind_id) then
            error("invalid player monster unique history " .. kind_id)
        end
    end

    if not state.pan_states then
        error("player Pan unique history is missing")
    end

    for kind_id, decision in pairs(state.pan_states) do
        if kind_id ~= monsters.MONS_IGNACIO or
            (decision ~= decisions.ALLOW and
                decision ~= decisions.FORBID) then
            error("invalid player Pan unique decision " .. kind_id)
        end
    end
end

return history
