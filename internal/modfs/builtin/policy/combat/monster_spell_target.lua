local kind = require("constants.target_kind")

local target = {}

local function integer(value)
    return type(value) == "number" and value == math.floor(value)
end

local function write_direction(intent, plan)
    if plan.dx == nil and plan.dy == nil then
        return
    end

    if not integer(plan.dx) or not integer(plan.dy) then
        error("monster spell plan has invalid direction")
    end

    intent.dx = plan.dx
    intent.dy = plan.dy
end

local function read_direction(plan, intent)
    if intent.dx ~= nil and intent.dy ~= nil then
        plan.dx = intent.dx
        plan.dy = intent.dy
    end

    return plan
end

function target.write(intent, plan)
    if type(plan) ~= "table" then
        error("monster spell has no target plan")
    end

    intent.target_kind = plan.kind
    write_direction(intent, plan)

    if plan.kind == kind.ENTITY then
        if plan.entity == nil then
            error("monster spell entity plan has no target")
        end

        intent.target_entity = plan.entity

        return intent
    end

    if plan.kind == kind.CELL then
        if not integer(plan.level_id) or
            not integer(plan.x) or
            not integer(plan.y) then
            error("monster spell cell plan has invalid coordinates")
        end

        intent.target_level_id = plan.level_id
        intent.target_x = plan.x
        intent.target_y = plan.y

        return intent
    end

    error("unknown monster spell target kind " .. tostring(plan.kind))
end

function target.read(intent)
    if intent.target_kind == kind.ENTITY then
        if intent.target_entity == nil then
            error("monster spell intent has no entity target")
        end

        return read_direction({
            kind = kind.ENTITY,
            entity = intent.target_entity,
        }, intent)
    end

    if intent.target_kind == kind.CELL then
        if not integer(intent.target_level_id) or
            not integer(intent.target_x) or
            not integer(intent.target_y) then
            error("monster spell intent has invalid cell target")
        end

        return read_direction({
            kind = kind.CELL,
            level_id = intent.target_level_id,
            x = intent.target_x,
            y = intent.target_y,
        }, intent)
    end

    error("unknown monster spell intent target " ..
        tostring(intent.target_kind))
end

function target.require_entity(plan, expected)
    if plan.kind ~= kind.ENTITY or plan.entity ~= expected then
        error("monster spell target differs from the selected foe")
    end

    return plan.entity
end

return target
