-- Theory of operation: Jiyva's two invocations have player-owned clocks.
-- Oozemancy's changed cells are separate temporary-terrain ECS markers;
-- only markers tagged with its ability ID may be cleared by this owner.
local abilities = require("ids.abilities")
local component = require("constants.component")
local gods = require("constants.gods")
local temporary = require("policy.world.temporary_terrain")
local time = require("constants.time")

local powers = {}
local MAX_DURATION_AUT = 1000

-- A missing component is equivalent to both powers being inactive.
local function state(ctx, player)
    return ctx:get(player, component.JIYVA_POWERS) or {
        oozemancy_aut = 0,
        ooze_level_id = 0,
        slimify_aut = 0,
    }
end

-- Remove the component once both durations end; no empty persistent
-- record should survive departure or the next save.
local function save(ctx, player, value)
    if value.oozemancy_aut == 0 and value.slimify_aut == 0 then
        if ctx:has(player, component.JIYVA_POWERS) then
            ctx:remove(player, component.JIYVA_POWERS)
        end

        return
    end

    if ctx:has(player, component.JIYVA_POWERS) then
        ctx:set(player, component.JIYVA_POWERS, value)
    else
        ctx:add(player, component.JIYVA_POWERS, value)
    end
end

-- Restrict cleanup to this invocation. A player may also own temporary
-- water, vines, and other spell terrain on the same floor.
local function restore_ooze_walls(ctx, player)
    local owner_id = ctx:id(player)

    for _, marker in ipairs(ctx:query({
        component.TEMPORARY_TERRAIN,
    })) do
        local record = ctx:get(marker, component.TEMPORARY_TERRAIN)

        if record.source_actor_id == owner_id and
            record.source_kind_id == abilities.JIYVA_OOZEMANCY then
            temporary.restore(ctx, marker, record)
        end
    end
end

-- The remaining clock is read by the melee owner without modifying it.
function powers.slimify_active(ctx, player)
    return state(ctx, player).slimify_aut > 0
end

-- A successful invocation extends its own timer, capped at 100 turns.
function powers.start_slimify(ctx, player, turns)
    local value = state(ctx, player)

    value.slimify_aut = math.min(MAX_DURATION_AUT,
        value.slimify_aut + turns * time.AUT_PER_TURN)
    save(ctx, player, value)
end

-- Once an eligible successful contact transforms a body, no later contact
-- in the same attack may use this charge.
function powers.consume_slimify(ctx, player)
    local value = state(ctx, player)

    value.slimify_aut = 0
    save(ctx, player, value)
end

-- Oozemancy cannot be refreshed while it runs. Its level ID lets a floor
-- transition stop the aura even if the world retains that older floor.
function powers.oozemancy_active(ctx, player)
    local value = state(ctx, player)
    local position = ctx:get(player, component.POSITION)

    return value.oozemancy_aut > 0 and position and
        value.ooze_level_id == position.level_id or false
end

-- Save the duration after wall markers are placed, so a failed placement
-- cannot create a power with no cells to own.
function powers.start_oozemancy(ctx, player, level_id, turns)
    local value = state(ctx, player)

    value.oozemancy_aut = math.min(MAX_DURATION_AUT,
        value.oozemancy_aut + turns * time.AUT_PER_TURN)
    value.ooze_level_id = level_id
    save(ctx, player, value)
end

-- Source worship transitions revoke both powers immediately. Restoring
-- only this ability's markers leaves unrelated temporary terrain intact.
function powers.clear(ctx, player)
    restore_ooze_walls(ctx, player)

    if ctx:has(player, component.JIYVA_POWERS) then
        ctx:remove(player, component.JIYVA_POWERS)
    end
end

-- Player action time ages both clocks. Oozemancy additionally ends when
-- its originating floor is left, as in the source stair transition.
function powers.tick(ctx, player, aut)
    local current = ctx:get(player, component.JIYVA_POWERS)

    if not current then
        return
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if not worship or worship.god_id ~= gods.JIYVA or
        (worship.penance[gods.JIYVA] or 0) > 0 then
        powers.clear(ctx, player)

        return
    end

    local position = ctx:get(player, component.POSITION)

    if current.oozemancy_aut > 0 and
        (not position or position.level_id ~= current.ooze_level_id) then
        restore_ooze_walls(ctx, player)
        current.oozemancy_aut = 0
        current.ooze_level_id = 0
    end

    current.oozemancy_aut = math.max(0,
        current.oozemancy_aut - aut)
    current.slimify_aut = math.max(0, current.slimify_aut - aut)

    if current.oozemancy_aut == 0 then
        restore_ooze_walls(ctx, player)
        current.ooze_level_id = 0
    end

    save(ctx, player, current)
end

-- Restore refuses impossible duration or worship combinations before
-- the next action can age the record and hide corruption.
function powers.validate(ctx, player)
    local value = ctx:get(player, component.JIYVA_POWERS)

    if not value then
        return
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if value.oozemancy_aut < 0 or
        value.oozemancy_aut > MAX_DURATION_AUT or
        value.slimify_aut < 0 or
        value.slimify_aut > MAX_DURATION_AUT or
        value.oozemancy_aut == 0 and value.slimify_aut == 0 or
        value.oozemancy_aut == 0 and value.ooze_level_id ~= 0 or
        value.oozemancy_aut > 0 and value.ooze_level_id <= 0 or
        not worship or worship.god_id ~= gods.JIYVA or
        (worship.penance[gods.JIYVA] or 0) > 0 then
        error("invalid Jiyva active power state")
    end
end

return powers
