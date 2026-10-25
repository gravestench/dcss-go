-- A Ru sacrifice is a historical mutation grant. Demonspawn silver damage
-- reads that saved history even after another mutation changes later.
local component = require("constants.component")
local forms = require("constants.form_ids")
local harness = require("tests.harness")
local missile = require("ids.items")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local silver = require("policy.combat.monster_missile_egos.silver")
local species = require("ids.species")
local fixture = require("tests.fixtures.ranged_reflection")

local test = {}

-- Use the ordinary player damage owner; a zero draw makes the source
-- minimum silver fragment exactly one HP for a 100-damage contact.
local function scene(ctx, species_id, sacrifice_count, transformed)
    local battle, player, shooter = fixture.scene(ctx,
        missile.MI_BOOMERANG, false, nil, false)
    local identity = ctx:get(player, component.PLAYER)
    local health = ctx:get(player, component.HEALTH)

    identity.species_id = species_id
    health.current = 100
    health.max = 100
    ctx:set(player, component.PLAYER, identity)
    ctx:set(player, component.HEALTH, health)

    ctx:add(player, component.RELIGION_RU, {
        sacrifice_mutations = sacrifice_count,
    })

    if species_id == species.SP_DEMONSPAWN then
        records.grant_innate(ctx, player, mutations.MUT_HORNS, 3)
    else
        records.grant_acquired(ctx, player, mutations.MUT_HORNS, 3)
    end

    if transformed then
        ctx:add(player, component.PLAYER_FORM, {
            form_id = forms.DRAGON,
        })
    end

    function battle.random()
        return 0
    end

    return battle, player, shooter
end

-- A Demonspawn with no Ru history takes the mutation term; after one
-- sacrifice, the pinned source's repeated subtraction leaves only the
-- minimum. Other species and shapechange retain their separate rules.
function test.run(ctx)
    local ordinary, plain_player, plain_shooter = scene(ctx,
        species.SP_DEMONSPAWN, 0, false)

    silver.apply(ordinary, plain_shooter, nil, nil, 100)
    harness.equal(ctx:get(plain_player, component.HEALTH).current, 85)

    local sacrificed, ru_player, ru_shooter = scene(ctx,
        species.SP_DEMONSPAWN, 1, false)

    silver.apply(sacrificed, ru_shooter, nil, nil, 100)
    harness.equal(ctx:get(ru_player, component.HEALTH).current, 99)

    local human, human_player, human_shooter = scene(ctx,
        species.SP_HUMAN, 1, false)

    silver.apply(human, human_shooter, nil, nil, 100)
    harness.equal(ctx:get(human_player, component.HEALTH).current, 85)

    local dragon, dragon_player, dragon_shooter = scene(ctx,
        species.SP_DEMONSPAWN, 1, true)

    silver.apply(dragon, dragon_shooter, nil, nil, 100)
    harness.equal(ctx:get(dragon_player, component.HEALTH).current, 25)
end

return test
