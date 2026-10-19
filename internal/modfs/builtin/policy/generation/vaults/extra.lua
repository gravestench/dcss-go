-- Example: A rejected placement restores its prior map cells before retrying elsewhere.
local catalog = require("policy.generation.vaults.catalog")
local depth = require("policy.generation.vaults.depth")
local hooks = require("policy.generation.vaults.hooks")
local placement = require("policy.generation.vaults.placement")
local connect = require("policy.generation.vaults.connect")
local selection = require("policy.generation.vaults.selection")

local extra = {}
local GENERIC_EXTRA_ROLL = 8

-- Identify protected map cells by coordinate across repeated placement attempts.
local function key(x, y)
    return x .. ":" .. y
end

-- Restore a rejected fit cell by cell before the next origin attempt.
local function restore(builder, rows)
    for y, row in ipairs(rows) do
        for x = 1, #row do
            builder:set(x - 1, y - 1, row:sub(x, x))
        end
    end
end

-- A rejected fit must leave every protected stair and arrival cell unchanged.
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

-- Mark only cells actually changed by the extra vault so later projection does not restore them.
local function mark_changes(builder, rows, protected)
    for y, row in ipairs(rows) do
        for x = 1, #row do
            if builder:cell(x - 1, y - 1) ~= row:sub(x, x) then
                protected[key(x - 1, y - 1)] = true
            end
        end
    end
end

-- Retry geometric conflicts but propagate malformed vault definitions as errors.
local function fit_failure(message)
    return message:find("conflicts with an existing stair", 1, true) or
        message:find("cannot fit without replacing", 1, true) or
        message:find("no ordinary Dungeon floor to connect", 1, true)
end

-- A failed fit restores every grid cell. The layout stream still advances,
-- so retries are deterministic and never repeat a rejected origin forever.
-- Reject a map fit if it alters protected stairs, restoring the builder cells before another candidate.
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

-- Give DES controllers a bounded layout RNG and placement API.
local function controller_api(builder, context, placed)
    local api = {}

    -- Draw through the current builder so controller choices share layout RNG order.
    function api:roll(bound)
        return builder:roll(bound)
    end

    -- Skip draws for certain or impossible chances, matching source controller behavior.
    function api:chance(numerator, denominator)
        return numerator >= denominator or
            (numerator > 0 and self:roll(denominator) < numerator)
    end

    -- Use the builder one-in primitive for controller branch choices.
    function api:one_in(bound)
        return builder:one_in(bound)
    end

    -- Convert one bounded builder draw into an inclusive interval.
    function api:random_range(first, last)
        return first + self:roll(last - first + 1)
    end

    -- Fall back to local depth when no absolute branch depth was supplied.
    function api:absolute_depth()
        return context.absolute_depth or context.depth
    end

    -- Attempt requested tagged maps sequentially so a prior fit affects the
    -- next. A tag with no candidates at this depth places nothing; the
    -- caller can keep that slot for another map family.
    function api:place_maps(tag, count)
        local placed_count = 0

        for _ = 1, count do
            local selected = selection.choose_tag(builder, tag, context)

            if not selected then
                return placed_count
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
            placed_count = placed_count + 1
        end

        return placed_count
    end

    return api
end

-- CHANCE maps are rolled independently of the weighted shop map selected
-- by their controller. This is the source serial_shops placement sequence.
-- Choose the controller and its tagged extras on the layout stream after arrival connection.
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

-- Add a stair or arrival point to the protected-cell set before extra placement.
function extra.protect(protected, point)
    protected[key(point.x, point.y)] = true
end

return extra
