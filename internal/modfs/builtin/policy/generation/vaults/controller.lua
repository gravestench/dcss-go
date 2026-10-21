-- Serial controllers place related DES maps through one bounded Lua API.
local catalog = require("policy.generation.vaults.catalog")
local selection = require("policy.generation.vaults.selection")
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local hooks = require("policy.generation.vaults.hooks")

local controller = {}
local MAX_CHILD_MAPS = 1000

-- Controller random choices use the same layout stream as their maps, so
-- a saved RNG state reproduces the entire serial family on first entry.
function controller.roll(api, bound)
    return api.builder:roll(bound)
end

-- Certain and impossible chances skip a draw, matching source controller
-- functions that call x_chance_in_y with boundary values.
function controller.chance(api, numerator, denominator)
    return numerator >= denominator or
        (numerator > 0 and api:roll(denominator) < numerator)
end

-- Use the builder's one-in primitive for source one_chance_in decisions.
function controller.one_in(api, bound)
    return api.builder:one_in(bound)
end

-- Turn one bounded draw into the source controller's inclusive interval.
function controller.random_range(api, first, last)
    return first + api:roll(last - first + 1)
end

-- A controller can span branches; absolute depth is an optional supplied
-- fact, with its current local depth as the Dungeon fallback.
function controller.absolute_depth(api)
    return api.context.absolute_depth or api.context.depth
end

-- Source map_by_tag asks whether a named pool exists before consuming a
-- conditional draw. Keep this read-only so mod layers can add that pool.
function controller.has_tag(_, tag)
    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.tags[tag] then
            return true
        end
    end

    return false
end

-- Keep the tag request separate from its parent so a child hook sees its
-- own map_tag without changing the next sibling's player context.
local function child_context(parent, tag)
    local child = {}

    for name, value in pairs(parent) do
        child[name] = value
    end

    child.player = {}

    for name, value in pairs(parent.player or {}) do
        child.player[name] = value
    end

    child.player.map_tag = tag
    child.ignore_chance = true

    return child
end

-- A tagged child may itself be a mapless controller. Claim its source ID
-- before invoking its hooks so its own nested draw sees level uniqueness.
-- A child with geometry may also have post-place work after its map fits.
local function run_child_hooks(api, child, vault, map)
    for _, operation in ipairs(vault.operations) do
        if operation.kind == directives.HOOK_POST_PLACE then
            local child_api = controller.new(api.builder, child,
                api.placed, api.place, vault.id, map)

            hooks.run(vault, operation.argument, child_api)
        end
    end
end

-- Place related maps in request order. Optional family and ID constraints
-- keep a composed map's eligibility aligned with its save contract. Source
-- dgn.place_maps skips a map whose geometry cannot fit and counts only
-- successful children. Malformed definitions still error on placement.
function controller.place_maps(api, tag, count, options)
    if type(count) ~= "number" or count < 0 or
        count > MAX_CHILD_MAPS or count ~= math.floor(count) then
        error("serial controller requested an invalid map count")
    end

    local placed_count = 0
    local placed_ids = {}

    options = options or {}

    for _ = 1, count do
        local child = child_context(api.context, tag)
        local excluded = {}

        child.family = options.family or child.family

        for id, blocked in pairs(child.excluded or {}) do
            excluded[id] = blocked
        end

        child.excluded = excluded

        if options.exclude_id then
            child.excluded[options.exclude_id] = true
        end

        -- Child settings are copied for each placement. Source controllers
        -- can pass a boss role or shop without leaking it into siblings.
        local settings = {}

        for name, value in pairs(child.player.settings or {}) do
            settings[name] = value
        end

        for name, value in pairs(options.settings or {}) do
            settings[name] = value
        end

        child.player.settings = settings

        -- A tag draw can choose a map that cannot fit beside the primary.
        -- Exclude only that rejected candidate and redraw from the remaining
        -- effective pool. A failed fit never claims its name or source tag.
        while true do
            local selected = selection.choose_tag(api.builder, tag, child)

            if not selected then
                return placed_count, placed_ids
            end

            local vault = catalog.get(selected.id)
            local map

            if #vault.rows > 0 then
                map = api.place(nil, api.builder, vault, child)
            end

            if map or #vault.rows == 0 then
                if map then
                    api.placed[#api.placed + 1] = map
                    api.context.used:add_map(vault, map)
                else
                    api.context.used:add(vault)
                end

                run_child_hooks(api, child, vault, map)
                placed_count = placed_count + 1
                placed_ids[#placed_ids + 1] = vault.id
                break
            end

            excluded[vault.id] = true
        end
    end

    return placed_count, placed_ids
end

-- Put one tagged child at the exact center requested by a source
-- controller. Reuse the ordinary fitter, history, and child hooks so this
-- path cannot silently bypass unique claims or typed record placement.
function controller.place_tag_at(api, tag, x, y)
    local child = child_context(api.context, tag)

    child.exact_center = {
        x = x,
        y = y,
    }

    local selected = selection.choose_tag(api.builder, tag, child)

    if not selected then
        error("controller has no child tagged " .. tostring(tag))
    end

    local vault = catalog.get(selected.id)

    if #vault.rows == 0 then
        error("exact child placement needs a MAP: " .. vault.id)
    end

    local map, reason = api.place(nil, api.builder, vault, child)

    if not map then
        error("exact child placement failed: " .. tostring(reason))
    end

    api.placed[#api.placed + 1] = map
    api.context.used:add_map(vault, map)
    run_child_hooks(api, child, vault, map)

    return map
end

-- Preserve source whole-level tile choices as a saved, typed controller
-- record. The ASCII client has no tile surface, while a future tiles client
-- can read the same level data without rerunning the source hook.
function controller.level_tiles(api, floor_tile, rock_tile)
    api.placed[#api.placed + 1] = {
        id = api.controller_id,
        occupied = {},
        exits = {},
        records = {
            {
                kind = effects.GENERATION_RULE,
                identity = "level_tiles",
                source_id = api.controller_id,
                vault_id = api.controller_id,
                x = 0,
                y = 0,
                pending = false,
                arguments = {
                    floor_tile = floor_tile,
                    rock_tile = rock_tile,
                },
            },
        },
    }
end

-- A map's pre-place run hook may make a source choice that its post-place
-- controller uses after the map fits. Keep that value local to this attempt.
function controller.recall(api, name)
    local value = api.map and api.map.hook_values and
        api.map.hook_values[name]

    if value == nil then
        error("controller hook memory is missing " .. tostring(name))
    end

    return value
end

-- Bind one ephemeral controller object to its builder, level facts, and
-- already placed maps. Source-specific policy remains in its own Lua file.
function controller.new(builder, context, placed, place, controller_id, map)
    local api = {
        builder = builder,
        context = context,
        placed = placed,
        place = place,
        controller_id = controller_id,
        map = map,
    }

    api.roll = controller.roll
    api.chance = controller.chance
    api.one_in = controller.one_in
    api.random_range = controller.random_range
    api.absolute_depth = controller.absolute_depth
    api.has_tag = controller.has_tag
    api.place_maps = controller.place_maps
    api.place_tag_at = controller.place_tag_at
    api.level_tiles = controller.level_tiles
    api.recall = controller.recall

    return api
end

return controller
