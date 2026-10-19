-- Ensnare must use a real projectile hit before making a saved web hold.
-- The test imports the production beam profile and restraint policy.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local attitudes = require("constants.attitude")
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local fixture = require("tests.fixtures.monster_status")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local species = require("ids.species")
local forms = require("policy.magic.effects.forms.player")
local held = require("policy.traps.held")
local save_traps = require("policy.save.traps")

local test = {}

-- A clear shot plans the original foe. A landed hit applies the same web
-- and trap placement that a chaos web uses, without an HP damage roll.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {})

    local caster = fixture.actor(ctx,
        monsters.MONS_ARACHNE, 1, 1, 30)
    local victim = fixture.actor(ctx,
        monsters.MONS_GOBLIN, 3, 1, 10)

    ctx:add(victim, component.SUMMON, {
        owner = player,
        source_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
        attitude = attitudes.FRIENDLY,
        expires_aut = 200,
    })

    local live = fixture.context(ctx, player, 0)
    local effect = effects.effect(spells.SPELL_ENSNARE)
    local profile = catalog.get(categories.MONSTER_BEAMS,
        spells.SPELL_ENSNARE)

    -- Only this simple floor service is absent from the isolated ECS host.
    function live:cell()
        return require("constants.terrain").DNGN_FLOOR
    end

    -- The isolated rule host has no level grid. Keep the shot open and put
    -- only the selected victim on its destination cell.
    function live:walkable()
        return true
    end

    function live:actor_at(_, x, y)
        if x == 3 and y == 1 then
            return victim
        end

        return nil
    end

    harness.equal(profile.monster_tohit.args[1], 22,
        "the source web stream starts at accuracy 22")
    harness.falsy(profile.monster_damage,
        "webbing does not inflict direct hit-point damage")
    local plan = effect.plan(live, caster, victim)

    harness.truthy(plan,
        "a clear five-cell web shot commits its selected foe")

    -- Planning must refuse an opaque cell before the selected actor and
    -- must not consume a beam roll merely to discover that wall.
    local blocked = setmetatable({}, { __index = live })

    function blocked:walkable(_, x)
        return x ~= 2
    end

    harness.falsy(effect.plan(blocked, caster, victim),
        "a wall before the foe makes Ensnare ineligible")

    effect.resolve(live, caster, victim, nil, plan)

    harness.truthy(ctx:has(victim, component.TRAP_HELD),
        "a landed projectile stores web restraint on the victim")
    harness.equal(ctx:get(victim, component.HEALTH).current, 10,
        "a web hit does not deal HP damage")
    harness.falsy(effect.after_hit(live, caster, victim),
        "a second web hit does not duplicate the hold")

    local giant = fixture.actor(ctx,
        monsters.MONS_STONE_GIANT, 4, 1, 50)

    harness.falsy(effect.after_hit(live, caster, giant),
        "a giant cannot gain a web hold after projectile contact")
    harness.falsy(ctx:has(giant, component.TRAP_HELD),
        "an immune hit leaves no orphaned hold")

    local transformed = fixture.actor(ctx,
        monsters.MONS_HUMAN, 5, 1, 30)

    ctx:add(transformed, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    -- A live transformation changes web eligibility without changing the
    -- saved species choice. Spider is immune; Dragon is too large.
    ctx:add(transformed, component.PLAYER_FORM, {
        form_id = forms.profile(spells.SPELL_SPIDER_FORM).id,
        remaining_aut = 100,
    })

    harness.falsy(effect.after_hit(live, caster, transformed),
        "Spider Form is web immune")
    harness.falsy(ctx:has(transformed, component.TRAP_HELD),
        "an immune player gets no saved web state")

    local form = ctx:get(transformed, component.PLAYER_FORM)

    form.form_id = forms.profile(spells.SPELL_DRAGON_FORM).id
    ctx:set(transformed, component.PLAYER_FORM, form)

    harness.falsy(effect.after_hit(live, caster, transformed),
        "Dragon Form is too large for a web")
    harness.falsy(ctx:has(transformed, component.TRAP_HELD),
        "a giant form gets no saved web state")

    form.remaining_aut = 0
    ctx:set(transformed, component.PLAYER_FORM, form)

    harness.truthy(effect.after_hit(live, caster, transformed),
        "an untransformed human can be caught by a web")
    harness.truthy(save_traps.validate(live, { levels = {} }),
        "a player web and floor trap pass the production save validator")

    -- A successful escape removes both the actor condition and the
    -- temporary floor trap, so restoring later cannot find a dangling web.
    function live:random(_, bound)
        return bound - 1
    end

    harness.truthy(held.escape(live, transformed),
        "a player can escape the projectile web")
    harness.falsy(ctx:has(transformed, component.TRAP_HELD),
        "escape clears the player restraint")
    harness.truthy(save_traps.validate(live, { levels = {} }),
        "the post-escape world has no dangling saved web")
end

return test
