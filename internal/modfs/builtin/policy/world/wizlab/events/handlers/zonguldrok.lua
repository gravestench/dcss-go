-- Theory of operation: the M clock creates a single encounter owner
-- from the complete transformed marker group. The G, Z, D, and L
-- markers remain witnesses used by its timed, death, and move policies.
local component = require("constants.component")
local effects = require("constants.vault_effects")
local source_group = require("policy.world.wizlab.events.source_group")
local streams = require("constants.rng_streams")
local wizlab = require("constants.wizlab")

local handler = {
    id = "zonguldrok",
}

local owned = {
    [wizlab.ZONG_GRAVE_MARKER] = true,
    [wizlab.ZONG_WIZARD_GRAVE_MARKER] = true,
    [wizlab.ZONG_SHRINE_MARKER] = true,
    [wizlab.ZONG_SPAWN_MARKER] = true,
    [wizlab.ZONG_DEATH_MARKER] = true,
    [wizlab.ZONG_AWAKEN_MARKER] = true,
}

-- Claim only the exact callback identities in this named source map.
function handler.is_marker(record)
    return record.source_id == wizlab.ZONG_MAP_ID and
        record.kind == effects.MARKER and owned[record.identity] == true
end

-- Record order is DES order, already stable across mod file ordering.
local function group(level, vault_id)
    local graves = {}
    local wizard
    local door
    local awaken = {}

    for _, record in ipairs(level.vault_records or {}) do
        if record.source_id == vault_id and
            record.kind == effects.MARKER then
            if record.identity == wizlab.ZONG_GRAVE_MARKER then
                graves[#graves + 1] = record
            elseif record.identity ==
                wizlab.ZONG_WIZARD_GRAVE_MARKER and not wizard then
                wizard = record
            elseif record.identity == wizlab.ZONG_DEATH_MARKER then
                if door then
                    error("Zonguldrok has multiple door markers")
                end

                door = record
            elseif record.identity == wizlab.ZONG_AWAKEN_MARKER then
                awaken[#awaken + 1] = record
            end
        end
    end

    if #graves == 0 or not wizard or not door or #awaken == 0 then
        error("Zonguldrok lacks its source grave marker group")
    end

    return graves, wizard, door, awaken
end

-- Only M constructs the owner. Other marker records are still realized
-- so saves can verify their source positions after a return or restore.
function handler.materialize(ctx, level, record)
    if record.identity == wizlab.ZONG_SPAWN_MARKER then
        source_group.require_unique_clock(level, record,
            "Zonguldrok")

        local graves, wizard, door, awaken =
            group(level, record.source_id)
        local indices = {}
        local xs = {}
        local ys = {}
        local active = {}
        local awaken_x = {}
        local awaken_y = {}

        for _, grave in ipairs(graves) do
            indices[#indices + 1] = grave.index
            xs[#xs + 1] = grave.x
            ys[#ys + 1] = grave.y
            active[#active + 1] = true
        end

        for _, cell in ipairs(awaken) do
            awaken_x[#awaken_x + 1] = cell.x
            awaken_y[#awaken_y + 1] = cell.y
        end

        local entity = ctx:create()

        ctx:add(entity, component.WORLD_WIZLAB_ZONGULDROK, {
            level_id = level.id,
            vault_id = record.source_id,
            clock_index = record.index,
            door_index = door.index,
            door_x = door.x,
            door_y = door.y,
            next_aut = ctx:aut() + 10 *
                (wizlab.ZONG_DELAY_MIN_TURNS +
                    ctx:random(streams.WIZLAB_EVENTS,
                        wizlab.ZONG_DELAY_RANGE_TURNS)),
            count = 0,
            vampire_count = 0,
            warrior_count = 0,
            champion_count = 0,
            killed = 0,
            door_appeared = false,
            awoke = false,
            grave_indices = indices,
            grave_x = xs,
            grave_y = ys,
            grave_active = active,
            wizard_x = wizard.x,
            wizard_y = wizard.y,
            wizard_index = wizard.index,
            awaken_x = awaken_x,
            awaken_y = awaken_y,
        })
    end

    return {
        level_id = level.id,
        index = record.index,
    }
end

return handler
