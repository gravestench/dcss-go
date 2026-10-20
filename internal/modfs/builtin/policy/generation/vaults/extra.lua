-- Example: A rejected placement restores its prior map cells before retrying elsewhere.
local catalog = require("policy.generation.vaults.catalog")
local chance = require("policy.generation.vaults.chance")
local controller = require("policy.generation.vaults.controller")
local directives = require("constants.vault_directives")
local hooks = require("policy.generation.vaults.hooks")
local placement = require("policy.generation.vaults.placement")
local connect = require("policy.generation.vaults.connect")
local selection = require("policy.generation.vaults.selection")
local used = require("policy.generation.vaults.used")

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

-- A successful CHANCE map may be a controller with no MAP rows. Its
-- post-place hooks then request tagged children through the same API used
-- by every other serial family; the DES operation names choose the hooks.
local function place_chance_map(ctx, builder, context, placed, vault)
    local map

    if #vault.rows > 0 then
        map = extra.place(ctx, builder, vault, context)

        if not map then
            return false
        end

        placed[#placed + 1] = map
    end

    context.used:add(vault)

    for _, operation in ipairs(vault.operations) do
        if operation.kind == directives.HOOK_POST_PLACE then
            local api = controller.new(builder, context, placed, extra.place)

            hooks.run(vault, operation.argument, api)
        end
    end

    return true
end

-- Chance maps roll before ordinary extras. A failed fit can request a
-- source fallback_* map, while another successful CHANCE map still gets
-- its own chance to place on the same floor.
local function place_chance_stage(ctx, builder, context, placed)
    local primary

    for _, selected in ipairs(chance.select(builder, context)) do
        local vault = catalog.get(selected.id)

        if context.used:allows(vault) then
            local placed_ok = place_chance_map(ctx, builder, context,
                placed, vault)

            if not placed_ok then
                local tag = chance.fallback_tag(vault)
                local fallback = tag and selection.choose_tag(builder,
                    tag, context)

                if fallback then
                    local replacement = catalog.get(fallback.id)

                    placed_ok = place_chance_map(ctx, builder, context,
                        placed, replacement)

                    if placed_ok then
                        primary = primary or replacement.id
                    end
                end
            else
                primary = primary or vault.id
            end
        end
    end

    return primary
end

-- The partial catalog has shops but not the full ordinary minivault pool.
-- Keep its bounded opportunity until that corpus replaces this interim
-- draw; CHANCE definitions never enter this ordinary weighted selection.
local function place_temporary_extra(ctx, builder, context, placed)
    if builder:roll(GENERIC_EXTRA_ROLL) ~= 0 then
        return nil
    end

    context.family = "shop"
    context.exclude_chance = true

    local selected = selection.choose_tag(builder, "extra", context)

    context.family = nil
    context.exclude_chance = nil

    if not selected then
        return nil
    end

    local vault = catalog.get(selected.id)
    local map = extra.place(ctx, builder, vault, context)

    if not map then
        return nil
    end

    placed[#placed + 1] = map
    context.used:add(vault)

    return vault.id
end

-- Track arrival, chance controllers, children, and ordinary maps together
-- so later floors can reconstruct source uniqueness from one saved ID list.
function extra.generate(ctx, builder, context)
    local placed = {}

    context.used = used.new(context.prior_vault_ids)

    if context.arrival_vault then
        context.used:add(context.arrival_vault)
    end

    local primary = place_chance_stage(ctx, builder, context, placed)
    local ordinary = place_temporary_extra(ctx, builder, context, placed)

    return placed, primary or ordinary, context.used:ids()
end

-- Add a stair or arrival point to the protected-cell set before extra placement.
function extra.protect(protected, point)
    protected[key(point.x, point.y)] = true
end

return extra
