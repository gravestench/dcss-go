
local attributes = require("policy.character.attributes")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

-- Seed attribute effect owner components once so each branch changes only the mutation under test.
local function player(ctx, mutation_id, level)
    local owner = ctx:create()

    ctx:add(owner, "core.attributes", {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })

    records.grant_acquired(ctx, owner, mutation_id, level)

    return owner
end

-- Source player strength query floors at zero.
function test.run(ctx)
    local vectors = {
        {
            id = mutations.MUT_STRONG,
            str = 14,
            int = 9,
            dex = 9,
        },
        {
            id = mutations.MUT_CLEVER,
            str = 9,
            int = 14,
            dex = 9,
        },
        {
            id = mutations.MUT_AGILE,
            str = 9,
            int = 9,
            dex = 14,
        },
        {
            id = mutations.MUT_WEAK,
            str = 8,
            int = 10,
            dex = 10,
        },
        {
            id = mutations.MUT_DOPEY,
            str = 10,
            int = 8,
            dex = 10,
        },
        {
            id = mutations.MUT_CLUMSY,
            str = 10,
            int = 10,
            dex = 8,
        },
        {
            id = mutations.MUT_BIG_BRAIN,
            str = 10,
            int = 12,
            dex = 10,
        },
        {
            id = mutations.MUT_THIN_SKELETAL_STRUCTURE,
            str = 10,
            int = 10,
            dex = 12,
        },
    }

    for _, vector in ipairs(vectors) do
        local owner = player(ctx, vector.id, 1)
        local current = attributes.current(ctx, owner)

        harness.equal(current.strength, vector.str,
            vector.id .. " strength modifier")
        harness.equal(current.intelligence, vector.int,
            vector.id .. " intelligence modifier")
        harness.equal(current.dexterity, vector.dex,
            vector.id .. " dexterity modifier")
    end

    local capped = player(ctx, mutations.MUT_STRONG, 2)
    local base = ctx:get(capped, "core.attributes")

    base.strength = 120
    ctx:set(capped, "core.attributes", base)

    harness.equal(attributes.current(ctx, capped).strength, 125,
        "source maximum stat is 125")
    -- Mutation modifiers belong to the derived query, leaving saved base attributes intact.
    harness.equal(ctx:get(capped, "core.attributes").strength, 120,
        "derived mutation stats do not overwrite base attributes")

    local drained = player(ctx, mutations.MUT_WEAK, 1)
    local low = ctx:get(drained, "core.attributes")

    low.strength = 1
    ctx:set(drained, "core.attributes", low)

    -- The derived floor is applied after all negative and positive stat modifiers.
    harness.equal(attributes.current(ctx, drained).strength, 0,
        "source player strength query floors at zero")
end

return test
