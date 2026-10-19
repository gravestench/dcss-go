local catalog = require("policy.catalog")
local component = require("constants.component")
local ids = require("ids.traps")
local item_ids = require("ids.items")
local effects = require("constants.vault_effects")

local traps = {}

-- An alarm mark duration must be bounded before timed trap systems resume.
local function validate_mark(ctx)
    for _, entity in ipairs(ctx:query({ component.TRAP_MARK })) do
        local state = ctx:get(entity, component.TRAP_MARK)

        if entity ~= ctx:player() or state.remaining_aut < 1 or
            state.remaining_aut > 2500 then
            error("invalid saved sentinel mark")
        end
    end
end

-- Held-state validation ties a victim to its net or web source.
local function validate_held(ctx, occupied)
    for _, entity in ipairs(ctx:query({ component.TRAP_HELD })) do
        local state = ctx:get(entity, component.TRAP_HELD)
        local position = ctx:get(entity, component.POSITION)

        if not position or not ctx:get(entity, component.ACTOR) then
            error("trap restraint has no positioned actor")
        end

        if state.kind_id == ids.TRAP_WEB then
            local cell = string.format("%d:%d:%d",
                position.level_id, position.x, position.y)
            local trap = occupied[cell]

            if state.net_item_id ~= 0 or not trap or
                trap.kind_id ~= ids.TRAP_WEB then
                error("web restraint has no matching web")
            end
        elseif state.kind_id == ids.TRAP_NET then
            local item = ctx:entity(state.net_item_id)
            local item_state = item and ctx:get(item, component.ITEM)
            local item_position = item and ctx:get(item, component.POSITION)
            local durability = item and
                ctx:get(item, component.PROJECTILE_NET)

            if entity ~= ctx:player() or not item_state or
                item_state.kind_id ~= item_ids.MI_THROWING_NET or
                not item_position or not durability or
                item_position.level_id ~= position.level_id or
                item_position.x ~= position.x or
                item_position.y ~= position.y or
                durability.durability < -7 or durability.durability > 0 then
                error("net restraint has no matching net")
            end
        else
            error("unknown trap restraint " .. state.kind_id)
        end
    end
end

-- Authored traps keep a vault record key so a restored trap cannot migrate away from its source cell.
local function validate_origin(state, levels)
    if state.source_record == "" then
        return
    end

    local source_id, index = state.source_record:match("^(.*):(%d+)$")
    local level = levels[state.level_id]
    local record = level and level.vault_records[tonumber(index)]

    if not record or source_id ~= record.source_id or
        record.x ~= state.x or record.y ~= state.y or record.pending or
        (record.kind ~= effects.FEATURE and
            record.kind ~= effects.SOURCE_FEATURE) or
        record.identity ~= state.kind_id then
        error("trap has dangling vault origin " .. state.source_record)
    end
end

-- Trap marks and held victims must refer to valid trap records after restore.
-- Example: traps.validate(ctx, input) rejects a held player without a valid net or web source.
function traps.validate(ctx, input)
    input = input or {}
    local occupied = {}
    local levels = {}

    for _, level in ipairs(input.levels or {}) do
        levels[level.id] = level
    end

    for _, entity in ipairs(ctx:query({ component.WORLD_TRAP })) do
        local state = ctx:get(entity, component.WORLD_TRAP)
        local position = ctx:get(entity, component.POSITION)
        local id = ctx:id(entity)

        if not position or ctx:get(entity, component.ACTOR) or
            ctx:get(entity, component.ITEM) then
            error("trap " .. id .. " has invalid entity roles")
        end

        if state.level_id ~= position.level_id or
            state.x ~= position.x or state.y ~= position.y then
            error("trap " .. id .. " has mismatched position")
        end

        local known, definition = pcall(catalog.get, "traps", state.kind_id)

        if not known then
            error("trap " .. id .. " has unknown kind " .. state.kind_id)
        end

        local lifetime = definition.lifetime_turns
        local maximum = lifetime and
            lifetime.minimum + lifetime.random - 1 or 0

        if state.charges < 0 or
            (definition.one_shot and state.charges ~= 1) or
            (lifetime and (state.charges < 1 or state.charges > maximum)) or
            (not definition.one_shot and not lifetime and
                state.charges ~= 0) then
            error("trap " .. id .. " has invalid charges")
        end

        if not ctx:walkable(state.level_id, state.x, state.y) then
            error("trap " .. id .. " is outside walkable terrain")
        end

        local cell = string.format("%d:%d:%d",
            state.level_id, state.x, state.y)

        if occupied[cell] then
            error("duplicate traps at " .. cell)
        end

        validate_origin(state, levels)
        occupied[cell] = state
    end

    validate_mark(ctx)
    validate_held(ctx, occupied)

    return {}
end

register.policy({
    id = "save.validate_traps",
    run = traps.validate,
})

return traps
