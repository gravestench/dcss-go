-- Theory of operation: Wucad's source A marker owns a repeating monk
-- timer, while seven numbered cells each carry an independent one-shot
-- impression. The named statue's death permanently disables both. One
-- Akara component saves all three concerns so revisits cannot replay them.
local channels = require("constants.message_channels")
local component = require("constants.component")
local death_hooks = require("policy.combat.death_hooks")
local monsters = require("ids.monsters")
local silence = require("policy.world.silence")
local streams = require("constants.rng_streams")
local summons = require("policy.world.wizlab.events.summons")
local wizlab = require("constants.wizlab")

local wucad = {}

-- Exactly one of the seven source markers may speak when the player
-- enters it. A failed chance or Silence does not consume the marker.
local function visit_message(ctx, state, position)
    for index, x in ipairs(state.message_x) do
        local spot = state.message_spot[index]

        if x == position.x and state.message_y[index] == position.y and
            not state.message_done[spot] then
            if ctx:random(streams.WIZLAB_EVENTS,
                wizlab.WUCAD_MESSAGE_CHANCE_DENOMINATOR) == 0 then
                return false
            end

            if (spot == 4 or spot == 5) and silence.at(ctx,
                position.level_id, position.x, position.y) then
                return false
            end

            ctx:emit(channels.VAULT,
                wizlab.WUCAD_MESSAGE_TEXT[spot])
            state.message_done[spot] = true

            return true
        end
    end

    return false
end

-- The source circle scans cells in stable row order. The one-in-eight
-- draw is made before floor suitability, matching the original callback.
local function summon_monks(ctx, state, position)
    local count = 0
    local weights = {
        monsters.MONS_DEMONSPAWN,
        monsters.MONS_DEEP_TROLL,
        monsters.MONS_DRACONIAN_MONK,
        monsters.MONS_DRACONIAN_MONK,
        monsters.MONS_DRACONIAN_MONK,
        monsters.MONS_DRACONIAN_MONK,
        monsters.MONS_DRACONIAN_MONK,
    }

    for y = position.y - wizlab.WUCAD_MONK_RADIUS,
        position.y + wizlab.WUCAD_MONK_RADIUS do
        for x = position.x - wizlab.WUCAD_MONK_RADIUS,
            position.x + wizlab.WUCAD_MONK_RADIUS do
            local dx = x - position.x
            local dy = y - position.y

            if dx * dx + dy * dy <=
                wizlab.WUCAD_MONK_RADIUS * wizlab.WUCAD_MONK_RADIUS and
                count < wizlab.WUCAD_MONK_LIMIT and
                ctx:random(streams.WIZLAB_EVENTS,
                    wizlab.WUCAD_MONK_CELL_CHANCE_DENOMINATOR) == 0 and
                ctx:walkable(state.level_id, x, y) and
                not ctx:actor_at(state.level_id, x, y) then
                local kind = weights[ctx:random(streams.WIZLAB_EVENTS,
                    #weights) + 1]
                local actor = summons.place(ctx, state, state.monks_index,
                    kind, x, y, wizlab.WUCAD_MONK_DURATION_AUT,
                    wizlab.EVENT_ACTOR_WUCAD)

                if actor then
                    count = count + 1
                end
            end
        end
    end

    if count == 1 then
        ctx:emit(channels.WARNING,
            "One of the shadowy figures appears more solid!")
    elseif count > 1 then
        ctx:emit(channels.WARNING,
            "Shadows coalesce into solid form.")
    end
end

-- A long action may cross several countdowns. Save the next absolute
-- deadline after every callback, including one that found no free cells.
function wucad.tick(ctx, state, position, elapsed_aut, moved)
    if state.suppressed or state.level_id ~= position.level_id then
        return false
    end

    local changed = moved and visit_message(ctx, state, position) or false
    local now = ctx:aut() + elapsed_aut

    while now >= state.next_aut do
        summon_monks(ctx, state, position)
        state.next_aut = state.next_aut + 10 *
            (wizlab.WUCAD_MONK_DELAY_MIN_TURNS +
                ctx:random(streams.WIZLAB_EVENTS,
                    wizlab.WUCAD_MONK_DELAY_RANGE_TURNS))
        changed = true
    end

    return changed
end

-- The source death trigger targets the authored named orange statue.
-- Its vault origin distinguishes that statue from an ordinary one.
function wucad.statue_died(ctx, actor, definition, position)
    local origin = ctx:get(actor, component.VAULT_ORIGIN)

    if not origin or origin.vault_id ~= wizlab.WUCAD_MAP_ID or
        definition.id ~= wizlab.WUCAD_STATUE_KIND then
        return false
    end

    for _, entity in ipairs(ctx:query({
        component.WORLD_WIZLAB_WUCAD,
    })) do
        local state = ctx:get(entity,
            component.WORLD_WIZLAB_WUCAD)

        if state.level_id == position.level_id and
            not state.suppressed then
            state.suppressed = true
            state.next_aut = 0
            ctx:set(entity,
                component.WORLD_WIZLAB_WUCAD, state)
            ctx:emit(channels.VAULT,
                "The shadows inhabiting this place fade forever.")
        end
    end

    return false
end

death_hooks.add("wizlab.wucad_statue", wucad.statue_died)

return wucad
