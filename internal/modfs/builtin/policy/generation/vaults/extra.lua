-- Example: A rejected placement restores its prior map cells before retrying elsewhere.
local catalog = require("policy.generation.vaults.catalog")
local chance = require("policy.generation.vaults.chance")
local controller = require("policy.generation.vaults.controller")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local end_vault = require("policy.generation.vaults.end")
local hooks = require("policy.generation.vaults.hooks")
local minivault = require("policy.generation.vaults.minivault")
local placement = require("policy.generation.vaults.placement")
local place = require("policy.generation.vaults.place")
local regular = require("policy.generation.vaults.regular")
local connect = require("policy.generation.vaults.connect")
local selection = require("policy.generation.vaults.selection")
local used = require("policy.generation.vaults.used")
local unique_placement = require("policy.generation.vaults.unique.placement")
local overflow_placement = require("policy.generation.altar.placement")

local extra = {}

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
        message:find("validation rejected placement", 1, true) or
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

        -- A source veto rejects this selected map outright. Retrying its
        -- geometry would consume more RNG and could reroll durable state.
        if last_error:find(": veto ", 1, true) and
            last_error:find("rejected placement", 1, true) then
            return nil, last_error
        end

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

    if map then
        context.used:add_map(vault, map)
    else
        context.used:add(vault)
    end

    for _, operation in ipairs(vault.operations) do
        if operation.kind == directives.HOOK_POST_PLACE then
            local api = controller.new(builder, context, placed, extra.place,
                vault.id, map)

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

-- Track arrival, chance controllers, children, and ordinary maps together
-- so later floors can reconstruct source uniqueness from one saved ID list.
function extra.generate(ctx, builder, context)
    local placed = {}

    context.used = used.new(context.prior_vault_ids)

    if context.arrival_vault then
        context.used:add(context.arrival_vault)
    end

    -- The primary layout may already contain tagged DES rooms. Include
    -- their names and unique tags before secondary vault selection, and
    -- return their IDs in the same saved placement history.
    for _, id in ipairs(context.primary_room_ids or {}) do
        context.used:add(catalog.get(id))
    end

    -- An authored branch ending owns its floor before optional maps spend
    -- draws or reserve cells. Its occupied region joins the protected set.
    local end_primary = end_vault.place(ctx, builder, context,
        placed, extra.place)

    for _, map in ipairs(overflow_placement.place(ctx, builder,
        context, extra.place)) do
        placed[#placed + 1] = map
    end

    local primary = place_chance_stage(ctx, builder, context, placed)
    local explicit = place.place(ctx, builder, context, placed,
        extra.place, place_chance_map)
    local branch_regular = regular.place(ctx, builder, context,
        placed, extra.place)
    local ordinary = minivault.place(ctx, builder, context,
        placed, extra.place, place_chance_map)
    unique_placement.place(ctx, builder, context, placed, extra.place)

    -- A whole-floor sea border is decoded after every secondary vault has
    -- placed. Preserve those later authored cells as well as the end map's
    -- stair corridors, or the border would drown their saved entities.
    for _, map in ipairs(placed) do
        for _, record in ipairs(map.records or {}) do
            if record.kind == effects.BORDER_FILL then
                local preserved = {}

                for coordinate in
                    (record.arguments.preserve_cells or ""):gmatch("[^|]+") do
                    preserved[coordinate] = true
                end

                for coordinate in pairs(context.protected) do
                    preserved[coordinate] = true
                end

                local keys = {}

                for coordinate in pairs(preserved) do
                    keys[#keys + 1] = coordinate
                end

                table.sort(keys)
                record.arguments.preserve_cells = table.concat(keys, "|")
            end
        end
    end

    return placed, end_primary or primary or explicit or
        branch_regular or ordinary,
        context.used:ids()
end

-- Add a stair or arrival point to the protected-cell set before extra placement.
function extra.protect(protected, point)
    protected[key(point.x, point.y)] = true
end

return extra
