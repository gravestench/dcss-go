local catalog = require("policy.generation.vaults.catalog")
local depth = require("policy.generation.vaults.depth")
local hooks = require("policy.generation.vaults.hooks")
local placement = require("policy.generation.vaults.placement")
local connect = require("policy.generation.vaults.connect")
local selection = require("policy.generation.vaults.selection")

local extra = {}
local GENERIC_EXTRA_ROLL = 8

local function key(x, y)
    return x .. ":" .. y
end

local function restore(builder, rows)
    for y, row in ipairs(rows) do
        for x = 1, #row do
            builder:set(x - 1, y - 1, row:sub(x, x))
        end
    end
end

local function altered_protected(builder, rows, protected)
    for position in pairs(protected) do
        local x, y = position:match("^(%d+):(%d+)$")

        x = tonumber(x)
        y = tonumber(y)

        if builder:cell(x, y) ~= rows[y + 1]:sub(x + 1, x + 1) then
            return true
        end
    end

    return false
end

local function mark_changes(builder, rows, protected)
    for y, row in ipairs(rows) do
        for x = 1, #row do
            if builder:cell(x - 1, y - 1) ~= row:sub(x, x) then
                protected[key(x - 1, y - 1)] = true
            end
        end
    end
end

local function fit_failure(message)
    return message:find("conflicts with an existing stair", 1, true) or
        message:find("cannot fit without replacing", 1, true) or
        message:find("no ordinary Dungeon floor to connect", 1, true)
end

-- A failed fit restores every grid cell. The layout stream still advances,
-- so retries are deterministic and never repeat a rejected origin forever.
function extra.place(ctx, builder, vault, context)
    local protected = context.protected
    local last_error

    for _ = 1, 8 do
        local before = builder:rows()
        local ok, placed = pcall(placement.place, ctx, builder, vault,
            context.player, {
                protected = protected,
                attempts = 128,
            })

        if ok then
            local connected, message = pcall(connect.finish, ctx, builder,
                placed, context.required)

            if connected and not altered_protected(builder, before, protected) then
                mark_changes(builder, before, protected)

                for _, point in ipairs(placed.occupied) do
                    protected[key(point.x, point.y)] = true
                end

                return placed
            end

            last_error = connected and "connector altered protected cells" or
                tostring(message)
        else
            last_error = tostring(placed)
        end

        restore(builder, before)

        if not fit_failure(last_error) and
            last_error ~= "connector altered protected cells" then
            error(last_error)
        end
    end

    return nil, last_error
end

local function controller_api(builder, context, placed)
    local api = {}

    function api:roll(bound)
        return builder:roll(bound)
    end

    function api:chance(numerator, denominator)
        return numerator >= denominator or
            (numerator > 0 and self:roll(denominator) < numerator)
    end

    function api:one_in(bound)
        return builder:one_in(bound)
    end

    function api:random_range(first, last)
        return first + self:roll(last - first + 1)
    end

    function api:absolute_depth()
        return context.absolute_depth or context.depth
    end

    function api:place_maps(tag, count)
        for _ = 1, count do
            local selected = selection.choose_tag(builder, tag, context)

            if not selected then
                error("no eligible source vault for tag " .. tag)
            end

            local vault = catalog.get(selected.id)
            local child = {}

            for name, value in pairs(context) do
                child[name] = value
            end

            child.player = {}

            for name, value in pairs(context.player or {}) do
                child.player[name] = value
            end

            child.player.map_tag = tag

            local map, reason = extra.place(nil, builder, vault, child)

            if not map then
                error("cannot place shop vault " .. vault.id ..
                    ": " .. tostring(reason))
            end

            placed[#placed + 1] = map
            context.used[vault.id] = true
        end
    end

    return api
end

-- CHANCE maps are rolled independently of the weighted shop map selected
-- by their controller. This is the source serial_shops placement sequence.
function extra.generate(ctx, builder, context)
    local serial = catalog.get("serial_shops")
    local placed = {}
    local controller

    context.used = context.used or {}
    context.family = "shop"
    context.excluded = {
        [serial.id] = true,
    }

    local generic

    -- DCSS draws from a global secondary-vault pool. Until the other
    -- families are imported, a bounded opportunity keeps shop-only content
    -- from occupying every generated floor.
    if builder:roll(GENERIC_EXTRA_ROLL) == 0 then
        generic = selection.choose_tag(builder, "extra", context)
    end

    if generic then
        local vault = catalog.get(generic.id)
        local map = extra.place(ctx, builder, vault, context)

        if map then
            placed[#placed + 1] = map
            context.used[vault.id] = true
            controller = vault.id
        end
    end

    if not depth.eligible(serial, context.branch_id,
        context.depth, context.branch_bottom) then
        return placed, controller
    end

    local percent = depth.chance(serial, context.branch_id)

    if percent <= 0 or
        (percent < 100 and builder:roll(100) >= percent) then
        return placed, controller
    end

    hooks.run(serial, "place_serial_shops",
        controller_api(builder, context, placed))

    return placed, serial.id
end

function extra.protect(protected, point)
    protected[key(point.x, point.y)] = true
end

return extra
