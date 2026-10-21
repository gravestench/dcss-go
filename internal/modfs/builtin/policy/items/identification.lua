local appearances = require("policy.items.appearances")
local catalog = require("policy.catalog")
local component = require("constants.component")
local classes = require("ids.object_classes")
local properties = require("policy.items.properties")
local item_ids = require("ids.items")
local cosmetics = require("constants.item_cosmetics")
local pools = require("constants.appearance_pools")
local artefact_flags = require("constants.artefact_flags")
local artefact_kinds = require("constants.artefact_kinds")

local identification = {}
local unenchantable_armour = {
    [item_ids.ARM_QUICKSILVER_DRAGON_ARMOUR] = true,
    [item_ids.ARM_SCARF] = true,
    [item_ids.ARM_ORB] = true,
}

local valid_cosmetics = {
    [cosmetics.NONE] = true,
    [cosmetics.GLOWING] = true,
    [cosmetics.RUNED] = true,
    [cosmetics.EMBROIDERED_SHINY] = true,
}

-- A plus is shown only after type and plus knowledge, and only for enchantable classes.
local function shows_pluses(kind, state)
    if not state.pluses or not state.type then
        return false
    end

    if kind.class == classes.OBJ_WEAPONS then
        return true
    end

    if kind.class == classes.OBJ_ARMOUR then
        if kind.identification_enchantable ~= nil then
            return kind.identification_enchantable
        end

        return not unenchantable_armour[kind.id]
    end

    return kind.class == classes.OBJ_JEWELLERY and
        (kind.identification_has_pluses == true or
            (kind.jewellery and kind.jewellery.pluses == true))
end

-- Removed and enum-only kinds never consume an appearance seed.
local function active(kind)
    return kind.status ~= "removed" and kind.status ~= "enum_only" and
        not kind.explicitly_removed
end

-- Item naming requires the player's own knowledge component, not global catalog state.
local function knowledge(ctx, player)
    local known = ctx:get(player, component.ITEM_KNOWLEDGE)

    if not known then
        error("player lacks item knowledge")
    end

    return known
end

-- Most fixed artefacts reveal themselves by name at creation. The source
-- keeps the Octopus King's same-name ring unidentified via its unided flag.
-- Deriving this from content lets both generation and display agree without
-- persisting a duplicate immutable fact.
function identification.unique_self_identifying(definition)
    local appearance = definition.appearance ~= "" and
        definition.appearance or definition.name

    if definition.name ~= appearance then
        return false
    end

    for _, flag in ipairs(definition.flags or {}) do
        if flag == artefact_flags.UNIDED then
            return false
        end
    end

    return true
end

-- Assign appearances only to active kinds with an unidentified descriptor pool.
local function each_identifiable()
    local definitions = {}

    for _, kind in ipairs(catalog.all("items")) do
        local pool = appearances.pool(kind)

        if active(kind) and pool then
            definitions[#definitions + 1] = {
                kind = kind,
                pool = pool,
            }
        end
    end

    return definitions
end

-- Sparse swap removal draws unique seeds without shuffling the full pool.
local function remove_at(swaps, selected, remaining)
    local tail = remaining - 1
    local seed = swaps[selected] or selected
    swaps[selected] = swaps[tail] or tail

    return seed
end

-- Plain appearances carry source weight; selected seeds are removed from the pool.
local function weighted_draw(ctx, pool, draw)
    if not draw.plain_count then
        draw.plain_count = appearances.primary_count(pool)
        draw.qualified_count = draw.capacity - draw.plain_count
        draw.plain_weight = appearances.weight(pool, 0)
        draw.plain_swaps = {}
        draw.qualified_swaps = {}
        draw.plain_limit = draw.plain_count
    end

    local plain_mass = draw.plain_count * draw.plain_weight
    local total = plain_mass + draw.qualified_count
    local roll = ctx:random("item-appearance", total)

    if roll < plain_mass then
        local selected = math.floor(roll / draw.plain_weight)
        local seed = remove_at(draw.plain_swaps, selected,
            draw.plain_count)
        draw.plain_count = draw.plain_count - 1

        return seed
    end

    local selected = roll - plain_mass
    local seed = draw.plain_limit +
        remove_at(draw.qualified_swaps, selected, draw.qualified_count)
    draw.qualified_count = draw.qualified_count - 1

    return seed
end

-- Scroll and staff pools draw unused seeds uniformly without retries.
local function uniform_draw(ctx, draw)
    local remaining = draw.capacity - draw.count
    local selected = ctx:random("item-appearance", remaining)
    return remove_at(draw.swaps, selected, remaining)
end

-- Assign each identifiable kind a unique descriptor within its pool using the saved run RNG.
-- Example: identification.initialize(ctx, player) assigns distinct potion appearances for this run.
function identification.initialize(ctx, player)
    -- Source: ng-init.cc. A sparse swap table chooses distinct
    -- seeds without retries, including for mod-added item definitions.
    local seeds = {}
    local draws = {}

    for _, entry in ipairs(each_identifiable()) do
        local pool = entry.pool
        local capacity = appearances.capacity(pool)
        local draw = draws[pool]

        if not draw then
            draw = {
                capacity = capacity,
                count = 0,
                swaps = {},
            }
            draws[pool] = draw
        end

        if draw.count >= capacity then
            error("too many item types in appearance pool " .. pool)
        end

        if pool == pools.SCROLL or pool == pools.STAFF then
            seeds[entry.kind.id] = uniform_draw(ctx, draw)
        else
            seeds[entry.kind.id] = weighted_draw(ctx, pool, draw)
        end

        draw.count = draw.count + 1
    end

    ctx:add(player, component.ITEM_KNOWLEDGE, {
        known_types = {},
        seen_types = {},
        appearance_seeds = seeds,
    })
end

-- Merely seeing a weapon or armour type updates knowledge without revealing its enchantment or properties.
function identification.record_seen(ctx, player, kind_ids)
    local known = knowledge(ctx, player)
    known.seen_types = known.seen_types or {}
    local changed = false

    for _, id in ipairs(kind_ids) do
        local kind = catalog.get("items", id)

        if (kind.class == classes.OBJ_WEAPONS or
            kind.class == classes.OBJ_ARMOUR) and
            not known.seen_types[id] then
            known.seen_types[id] = true
            changed = true
        end
    end

    if changed then
        ctx:set(player, component.ITEM_KNOWLEDGE, known)
    end
end

-- A known type can come from global player knowledge or this item's instance state; pluses remain separate.
function identification.known(ctx, player, entity)
    local item = ctx:get(entity, component.ITEM)

    if not item then
        error("item identification requires an item entity")
    end

    local kind = catalog.get("items", item.kind_id)
    local instance = ctx:get(entity, component.ITEM_IDENTIFICATION) or {}
    local known = knowledge(ctx, player)
    local pool = appearances.pool(kind)
    local artefact = ctx:get(entity, component.ITEM_ARTEFACT)

    if artefact then
        local automatic = false

        if artefact.kind == artefact_kinds.UNIQUE then
            local definition = catalog.get("artefacts", artefact.unique_id)
            automatic = identification.unique_self_identifying(definition)
        end

        -- Books are always type-known in the source, including artefact
        -- books. Other artefacts ignore shared base-kind knowledge.
        return {
            type = kind.class == classes.OBJ_BOOKS or automatic or
                instance.known_type == true,
            pluses = automatic or instance.known_pluses == true,
            properties = automatic or
                instance.known_properties == true,
        }
    end

    return {
        type = not pool or known.known_types[item.kind_id] == true or
            instance.known_type == true,
        pluses = instance.known_pluses == true,
        properties = instance.known_properties == true,
    }
end

-- Learning one kind updates player knowledge shared by every item of that kind.
function identification.reveal_type(ctx, player, entity)
    local item = ctx:get(entity, component.ITEM)
    local kind = catalog.get("items", item.kind_id)

    if ctx:has(entity, component.ITEM_ARTEFACT) then
        identification.reveal_item(ctx, entity, {
            type = true,
        })

        return
    end

    if not appearances.pool(kind) then
        return
    end

    local known = knowledge(ctx, player)
    known.known_types[item.kind_id] = true
    ctx:set(player, component.ITEM_KNOWLEDGE, known)
end

-- Instance-only knowledge records pluses and properties without revealing every kind.
function identification.reveal_item(ctx, entity, fields)
    local state = ctx:get(entity, component.ITEM_IDENTIFICATION) or {}
    local artefact = ctx:get(entity, component.ITEM_ARTEFACT)
    local item = ctx:get(entity, component.ITEM)
    local kind = item and catalog.get("items", item.kind_id)
    local equipment = kind and (kind.class == classes.OBJ_WEAPONS or
        kind.class == classes.OBJ_ARMOUR or
        kind.class == classes.OBJ_JEWELLERY or
        kind.class == classes.OBJ_STAVES)
    local manual = kind and kind.id == item_ids.BOOK_MANUAL
    local artefact_book = kind and artefact and
        kind.class == classes.OBJ_BOOKS

    if fields.type then
        state.known_type = true
    end

    if fields.pluses and (equipment or manual) then
        state.known_pluses = true
    end

    if fields.properties and (equipment or manual or artefact_book) then
        state.known_properties = true
    end

    if ctx:has(entity, component.ITEM_IDENTIFICATION) then
        ctx:set(entity, component.ITEM_IDENTIFICATION, state)
    else
        ctx:add(entity, component.ITEM_IDENTIFICATION, state)
    end

    if artefact and fields.properties then
        artefact.known = artefact.known or {}

        for id in pairs(artefact.properties or {}) do
            artefact.known[id] = true
        end

        ctx:set(entity, component.ITEM_ARTEFACT, artefact)
    end
end

-- Stacks need matching identification fields so merging does not leak hidden information.
function identification.compatible(ctx, left, right)
    local first = ctx:get(left, component.ITEM_IDENTIFICATION) or {}
    local second = ctx:get(right, component.ITEM_IDENTIFICATION) or {}

    return (first.known_type or false) == (second.known_type or false) and
        (first.known_pluses or false) ==
            (second.known_pluses or false) and
        (first.known_properties or false) ==
            (second.known_properties or false) and
        (first.cosmetic or 0) == (second.cosmetic or 0)
end

-- A split stack inherits its source item's instance knowledge.
function identification.copy(ctx, source, target)
    local state = ctx:get(source, component.ITEM_IDENTIFICATION)

    if state then
        ctx:add(target, component.ITEM_IDENTIFICATION, state)
    end
end

-- Build the visible name from player knowledge, instance flags, and artefact appearance.
function identification.name(ctx, player, entity)
    local item = ctx:get(entity, component.ITEM)
    local kind = catalog.get("items", item.kind_id)
    local pool = appearances.pool(kind)
    local state = identification.known(ctx, player, entity)
    local name = kind.name
    local artefact = ctx:get(entity, component.ITEM_ARTEFACT)
    local authored = ctx:get(entity, component.VAULT_ITEM_APPEARANCE)

    -- DES itemname changes this instance's visible noun while the catalog
    -- keeps the real weapon kind for damage, skill, and save validation.
    if authored and authored.name ~= "" then
        name = authored.name
    end

    if artefact then
        local named = state.type and artefact.name or artefact.appearance

        if shows_pluses(kind, state) then
            return string.format("%+d %s", item.plus, named)
        end

        return named
    end

    if pool and not state.type then
        local seed = knowledge(ctx, player).appearance_seeds[item.kind_id]

        if seed == nil then
            error("missing appearance for " .. item.kind_id)
        end

        name = appearances.name(pool, seed)
    end

    if state.properties then
        name = properties.name(kind, item.ego, name)
    end

    if not state.pluses and not state.properties then
        local instance = ctx:get(entity, component.ITEM_IDENTIFICATION)
        local cosmetic = instance and instance.cosmetic or cosmetics.NONE
        name = properties.cosmetic(kind, cosmetic, name)
    end

    if shows_pluses(kind, state) then
        name = string.format("%+d %s", item.plus, name)
    end

    if pool == pools.WAND and state.type and item.charges > 0 then
        name = name .. " (" .. item.charges .. ")"
    end

    return name
end

-- Saved appearance seeds must be unique and remain within their pool capacity.
function identification.validate(ctx, player)
    local known = knowledge(ctx, player)
    local expected = {}
    local used = {}

    for _, entry in ipairs(each_identifiable()) do
        local id = entry.kind.id
        local pool = entry.pool
        local seed = known.appearance_seeds[id]

        if type(seed) ~= "number" then
            error("missing item appearance for " .. id)
        end

        appearances.name(pool, seed)
        expected[id] = true
        used[pool] = used[pool] or {}

        if used[pool][seed] then
            error("duplicate " .. pool .. " item appearance")
        end

        used[pool][seed] = true
    end

    for id in pairs(known.appearance_seeds) do
        if not expected[id] then
            error("unknown saved item appearance " .. id)
        end
    end

    for id, value in pairs(known.known_types) do
        if not expected[id] or value ~= true then
            error("invalid known item type " .. id)
        end
    end

    for id, value in pairs(known.seen_types or {}) do
        local okay, kind = pcall(catalog.get, "items", id)

        if not okay or value ~= true or
            (kind.class ~= classes.OBJ_WEAPONS and
                kind.class ~= classes.OBJ_ARMOUR) then
            error("invalid seen item type " .. id)
        end
    end

    for _, entity in ipairs(ctx:query({ component.ITEM_IDENTIFICATION })) do
        local item = ctx:get(entity, component.ITEM)
        local state = ctx:get(entity, component.ITEM_IDENTIFICATION)

        if not item then
            error("non-item has identification state")
        end

        local kind = catalog.get("items", item.kind_id)
        local equipment = kind.class == classes.OBJ_WEAPONS or
            kind.class == classes.OBJ_ARMOUR or
            kind.class == classes.OBJ_JEWELLERY or
            kind.class == classes.OBJ_STAVES
        local manual = kind.id == item_ids.BOOK_MANUAL

        if state.known_type and not appearances.pool(kind) and
            not manual and
            not ctx:has(entity, component.ITEM_ARTEFACT) then
            error("non-identifiable item has type knowledge")
        end

        local artefact_book = kind.class == classes.OBJ_BOOKS and
            ctx:has(entity, component.ITEM_ARTEFACT)

        if (state.known_pluses and not equipment and not manual) or
            (state.known_properties and not equipment and not manual and
                not artefact_book) then
            error("non-equipment item " .. item.kind_id .. " (entity " ..
                ctx:id(entity) .. ") has equipment knowledge")
        end

        if not valid_cosmetics[state.cosmetic] then
            error("invalid item cosmetic")
        end

        if state.cosmetic ~= cosmetics.NONE and
            kind.class ~= classes.OBJ_WEAPONS and
            kind.class ~= classes.OBJ_ARMOUR then
            error("non-equipment item has cosmetic state")
        end

        if state.cosmetic == cosmetics.EMBROIDERED_SHINY and
            kind.class ~= classes.OBJ_ARMOUR then
            error("weapon has armour-only cosmetic state")
        end
    end
end

return identification
