local streams = require("constants.rng_streams")
local catalog = require("policy.item_generation.catalog")
local definitions = require("policy.catalog")
local armour_egos = require("policy.item_generation.armour_egos")
local egos = require("constants.armour_egos")
local classes = require("ids.object_classes")
local ids = require("ids.items")
local quality = require("constants.vault_item_quality")
local source = require("policy.item_generation.source_roll")

local policy = {}

-- Source: crawl-ref/source/makeitem.cc:995-1079.
local secondary = {
    {
        id = ids.ARM_BOOTS,
        weight = 12,
    },
    {
        id = ids.ARM_GLOVES,
        weight = 12,
    },
    {
        id = ids.ARM_CLOAK,
        weight = 9,
    },
    {
        id = ids.ARM_SCARF,
        weight = 3,
    },
    {
        id = ids.ARM_HELMET,
        weight = 10,
    },
    {
        id = ids.ARM_HAT,
        weight = 2,
    },
    {
        id = ids.ARM_KITE_SHIELD,
        weight = 2,
    },
    {
        id = ids.ARM_BUCKLER,
        weight = 4,
    },
    {
        id = ids.ARM_TOWER_SHIELD,
        weight = 1,
    },
    {
        id = ids.ARM_ORB,
        weight = 3,
    },
}

local high_dragons = {
    ids.ARM_STEAM_DRAGON_ARMOUR,
    ids.ARM_ACID_DRAGON_ARMOUR,
    ids.ARM_STORM_DRAGON_ARMOUR,
    ids.ARM_GOLD_DRAGON_ARMOUR,
    ids.ARM_SWAMP_DRAGON_ARMOUR,
    ids.ARM_PEARL_DRAGON_ARMOUR,
    ids.ARM_SHADOW_DRAGON_ARMOUR,
    ids.ARM_QUICKSILVER_DRAGON_ARMOUR,
}

local exceptional = {
    ids.ARM_CRYSTAL_PLATE_ARMOUR,
    ids.ARM_TROLL_LEATHER_ARMOUR,
    ids.ARM_FIRE_DRAGON_ARMOUR,
    ids.ARM_ICE_DRAGON_ARMOUR,
}

local all_mundane = {
    ids.ARM_ROBE,
    ids.ARM_LEATHER_ARMOUR,
    ids.ARM_RING_MAIL,
    ids.ARM_SCALE_MAIL,
    ids.ARM_CHAIN_MAIL,
    ids.ARM_PLATE_ARMOUR,
}

local middle_mundane = {
    ids.ARM_ROBE,
    ids.ARM_LEATHER_ARMOUR,
    ids.ARM_RING_MAIL,
    ids.ARM_SCALE_MAIL,
    ids.ARM_CHAIN_MAIL,
}

local early_mundane = {
    ids.ARM_ROBE,
    ids.ARM_LEATHER_ARMOUR,
    ids.ARM_RING_MAIL,
}

function policy.eligible(_, definition, request)
    return definition.class == classes.OBJ_ARMOUR and
        (definition.generation.mode == "random" or
            request.kind_id == definition.id and
            definition.generation.mode == "forced")
end

function policy.weight(_, definition)
    return definition.generation.weight or 1
end

function policy.pick(ctx, request)
    local extensions = {}
    local extension_weight = 0

    -- Source armour uses the subtype table below. A layered mod can add
    -- a subtype by giving its definition a positive generation weight.
    for _, definition in ipairs(definitions.all("items")) do
        local generation = definition.generation

        if definition.class == classes.OBJ_ARMOUR and
            generation.mode == "random" and
            (generation.weight or 0) > 0 then
            extensions[#extensions + 1] = {
                id = definition.id,
                weight = generation.weight,
            }
            extension_weight = extension_weight + generation.weight
        end
    end

    if extension_weight > 0 and
        source.chance(ctx, extension_weight, 100 + extension_weight) then
        return source.weighted(ctx, extensions)
    end

    local depth = request.depth

    if source.chance(ctx, 1, 5) then
        return source.weighted(ctx, secondary)
    end

    if source.chance(ctx, 11 + depth, 10000) then
        return source.one_of(ctx, high_dragons)
    end

    if source.chance(ctx, 11 + depth, 8000) then
        return source.one_of(ctx, exceptional)
    end

    if source.chance(ctx, 11 + depth, 60) then
        return source.one_of(ctx, all_mundane)
    end

    if source.chance(ctx, 11 + depth, 35) then
        return source.one_of(ctx, middle_mundane)
    end

    return source.one_of(ctx, early_mundane)
end

function policy.roll(ctx, definition, request, result)
    -- Source: crawl-ref/source/makeitem.cc:1137-1203.
    if definition.id == ids.ARM_BOOTS and source.chance(ctx, 1, 8) then
        result.kind_id = ids.ARM_BARDING
        definition = definitions.get("items", result.kind_id)
    end

    local forced_good = request.quality == quality.GOOD or
        request.quality == quality.SUPERB
    local forced_ego = request.ego and request.ego ~= egos.NORMAL
    local always_ego = definition.id == ids.ARM_SCARF or
        definition.id == ids.ARM_ORB
    if always_ego then
        result.ego = request.ego or armour_egos.roll(ctx, definition)
    elseif forced_good or
        (not definition.armour.mundane and
            (forced_ego or definition.id == ids.ARM_HAT or
                source.chance(ctx, 51 + request.depth, 250))) then
        result.plus = ctx:random(streams.ITEM_GENERATION, 3)

        if definition.slot == "body" and
            source.chance(ctx, 21 + request.depth, 300) then
            result.plus = result.plus + ctx:random(streams.ITEM_GENERATION, 3)
        end

        if forced_ego or source.chance(ctx, 31 + request.depth, 350) then
            result.ego = request.ego or armour_egos.roll(ctx, definition)

            if result.ego == egos.PONDEROUSNESS then
                result.plus = result.plus + 3 +
                    ctx:random(streams.ITEM_GENERATION, 8)
            end
        end
    end

    local maximum = 2

    if definition.slot == "body" or definition.id == ids.ARM_BARDING then
        maximum = definition.armour.ac
    elseif definition.slot == "shield" then
        maximum = math.floor((definition.armour.ac - 3) / 2) + 3
    end

    if definition.id == ids.ARM_QUICKSILVER_DRAGON_ARMOUR or
        always_ego then
        maximum = 0
    end

    result.plus = math.min(result.plus, maximum)

    if not forced_good and result.ego == egos.NORMAL then
        local threshold = 1

        if definition.slot == "body" then
            threshold = 3
        elseif definition.slot == "shield" then
            threshold = 2
        end

        if result.plus < threshold then
            result.plus = 0
        end
    end

    if not armour_egos.allowed(definition) then
        result.ego = egos.NORMAL
    end
end

catalog.register(classes.OBJ_ARMOUR, policy)

return policy
