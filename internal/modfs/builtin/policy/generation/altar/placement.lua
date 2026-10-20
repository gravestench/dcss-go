-- Theory of operation: the Temple plan reserves god groups and depths at
-- new game. When a scheduled Dungeon floor is built, this module draws one
-- eligible source overflow map per group, places it through the ordinary
-- vault geometry path, and binds its altars to the saved gods. The .des map
-- owns terrain and monsters; the plan owns altar identity.
local catalog = require("policy.generation.altar.catalog")
local branches = require("ids.branches")
local effects = require("constants.vault_effects")
local glyphs = require("constants.vault_glyphs")
local god_names = require("constants.god_names")
local limits = require("constants.overflow_altars")
local settings = require("constants.vault_settings")
local chance = require("constants.vault_chance")
local depth_rules = require("policy.generation.vaults.depth")
local eligibility = require("policy.generation.vaults.eligibility")
local weights = require("policy.generation.vaults.weight")

local placement = {}

-- Use the same god-name catalog for source tag matching and the altars'
-- DES feature tokens. Modded god names therefore have one spelling owner.
local function god_suffix(id)
    local name = god_names[id]

    if not name then
        error("overflow map has unknown scheduled god " .. tostring(id))
    end

    return name:lower():gsub(" ", "_")
end

-- Keep scheduled group order when building the source's specialized tag
-- request. A generic request uses only the altar count.
local function group_tag(group)
    local result = limits.COUNT_TAG .. #group.god_ids

    for _, id in ipairs(group.god_ids) do
        result = result .. " " .. limits.COUNT_TAG .. god_suffix(id)
    end

    return result
end

-- Match all source tags and the same branch, depth, species, layout, and
-- uniqueness rules used by other vault selectors before consuming a draw.
local function candidates(builder, context, tags)
    local result = {}
    local total = 0

    for _, id in ipairs(catalog.ids()) do
        local definition = catalog.get(id)
        local has_tags = true

        for _, tag in ipairs(tags) do
            has_tags = has_tags and definition.tags[tag]
        end

        if has_tags and eligibility.tag(definition, context) then
            local weight = weights.for_branch(definition,
                context.branch_id, context.depth, context.branch_bottom,
                context.absolute_depth)
            local odds = depth_rules.chance(definition,
                context.branch_id, context.depth, context.branch_bottom,
                context.absolute_depth)

            if weight > 0 and (odds == chance.ROLL or
                (odds > 0 and builder:roll(chance.ROLL) < odds)) then
                total = total + weight
                result[#result + 1] = {
                    definition = definition,
                    limit = total,
                }
            end
        end
    end

    return result, total
end

-- Draw from sorted source IDs and positive weights. A failed specialized
-- request may use generic maps, but a missing generic pool is a content
-- error rather than permission to silently omit a scheduled god.
local function weighted_map(builder, context, tags)
    local available, total = candidates(builder, context, tags)

    if total == 0 then
        return nil
    end

    local draw = builder:roll(total)

    for _, entry in ipairs(available) do
        if draw < entry.limit then
            return entry.definition
        end
    end

    error("overflow map draw exceeded source weights")
end

-- DCSS first tries a god-specific map for multi-god groups, or on a coin
-- flip for one god, then falls back to a generic count map. Keep the tag
-- used for the winning draw in local hook context.
local function choose_map(builder, context, group)
    local count = #group.god_ids
    local specialist

    if count > 1 or builder:roll(2) == 0 then
        local tags = { limits.COUNT_TAG .. count }

        for _, id in ipairs(group.god_ids) do
            tags[#tags + 1] = limits.COUNT_TAG .. god_suffix(id)
        end

        specialist = weighted_map(builder, context, tags)
    end

    if specialist then
        return specialist, group_tag(group)
    end

    local generic_tag = limits.GENERIC_TAG .. count
    local generic = weighted_map(builder, context, { generic_tag })

    if not generic then
        error("no eligible overflow altar map for " .. group_tag(group) ..
            " on Dungeon:" .. context.depth)
    end

    return generic, generic_tag
end

-- KFEAT can name a fixed altar or offer alternatives. A scheduled group
-- admits only its own gods; drawing among multiple matching alternatives
-- preserves a source choice without changing the saved partition.
local function explicit_god(record, group, builder)
    if record.kind ~= effects.FEATURE then
        return nil
    end

    local allowed = {}

    for _, id in ipairs(group.god_ids) do
        allowed["altar_" .. god_suffix(id)] = id
    end

    local options = {}

    for part in (record.identity .. "/"):gmatch("(.-)/") do
        local feature = part:match("altar_[a-z_]+")
        local id = feature and allowed[feature]

        if id then
            options[#options + 1] = id
        end
    end

    if #options == 0 then
        return nil
    end

    return options[builder:roll(#options) + 1]
end

-- Source B is a random altar placeholder; KFEAT may spell it as B too.
-- Exclude overwritten records so an explicit feature cannot count twice.
local function placeholder(record)
    if record.overridden then
        return false
    end

    return record.kind == effects.SOURCE_FEATURE and
        record.identity == glyphs.terrain.B or
        record.kind == effects.FEATURE and record.identity == "B"
end

-- Preserve the authored feature as an argument for inspection while the
-- live grid uses one altar terrain ID and the bound god ID for rendering.
local function bind(record, id)
    local arguments = {}

    for key, value in pairs(record.arguments or {}) do
        arguments[key] = value
    end

    arguments.god_id = id
    arguments.source_feature = record.identity
    record.arguments = arguments
    record.kind = effects.SOURCE_FEATURE
    record.identity = glyphs.terrain.B
    record.pending = false
end

-- Fixed altars consume their named gods first. Remaining saved gods fill
-- random B placeholders in row order, independent of DES operation order.
local function assign_altars(placed, group, builder)
    local assigned = {}
    local random_sites = {}

    for _, record in ipairs(placed.records) do
        if not record.overridden then
            local id = explicit_god(record, group, builder)

            if id then
                if assigned[id] then
                    error("overflow map " .. placed.id ..
                        " repeats scheduled altar " .. id)
                end

                bind(record, id)
                assigned[id] = true
            elseif placeholder(record) then
                random_sites[#random_sites + 1] = record
            end
        end
    end

    table.sort(random_sites, function(left, right)
        return left.y < right.y or
            left.y == right.y and left.x < right.x
    end)

    local remaining = {}

    for _, id in ipairs(group.god_ids) do
        if not assigned[id] then
            remaining[#remaining + 1] = id
        end
    end

    if #remaining ~= #random_sites then
        error("overflow map " .. placed.id .. " has " ..
            #random_sites .. " random altars for " ..
            #remaining .. " scheduled gods")
    end

    for index, record in ipairs(random_sites) do
        bind(record, remaining[index])
    end
end

-- Give each placed map a local selected-count and tag setting. Sharing the
-- surrounding context would let one group's hooks alter the next group.
local function group_context(context, group, tag)
    local child = {}

    for key, value in pairs(context) do
        child[key] = value
    end

    child.player = {}

    for key, value in pairs(context.player or {}) do
        child.player[key] = value
    end

    child.player.map_tag = tag
    child.player.settings = {
        [settings.OVERFLOW_ALTAR_COUNT] = #group.god_ids,
    }

    return child
end

-- Place every group scheduled for this floor before ordinary extras can
-- occupy its cells. A fit failure stops generation with the scheduled god
-- list intact; no other god or map is silently substituted.
function placement.place(ctx, builder, context, place)
    local placed = {}

    if context.branch_id ~= branches.BRANCH_DUNGEON then
        return placed
    end

    for _, group in ipairs(context.overflow_schedule or {}) do
        if group.depth == context.depth then
            local vault, tag = choose_map(builder, context, group)
            local child = group_context(context, group, tag)
            local map, reason = place(ctx, builder, vault, child)

            if not map then
                error("cannot place scheduled overflow map " .. vault.id ..
                    ": " .. tostring(reason))
            end

            assign_altars(map, group, builder)
            context.used:add(vault)
            placed[#placed + 1] = map
        end
    end

    return placed
end

return placement
