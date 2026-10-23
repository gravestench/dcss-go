-- Theory of operation: the source countdown fires three times. Two
-- warnings use Silence at the player's current position; the third
-- lowers every marked wall in one action and leaves short black smoke.
-- Akara stores the next absolute firing time and phase, while the
-- level grid owns the changed terrain.
local attribution = require("constants.cloud_attribution")
local channels = require("constants.message_channels")
local clouds = require("ids.clouds")
local component = require("constants.component")
local placement = require("policy.clouds.placement")
local silence = require("policy.world.silence")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")
local wizlab = require("constants.wizlab")

local doroklohe = {}

-- Source DgnTriggerer draws another inclusive 500–1000-turn delay after
-- each warning. Use one saved stream and advance from the prior deadline.
local function delay(ctx)
    return 10 * (wizlab.DOROK_DELAY_MIN_TURNS +
        ctx:random(streams.WIZLAB_EVENTS,
            wizlab.DOROK_DELAY_RANGE_TURNS))
end

-- The warning does not depend on whether the player can hear a distant
-- box; source Lua checks only their current Silence field.
local function warn(ctx, phase, position)
    local quiet = silence.at(ctx,
        position.level_id, position.x, position.y)

    if quiet then
        ctx:emit(channels.WARNING, "The ground shakes.")
    elseif phase == 1 then
        ctx:emit(channels.WARNING,
            "There is a faint hissing noise.")
    else
        ctx:emit(channels.WARNING,
            "There is a loud grinding noise.")
    end
end

-- Source wall_drop markers are transformed before population, so these
-- saved coordinates refer to the actual room even if a mod rotates it.
local function lower_walls(ctx, state)
    ctx:emit(channels.WARNING,
        "The walls fall away. The entombed are set free!")

    for index, x in ipairs(state.wall_x) do
        local y = state.wall_y[index]

        ctx:set_cell(state.level_id, x, y,
            terrain.DNGN_FLOOR)
        placement.place(ctx, clouds.CLOUD_BLACK_SMOKE,
            nil, state.level_id, x, y, 20, {
                kill_category = attribution.OTHER,
                killer_type = attribution.MISC,
                exclusion_radius = -1,
            })
    end
end

-- Only player action time on this lab advances its source Triggerable
-- Function. A long action may cross multiple deadlines in order.
function doroklohe.tick(ctx, state, position, elapsed_aut)
    if state.phase > 3 or state.level_id ~= position.level_id then
        return false
    end

    local now = ctx:aut() + elapsed_aut
    local changed = false

    while state.phase <= 3 and now >= state.next_aut do
        if state.phase < 3 then
            warn(ctx, state.phase, position)
            state.next_aut = state.next_aut + delay(ctx)
        else
            lower_walls(ctx, state)
            state.next_aut = 0
        end

        state.phase = state.phase + 1
        changed = true
    end

    return changed
end

return doroklohe
