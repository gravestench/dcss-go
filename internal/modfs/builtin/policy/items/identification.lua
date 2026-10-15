local appearances = require("policy.items.appearances")
local catalog = require("policy.catalog")
local component = require("constants.component")
local classes = require("ids.object_classes")
local properties = require("policy.items.properties")
local item_ids = require("ids.items")
local cosmetics = require("constants.item_cosmetics")
local pools = require("constants.appearance_pools")

local identification = {}
local jewellery_pluses = {
    [item_ids.RING_SLAYING] = true,
    [item_ids.RING_PROTECTION] = true,
    [item_ids.RING_EVASION] = true,
    [item_ids.RING_STRENGTH] = true,
    [item_ids.RING_INTELLIGENCE] = true,
    [item_ids.RING_DEXTERITY] = true,
}

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
            jewellery_pluses[kind.id] == true)
end

local function active(kind)
    return kind.status ~= "removed" and kind.status ~= "enum_only" and
        not kind.explicitly_removed
end

local function knowledge(ctx, player)
    local known = ctx:get(player, component.ITEM_KNOWLEDGE)

    if not known then
        error("player lacks item knowledge")
    end

    return known
end

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

local function remove_at(swaps, selected, remaining)
    local tail = remaining - 1
    local seed = swaps[selected] or selected
    swaps[selected] = swaps[tail] or tail

    return seed
end

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

local function uniform_draw(ctx, draw)
    local remaining = draw.capacity - draw.count
    local selected = ctx:random("item-appearance", remaining)
    return remove_at(draw.swaps, selected, remaining)
end

function identification.initialize(ctx, player)
    -- Source: ng-init.cc:326-414. A sparse swap table chooses distinct
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
        appearance_seeds = seeds,
    })
end

function identification.known(ctx, player, entity)
    local item = ctx:get(entity, component.ITEM)

    if not item then
        error("item identification requires an item entity")
    end

    local kind = catalog.get("items", item.kind_id)
    local instance = ctx:get(entity, component.ITEM_IDENTIFICATION) or {}
    local known = knowledge(ctx, player)
    local pool = appearances.pool(kind)

    return {
        type = not pool or known.known_types[item.kind_id] == true or
            instance.known_type == true,
        pluses = instance.known_pluses == true,
        properties = instance.known_properties == true,
    }
end

function identification.reveal_type(ctx, player, entity)
    local item = ctx:get(entity, component.ITEM)
    local kind = catalog.get("items", item.kind_id)

    if not appearances.pool(kind) then
        return
    end

    local known = knowledge(ctx, player)
    known.known_types[item.kind_id] = true
    ctx:set(player, component.ITEM_KNOWLEDGE, known)
end

function identification.reveal_item(ctx, entity, fields)
    local state = ctx:get(entity, component.ITEM_IDENTIFICATION) or {}

    if fields.type then
        state.known_type = true
    end

    if fields.pluses then
        state.known_pluses = true
    end

    if fields.properties then
        state.known_properties = true
    end

    if ctx:has(entity, component.ITEM_IDENTIFICATION) then
        ctx:set(entity, component.ITEM_IDENTIFICATION, state)
    else
        ctx:add(entity, component.ITEM_IDENTIFICATION, state)
    end
end

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

function identification.copy(ctx, source, target)
    local state = ctx:get(source, component.ITEM_IDENTIFICATION)

    if state then
        ctx:add(target, component.ITEM_IDENTIFICATION, state)
    end
end

function identification.name(ctx, player, entity)
    local item = ctx:get(entity, component.ITEM)
    local kind = catalog.get("items", item.kind_id)
    local pool = appearances.pool(kind)
    local state = identification.known(ctx, player, entity)
    local name = kind.name

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

        if state.known_type and not appearances.pool(kind) then
            error("non-identifiable item has type knowledge")
        end

        if (state.known_pluses or state.known_properties) and
            not equipment then
            error("non-equipment item has equipment knowledge")
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
