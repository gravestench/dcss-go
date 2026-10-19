-- The Serpent of Hell's four spells each fire three existing effects in
-- source head order. This tests their coordination while the effect modules
-- retain their own separate damage, cloud, and status tests.
local beam = require("policy.combat.monster_beams")
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local harness = require("tests.harness")
local serpent = require("policy.combat.monster_serpent_breath")
local spells = require("ids.spells")
local target_kind = require("constants.target_kind")

local test = {}
local caster = 101
local foe = 202

local cases = {
    {
        spell = spells.SPELL_SERPENT_OF_HELL_GEH_BREATH,
        heads = {
            spells.SPELL_FIRE_BREATH,
            spells.SPELL_FLAMING_CLOUD,
            spells.SPELL_FIREBALL,
        },
        kinds = {
            target_kind.ENTITY,
            target_kind.CELL,
            target_kind.CELL,
        },
    },
    {
        spell = spells.SPELL_SERPENT_OF_HELL_COC_BREATH,
        heads = {
            spells.SPELL_COLD_BREATH,
            spells.SPELL_FREEZING_CLOUD,
            spells.SPELL_FLASH_FREEZE,
        },
        kinds = {
            target_kind.ENTITY,
            target_kind.CELL,
            target_kind.ENTITY,
        },
    },
    {
        spell = spells.SPELL_SERPENT_OF_HELL_DIS_BREATH,
        heads = {
            spells.SPELL_METAL_SPLINTERS,
            spells.SPELL_QUICKSILVER_BOLT,
            spells.SPELL_LEHUDIBS_CRYSTAL_SPEAR,
        },
        kinds = {
            target_kind.ENTITY,
            target_kind.ENTITY,
            target_kind.ENTITY,
        },
    },
    {
        spell = spells.SPELL_SERPENT_OF_HELL_TAR_BREATH,
        heads = {
            spells.SPELL_BOLT_OF_DRAINING,
            spells.SPELL_MIASMA_BREATH,
            spells.SPELL_CORROSIVE_BOLT,
        },
        kinds = {
            target_kind.ENTITY,
            target_kind.CELL,
            target_kind.ENTITY,
        },
    },
}

-- Return only the live fields the composite owner reads. The production
-- component IDs remain authoritative; this fixture declares no schema.
local function context()
    local state = {
        foe_health = 100,
        caster_health = 100,
    }
    local ctx = {}

    -- The composite needs positions to bind direction and health to decide
    -- whether another head may fire. Other state belongs to leaf effects.
    function ctx:get(entity, id)
        if id == component.POSITION then
            if entity == caster then
                return { level_id = 1, x = 1, y = 1 }
            end

            if entity == foe then
                return { level_id = 1, x = 4, y = 1 }
            end
        end

        if id == component.HEALTH then
            if entity == caster then
                return { current = state.caster_health }
            end

            if entity == foe then
                return { current = state.foe_health }
            end
        end

        return nil
    end

    return ctx, state
end

-- Stub the leaf effects so a failure names the wrong head or target shape,
-- rather than depending on hit rolls in twelve independent beam policies.
local function check_case(entry, original_effect)
    local ctx, state = context()
    local seen = {}

    -- Replace only leaf resolution; the production composite still chooses
    -- the head ID and builds each typed plan.
    effects.effect = function(spell_id)
        local effect = {}

        -- Check the saved target for this head without repeating any beam
        -- damage or cloud implementation in the fixture.
        function effect.resolve(_, selected_caster, selected_foe, _, plan)
            local index = #seen + 1

            harness.equal(spell_id, entry.heads[index],
                "Serpent head uses source order")
            harness.equal(selected_caster, caster,
                "head retains the selected caster")
            harness.equal(selected_foe, foe,
                "head retains the selected foe")
            harness.equal(plan.kind, entry.kinds[index],
                "head keeps its beam or area target kind")
            harness.equal(plan.dx, 3, "head keeps the saved x direction")
            harness.equal(plan.dy, 0, "head keeps the saved y direction")

            if plan.kind == target_kind.CELL then
                harness.equal(plan.level_id, 1, "area stays on level")
                harness.equal(plan.x, 4, "area keeps the aim x")
                harness.equal(plan.y, 1, "area keeps the aim y")
            else
                harness.equal(plan.entity, foe, "ray keeps the foe")
            end

            seen[index] = spell_id

            return spell_id
        end

        return effect
    end

    local plan = {
        kind = target_kind.ENTITY,
        entity = foe,
        dx = 3,
        dy = 0,
    }
    local outcomes = serpent.resolve(ctx, caster, foe, nil,
        plan, entry.spell)

    harness.equal(#seen, 3, "one cast resolves three heads")
    harness.equal(#outcomes, 3, "one result is kept for each head")

    for index, head in ipairs(entry.heads) do
        harness.equal(outcomes[index].spell_id, head,
            "head result retains its spell ID")
    end

    -- A dead foe ends the sequence before another head can fire. Source
    -- mons_cast checks whether the target remains after each head.
    effects.effect = function(spell_id)
        local effect = {}

        -- Simulate a lethal first hit so the coordinator must stop before
        -- resolving the second head.
        function effect.resolve()
            state.foe_health = 0
            return spell_id
        end

        return effect
    end

    outcomes = serpent.resolve(ctx, caster, foe, nil, plan, entry.spell)
    harness.equal(#outcomes, 1, "dead foe stops later heads")
    effects.effect = original_effect
end

-- The first tracer uses the composite spell ID, so its own range comes from
-- that spell, while its ray safety rules come from Fire Breath's profile.
function test.run()
    local original_plan = beam.plan
    local original_effect = effects.effect

    -- Inspect the one initial tracer profile; individual heads have no
    -- independent prospect step in this spell family.
    beam.plan = function(_, selected_caster, selected_foe, profile)
        harness.equal(selected_caster, caster, "tracer keeps the caster")
        harness.equal(selected_foe, foe, "tracer keeps the foe")

        return profile
    end

    for _, entry in ipairs(cases) do
        local profile = serpent.plan({}, caster, foe, entry.spell)

        harness.equal(profile.id, entry.spell,
            "tracer reads the composite spell's range")
        check_case(entry, original_effect)
    end

    beam.plan = original_plan
    effects.effect = original_effect
end

return test
