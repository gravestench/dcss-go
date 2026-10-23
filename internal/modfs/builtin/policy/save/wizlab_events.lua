-- Restore checks each live lab event against its immutable DES markers
-- and the active floor. A saved phase cannot invent vanished walls,
-- replay the same collapse, or point at another lab's record index.
local branches = require("ids.branches")
local component = require("constants.component")
local effects = require("constants.vault_effects")
local monsters = require("ids.monsters")
local terrain = require("constants.terrain")
local wizlab = require("constants.wizlab")

local events = {}

-- Lookup is by saved record index, not by a new interpretation of the
-- source glyph. The populated floor is the immutable marker witness.
local function marker(level, index, vault_id, identity)
    for _, record in ipairs(level.vault_records or {}) do
        if record.index == index and
            record.source_id == vault_id and
            record.kind == effects.MARKER and
            record.identity == identity and
            not record.overridden and not record.pending then
            return record
        end
    end

    return nil
end

-- Index the actual saved floors once before checking Akara references.
local function level_index(input)
    local levels = {}

    for _, level in ipairs(input.levels or {}) do
        levels[level.id] = level

        -- Go saves records in array order without serializing a second
        -- index field. Population used this same one-based array index.
        for index, record in ipairs(level.vault_records or {}) do
            record.index = index
        end
    end

    return levels
end

-- Doroklohe's A clock and all wall_drop records form one ordered group.
-- The records stay on the level when the corresponding walls change.
local function dorok_sources(level)
    local clock
    local walls = {}

    for _, record in ipairs(level.vault_records or {}) do
        if record.source_id == wizlab.DOROK_MAP_ID and
            record.kind == effects.MARKER and
            not record.overridden and not record.pending then
            if record.identity == wizlab.DOROK_BOX_MARKER then
                if clock then
                    error("Doroklohe has multiple source clocks")
                end

                clock = record
            elseif type(record.identity) == "string" and
                record.identity:find(wizlab.DOROK_WALL_PROPERTY,
                    1, true) then
                walls[#walls + 1] = record
            end
        end
    end

    if not clock or #walls == 0 then
        error("Doroklohe lacks its source marker group")
    end

    return clock, walls
end

-- Compare each saved wall coordinate and record index, then verify the
-- completed phase's terrain. The grid is authoritative for fallen walls.
local function validate_dorok(ctx, state, level)
    local clock, walls = dorok_sources(level)
    local done = state.phase == 4

    if state.vault_id ~= wizlab.DOROK_MAP_ID or
        state.clock_index ~= clock.index or
        state.phase < 1 or state.phase > 4 or
        #state.wall_indices ~= #walls or
        #state.wall_x ~= #walls or
        #state.wall_y ~= #walls or
        (done and state.next_aut ~= 0) or
        (not done and
            (state.next_aut <= ctx:aut() or
                state.next_aut > ctx:aut() + 10000)) then
        error("Doroklohe event phase or source group is invalid")
    end

    for index, wall in ipairs(walls) do
        if state.wall_indices[index] ~= wall.index or
            state.wall_x[index] ~= wall.x or
            state.wall_y[index] ~= wall.y or
            (done and ctx:cell(level.id, wall.x, wall.y) ~=
                terrain.DNGN_FLOOR) then
            error("Doroklohe wall group disagrees with saved terrain")
        end
    end
end

-- The seven numbered Wucad spots must still point at the authored
-- markers. Suppressing the statue disables the timer, not saved history.
local function validate_wucad(ctx, state, level)
    if state.vault_id ~= wizlab.WUCAD_MAP_ID or
        not marker(level, state.monks_index, state.vault_id,
            wizlab.WUCAD_MONKS_MARKER) or
        not marker(level, state.death_index, state.vault_id,
            wizlab.WUCAD_DEATH_MARKER) or
        #state.message_indices < 7 or
        #state.message_x ~= #state.message_indices or
        #state.message_y ~= #state.message_indices or
        #state.message_spot ~= #state.message_indices or
        #state.message_done ~= 7 or
        (state.suppressed and state.next_aut ~= 0) or
        (not state.suppressed and
            (state.next_aut <= ctx:aut() or
                state.next_aut > ctx:aut() + 3000)) then
        error("Wucad event state is invalid")
    end

    local seen = {}

    for index, spot in ipairs(state.message_spot) do
        if spot < 1 or spot > 7 then
            error("Wucad has an invalid message spot")
        end

        seen[spot] = true
        local identity = wizlab.WUCAD_MESSAGE_MARKER ..
            " { spot = " .. spot .. " }"
        local record = marker(level, state.message_indices[index],
            state.vault_id, identity)

        if not record or state.message_x[index] ~= record.x or
            state.message_y[index] ~= record.y then
            error("Wucad message marker disagrees with save")
        end
    end

    for spot = 1, 7 do
        if not seen[spot] then
            error("Wucad is missing a message group")
        end
    end
end

-- Borgnjor's death callback has one authored marker and no mutable
-- countdown; its state exists solely to prove the source floor join.
local function validate_borgnjor(_, state, level)
    if state.vault_id ~= wizlab.BORGNJOR_MAP_ID or
        not marker(level, state.marker_index, state.vault_id,
            wizlab.BORGNJOR_SOUL_MARKER) then
        error("Borgnjor event marker is invalid")
    end
end

-- Grave bits are bounded by source G markers. A consumed grave must be
-- open floor, and the door bit must agree with the changed D terrain.
local function validate_zonguldrok(ctx, state, level)
    local count = 0
    local clock = marker(level, state.clock_index,
        state.vault_id, wizlab.ZONG_SPAWN_MARKER)
    local door = marker(level, state.door_index,
        state.vault_id, wizlab.ZONG_DEATH_MARKER)
    local wizard = marker(level, state.wizard_index,
        state.vault_id, wizlab.ZONG_WIZARD_GRAVE_MARKER)

    if not clock or not door or not wizard or
        state.door_x ~= door.x or state.door_y ~= door.y or
        state.wizard_x ~= wizard.x or
        state.wizard_y ~= wizard.y then
        error("Zonguldrok source clock, door, or wizard is invalid")
    end

    if state.vault_id ~= wizlab.ZONG_MAP_ID or
        #state.grave_indices == 0 or
        #state.grave_indices ~= #state.grave_x or
        #state.grave_indices ~= #state.grave_y or
        #state.grave_indices ~= #state.grave_active or
        state.count < 0 or state.killed < 0 or
        state.killed > state.count or
        state.next_aut <= ctx:aut() or
        state.next_aut > ctx:aut() + 2500 or
        #state.awaken_x == 0 or
        #state.awaken_x ~= #state.awaken_y then
        error("Zonguldrok event state is invalid: graves=" ..
            #state.grave_indices .. " awake=" ..
            #state.awaken_x .. " next=" ..
            state.next_aut .. " aut=" .. ctx:aut())
    end

    for index, source_index in ipairs(state.grave_indices) do
        local record = marker(level, source_index,
            state.vault_id, wizlab.ZONG_GRAVE_MARKER)

        if not record or state.grave_x[index] ~= record.x or
            state.grave_y[index] ~= record.y then
            error("Zonguldrok grave marker disagrees with save")
        end

        if not state.grave_active[index] then
            count = count + 1

            if ctx:cell(level.id, record.x, record.y) ~=
                terrain.DNGN_FLOOR then
                error("Zonguldrok consumed grave is still closed")
            end
        end
    end

    local door_cell = ctx:cell(level.id,
        state.door_x, state.door_y)

    if count ~= state.count or
        (state.door_appeared and
            door_cell ~= terrain.DNGN_CLOSED_DOOR and
            door_cell ~= terrain.DNGN_OPEN_DOOR) then
        error("Zonguldrok grave counters disagree with terrain")
    end

    local awaken = {}

    for _, record in ipairs(level.vault_records or {}) do
        if record.source_id == state.vault_id and
            record.kind == effects.MARKER and
            record.identity == wizlab.ZONG_AWAKEN_MARKER and
            not record.overridden and not record.pending then
            awaken[#awaken + 1] = record
        end
    end

    if #awaken ~= #state.awaken_x then
        error("Zonguldrok awakening cells are incomplete")
    end

    for index, record in ipairs(awaken) do
        if state.awaken_x[index] ~= record.x or
            state.awaken_y[index] ~= record.y then
            error("Zonguldrok awakening cell moved from source")
        end
    end
end

-- A small descriptor table keeps the four independent event contracts
-- visible without making one giant lab-name switch or reimplementing
-- each owner's gameplay policy in the save boundary.
local families = {
    {
        id = component.WORLD_WIZLAB_DOROKLOHE,
        vault_id = wizlab.DOROK_MAP_ID,
        check = validate_dorok,
    },
    {
        id = component.WORLD_WIZLAB_WUCAD,
        vault_id = wizlab.WUCAD_MAP_ID,
        check = validate_wucad,
    },
    {
        id = component.WORLD_WIZLAB_BORGNJOR,
        vault_id = wizlab.BORGNJOR_MAP_ID,
        check = validate_borgnjor,
    },
    {
        id = component.WORLD_WIZLAB_ZONGULDROK,
        vault_id = wizlab.ZONG_MAP_ID,
        check = validate_zonguldrok,
    },
}

-- Dynamic callbacks can create actors after the source roster is
-- populated. Their separate provenance joins each actor to its event
-- owner; otherwise a forged spawn could evade the vault-origin check.
local function event_owner(ctx, id, level_id)
    for _, entity in ipairs(ctx:query({ id })) do
        local state = ctx:get(entity, id)

        if state.level_id == level_id then
            return state
        end
    end

    return nil
end

-- Zonguldrok's grave actors have one source grave apiece. Wucad and
-- Borgnjor summons are further checked by the shared summon validator.
local function validate_event_actors(ctx, levels)
    local grave_kinds = {
        [monsters.MONS_ZOMBIE] = true,
        [monsters.MONS_WIGHT] = true,
        [monsters.MONS_VAMPIRE] = true,
        [monsters.MONS_SKELETAL_WARRIOR] = true,
        [monsters.MONS_ANCIENT_CHAMPION] = true,
    }
    local live_graves = {}

    for _, entity in ipairs(ctx:query({
        component.WORLD_WIZLAB_EVENT_ACTOR,
    })) do
        local origin = ctx:get(entity,
            component.WORLD_WIZLAB_EVENT_ACTOR)
        local position = ctx:get(entity, component.POSITION)
        local actor = ctx:get(entity, component.ACTOR)
        local level = levels[origin.level_id]

        if not level or
            level.branch_id ~= branches.BRANCH_WIZLAB or
            level.vault_id ~= origin.vault_id or
            not position or position.level_id ~= level.id or
            not actor then
            error("Wizard Lab event actor has invalid floor origin")
        end

        if origin.kind == wizlab.EVENT_ACTOR_WUCAD then
            local state = event_owner(ctx,
                component.WORLD_WIZLAB_WUCAD, level.id)

            if not state or
                origin.source_index ~= state.monks_index then
                error("Wucad monk lacks its source clock")
            end
        elseif origin.kind == wizlab.EVENT_ACTOR_BORGNJOR then
            local state = event_owner(ctx,
                component.WORLD_WIZLAB_BORGNJOR, level.id)

            if not state or
                origin.source_index ~= state.marker_index or
                actor.kind_id ~= monsters.MONS_LOST_SOUL then
                error("Borgnjor soul lacks its source marker")
            end
        elseif origin.kind == wizlab.EVENT_ACTOR_ZONGULDROK or
            origin.kind == wizlab.EVENT_ACTOR_ZONGULDROK_LICH then
            local state = event_owner(ctx,
                component.WORLD_WIZLAB_ZONGULDROK, level.id)

            if not state then
                error("Zonguldrok actor lacks its encounter state")
            end

            if origin.kind ==
                wizlab.EVENT_ACTOR_ZONGULDROK_LICH then
                if not state.awoke or
                    origin.source_index ~= state.wizard_index or
                    actor.kind_id ~= monsters.MONS_ANCIENT_LICH then
                    error("Zonguldrok lich has invalid awakening")
                end
            else
                local matched = false

                for index, source_index in ipairs(
                    state.grave_indices) do
                    matched = matched or
                        (source_index == origin.source_index and
                            not state.grave_active[index])
                end

                local key = level.id .. ":" .. origin.source_index

                if not matched or
                    not grave_kinds[actor.kind_id] or
                    live_graves[key] then
                    error("Zonguldrok actor has invalid grave origin")
                end

                live_graves[key] = true
            end
        else
            error("unknown Wizard Lab event actor kind")
        end
    end
end

-- One active Doroklohe floor needs one clock. All other Wizard Labs
-- must have none, including a retired floor after portal return.
function events.validate(ctx, input)
    local levels = level_index(input)
    for _, family in ipairs(families) do
        local seen = {}

        for _, entity in ipairs(ctx:query({ family.id })) do
            local state = ctx:get(entity, family.id)
            local level = levels[state.level_id]

            if not level or
                level.branch_id ~= branches.BRANCH_WIZLAB or
                level.vault_id ~= family.vault_id or
                seen[level.id] then
                error("Wizard Lab event has no unique active floor")
            end

            family.check(ctx, state, level)
            seen[level.id] = true
        end

        for _, level in ipairs(input.levels or {}) do
            if level.branch_id == branches.BRANCH_WIZLAB and
                level.vault_id == family.vault_id and
                not seen[level.id] then
                error("Wizard Lab floor lacks its saved " ..
                    family.vault_id .. " event state")
            end
        end
    end

    validate_event_actors(ctx, levels)

    return {}
end

register.policy({
    id = "save.validate_wizlab_events",
    run = events.validate,
})

return events
