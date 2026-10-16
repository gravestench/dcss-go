local definitions = require("policy.catalog")
local catalog = require("policy.item_generation.catalog")
local classes = require("ids.object_classes")
local ids = require("ids.items")
local item_sets = require("policy.item_generation.item_sets")
local sets = require("constants.item_sets")
local source = require("policy.item_generation.source_roll")

local policy = {}

local late_charges = {
    [ids.WAND_ICEBLAST] = 8,
    [ids.WAND_ROOTS] = 8,
    [ids.WAND_ACID] = 8,
    [ids.WAND_LIGHT] = 8,
    [ids.WAND_QUICKSILVER] = 8,
    [ids.WAND_CHARMING] = 8,
    [ids.WAND_PARALYSIS] = 8,
    [ids.WAND_POLYMORPH] = 8,
}

function policy.eligible(ctx, definition, request)
    if definition.class ~= classes.OBJ_WANDS then
        return false
    end

    if request.kind_id == definition.id then
        return definition.generation.mode ~= "none"
    end

    return definition.generation.mode == "random" and
        item_sets.allowed(ctx, ctx:player(), definition.id)
end

function policy.weight(_, definition)
    return definition.generation.weight or 0
end

function policy.pick(ctx, request)
    local player = ctx:player()
    local rows = {
        {
            id = ids.WAND_FLAME,
            weight = 14,
        },
        {
            id = item_sets.choice(ctx, player, sets.BLAST_WANDS),
            weight = 14,
        },
        {
            id = item_sets.choice(ctx, player, sets.HEX_WANDS),
            weight = 14,
        },
        {
            id = item_sets.choice(ctx, player, sets.BEAM_WANDS),
            weight = 9,
        },
        {
            id = ids.WAND_POLYMORPH,
            weight = 7,
        },
        {
            id = ids.WAND_MINDBURST,
            weight = 7,
        },
        {
            id = ids.WAND_DIGGING,
            weight = 5,
        },
    }

    -- A mod can add a wand with its own positive generation weight.
    for _, definition in ipairs(definitions.all("items")) do
        if definition.class == classes.OBJ_WANDS and
            policy.eligible(ctx, definition, request) and
            policy.weight(ctx, definition) > 0 then
            rows[#rows + 1] = {
                id = definition.id,
                weight = policy.weight(ctx, definition),
            }
        end
    end

    return source.weighted(ctx, rows)
end

function policy.roll(ctx, definition, request, result)
    -- Source: item-prop.cc:1433-1456; makeitem.cc:1259-1261.
    local maximum = 24

    if definition.id == ids.WAND_DIGGING then
        maximum = 9
    elseif definition.id == ids.WAND_FLAME then
        maximum = request.depth > 7 and 16 or 32
    elseif late_charges[definition.id] then
        maximum = request.depth > 7 and 8 or 15
    elseif request.depth > 7 then
        maximum = 12
    end

    result.charges = 1 + source.average(ctx, maximum, 2)
end

catalog.register(classes.OBJ_WANDS, policy)

return policy
