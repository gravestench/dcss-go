-- Delayed vault actors are part of authored map content even though they
-- appear after the initial population pass. Validate their saved source
-- marker and target before the restored turn scheduler can use them.
local component = require("constants.component")
local effects = require("constants.vault_effects")
local monsters = require("ids.monsters")
local trigger_ids = require("constants.vault_triggers")

local spawns = {}

-- A trigger may be consumed, but its immutable DES marker stays on the level.
local function source_record(level, state)
    local record = level.vault_records[state.trigger_index]

    if not record or record.kind ~= effects.MARKER or
        record.identity ~= trigger_ids.LADY_OF_LAKE_SPAWN or
        record.source_id ~= state.vault_id or
        record.pending or record.overridden then
        error("delayed vault actor has no authored trigger")
    end
end

-- The avatar target is a separate source marker in the same placed map.
local function target_record(level, state)
    local found = 0

    for _, record in ipairs(level.vault_records or {}) do
        if record.kind == effects.MARKER and
            record.identity == trigger_ids.MERFOLK_AVATAR_TARGET and
            record.source_id == state.vault_id and
            record.x == state.target_x and
            record.y == state.target_y and
            not record.overridden then
            found = found + 1
        end
    end

    if found ~= 1 then
        error("delayed vault actor has no unique authored target")
    end
end

-- One Lady encounter has one avatar, regardless of how many entrance cells
-- the source MAP marks. The actor may move after spawning, so its current
-- position must stay on the level but need not equal the target cell.
function spawns.validate(ctx, input)
    local levels = {}
    local seen = {}

    for _, level in ipairs(input.levels or {}) do
        levels[level.id] = level
    end

    for _, entity in ipairs(ctx:query({ component.WORLD_VAULT_SPAWN })) do
        local state = ctx:get(entity, component.WORLD_VAULT_SPAWN)
        local level = levels[state.level_id]
        local actor = ctx:get(entity, component.ACTOR)
        local position = ctx:get(entity, component.POSITION)
        local key = state.level_id .. ":" .. state.vault_id

        if not level or not actor or not position or
            actor.kind_id ~= monsters.MONS_MERFOLK_AVATAR or
            position.level_id ~= state.level_id or seen[key] then
            error("invalid delayed vault avatar " .. ctx:id(entity))
        end

        source_record(level, state)
        target_record(level, state)
        seen[key] = true
    end

    return {}
end

register.policy({
    id = "save.validate_vault_spawns",
    run = spawns.validate,
})

return spawns
