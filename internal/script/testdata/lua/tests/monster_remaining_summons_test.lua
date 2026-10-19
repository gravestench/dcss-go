local effects = require("policy.combat.monster_spells")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local save_summons = require("policy.save.summons")
local tentacles = require("policy.magic.effects.summons.tentacle")

local test = {}

local function valid_save(ctx, entity)
    local ai = ctx:get(entity, component.AI)

    ai.memory_until_aut = ai.memory_until_aut or 0
    ai.target_x = ai.target_x or 0
    ai.target_y = ai.target_y or 0

    save_summons.validate(ctx, entity,
        ctx:get(entity, component.ACTOR),
        ctx:get(entity, component.POSITION),
        ai,
        ctx:get(entity, component.SUMMON), 0)
end

local function dance_test(ctx)
    local game = fixture.observed_context(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_ORC, 2, 2)
    local foe = fixture.actor(ctx, monsters.MONS_ORC, 6, 2)

    game.random = function()
        return 0
    end

    local ok, dance = pcall(effects.effect, spells.SPELL_SHEZAS_DANCE)
    harness.truthy(ok, "Sheza's Dance has a production effect")
    dance.resolve(game, caster, foe, nil, dance.plan(game, caster, foe))

    local count = 0

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local state = ctx:get(entity, component.SUMMON)

        if state.owner == caster then
            count = count + 1
            valid_save(game, entity)
            harness.equal(ctx:get(entity, component.ACTOR).kind_id,
                monsters.MONS_DANCING_WEAPON, "dance creates weapons")
            harness.truthy(ctx:get(entity, component.MONSTER_BOONS).haste_aut > 0,
                "dancing weapons start hasted")
        end
    end

    harness.equal(count, 2, "minimum source dance count")
end

local function chaos_test(ctx)
    local game = fixture.observed_context(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_ORC, 22, 22)
    local ally = fixture.actor(ctx, monsters.MONS_ORC, 23, 22)
    local ok, effect = pcall(effects.effect, spells.SPELL_CALL_OF_CHAOS)

    harness.truthy(ok, "Call of Chaos has a production effect")
    game.random = function(_, _, bound)
        return bound == 660 and 450 or 0
    end

    effect.resolve(game, caster, game:player(), nil,
        effect.plan(game, caster, game:player()))

    local damage = require("policy.magic.damage")
    harness.equal(damage.monster_elemental(game, ally, 12, "MR_RES_FIRE"),
        6, "chaos Resistance affects real damage")
    local profiles = require("policy.combat.monster_profile")
    local definition = damage.monster(game, ally)
    local twice = profiles.definition(game, ally, definition)

    harness.equal(damage.elemental(12, twice, "MR_RES_FIRE"), 6,
        "repeated profile reads do not stack Resistance")
    require("policy.combat.monster_enchant").dispel(game, ally, definition)
    harness.equal(damage.monster_elemental(game, ally, 12, "MR_RES_FIRE"), 12,
        "dispel removes monster Resistance")
    harness.truthy(not ctx:has(caster, "combat.monster_resistance"),
        "Call of Chaos excludes its caster")
end

-- The source's eight weighted outcomes must all change their actual
-- status owner, including rare debuffs; none may fall through as a no-op.
local function chaos_outcomes(ctx)
    local effect = effects.effect(spells.SPELL_CALL_OF_CHAOS)
    local cases = {
        {
            draw = 0,
            component = component.MONSTER_BOONS,
            field = "haste_aut",
        },

        {
            draw = 150,
            component = component.MONSTER_BOONS,
            field = "might_aut",
        },

        {
            draw = 300,
            component = component.MONSTER_CHAOS,
            field = "agility_aut",
        },

        {
            draw = 450,
            component = "combat.monster_resistance",
            field = "remaining_aut",
        },

        {
            draw = 600,
            component = component.MONSTER_LOWERED_WILL,
            field = "remaining_aut",
        },

        {
            draw = 615,
            component = component.MONSTER_ALLEGIANCE,
            field = "frenzy_aut",
        },

        {
            draw = 630,
            component = component.MONSTER_POLYMORPH,
        },

        {
            draw = 645,
            component = component.INNER_FLAME,
            field = "remaining_aut",
        },

    }

    for index, case in ipairs(cases) do
        local game = fixture.observed_context(ctx)
        local caster = fixture.actor(ctx, monsters.MONS_ORC, 200 + 20 * index, 200)
        local ally = fixture.actor(ctx, monsters.MONS_ORC, 201 + 20 * index, 200)

        game.random = function(_, _, bound)
            return bound == 660 and case.draw or 0
        end

        effect.resolve(game, caster, game:player(), nil,
            effect.plan(game, caster, game:player()))

        local state = ctx:get(ally, case.component)
        harness.truthy(state, "Chaos choice " .. index .. " applies saved state")

        if case.field then
            harness.truthy(state[case.field] > 0,
                "Chaos choice " .. index .. " has positive duration")
        end
    end
end

local function gateway_test(ctx)
    local game = fixture.observed_context(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_ORC, 42, 42)
    local ok, effect = pcall(effects.effect, spells.SPELL_MALIGN_GATEWAY)

    harness.truthy(ok, "Malign Gateway has a monster effect")
    game.random = function()
        return 0
    end
    game.set_cell = function(_, _, x, y, feature)
        game.cells[x .. ":" .. y] = feature
    end

    local plan = effect.plan(game, caster, game:player())
    harness.truthy(plan, "gateway plans a free destination")
    effect.resolve(game, caster, game:player(), nil, plan)
    harness.truthy(not effect.plan(game, caster, game:player()),
        "an existing gateway prevents a second cast")

    for _, marker in ipairs(ctx:query({ component.SUMMON_GATEWAY })) do
        local state = ctx:get(marker, component.SUMMON_GATEWAY)
        harness.equal(state.owner, marker, "gateway has durable non-actor ownership")
        harness.equal(state.attitude, "hostile", "gateway inherits hostility")
        harness.equal(state.power, 200, "monster gateway source power")
        game:move_actor(game:player(), 2, 7, 7)
        require("systems.magic_summon_gateway").update(game, game:player())
        harness.equal(#ctx:query({ "world.cloud" }), 0,
            "pending portal does not emit clouds on an inactive floor")
        game:move_actor(game:player(), 1, 7, 7)
        state.expires_aut = 0
        ctx:set(marker, component.SUMMON_GATEWAY, state)
    end

    ctx:destroy(caster)
    require("systems.magic_summon_gateway").update(game, game:player())

    for _, marker in ipairs(ctx:query({ component.SUMMON_GATEWAY })) do
        local state = ctx:get(marker, component.SUMMON_GATEWAY)
        local head = ctx:entity(state.tentacle_id)
        harness.truthy(head, "portal produces its tentacle after caster death")
        harness.equal(state.owner, marker, "emerged gateway has no head save dependency")
        harness.equal(ctx:get(head, component.SUMMON).expires_aut, 0,
            "portal timer owns lifetime instead of ordinary abjuration")
        harness.truthy(ctx:has(head, "combat.portal_tentacle"),
            "tentacle saves portal and pacification timers")
    end
end

local function druid_test(ctx)
    local game = fixture.observed_context(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_SPRIGGAN_DRUID, 60, 60)
    local beast = fixture.actor(ctx, monsters.MONS_WOLF, 90, 90)
    local foe = game:player()
    game:move_actor(foe, 1, 50, 50)
    game.level_size = function()
        return 200, 200
    end
    local ok, effect = pcall(effects.effect, spells.SPELL_DRUIDS_CALL)

    harness.truthy(ok, "Druid's Call has a production effect")
    game.visible = function(_, _, x, y, radius, tx, ty)
        return math.max(math.abs(x - tx), math.abs(y - ty)) <= radius
    end
    game.random = function()
        return 0
    end

    effect.resolve(game, caster, foe, nil, effect.plan(game, caster, foe))

    local position = ctx:get(beast, component.POSITION)
    harness.truthy(position.x ~= 90 or position.y ~= 90,
        "Druid's Call relocates an existing distant beast")
    harness.truthy(ctx:has(beast, "combat.called_beast"),
        "called beast remembers its pursuit target")
    harness.truthy(not ctx:has(beast, component.SUMMON),
        "called beast is not a new expiring summon")
    local call = ctx:get(beast, "combat.called_beast")
    harness.equal(call.target_id, ctx:id(foe), "patrol stores a durable foe ID")
    harness.equal(call.caller, nil, "patrol does not retain its caller")
    ctx:destroy(caster)
    ctx:destroy(foe)
    require("systems.combat_called_beast").update(game, beast)
    harness.truthy(not ctx:has(beast, "combat.called_beast"),
        "patrol ends safely when its target died before the beast acted")
end

local function tentacle_test(ctx)
    local game = fixture.observed_context(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_TENTACLED_STARSPAWN, 120, 120)
    local ok, effect = pcall(effects.effect, spells.SPELL_CREATE_TENTACLES)

    harness.truthy(ok, "Create Tentacles has a production effect")
    game.random = function()
        return 0
    end

    effect.resolve(game, caster, game:player(), nil,
        effect.plan(game, caster, game:player()))

    local children = ctx:query({ "combat.attached_tentacle" })
    harness.equal(#children, 2, "starspawn grows two connected tentacles")
    harness.truthy(not effect.plan(game, caster, game:player()),
        "full tentacle quota rejects another cast")

    local head = children[1]
    game:move_actor(head, 1, 123, 120)
    tentacles.refresh(game, head)

    local segments = ctx:query({ component.SUMMON_SEGMENT })
    harness.truthy(#segments > 0, "moving head creates saved connectors")

    for _, segment in ipairs(segments) do
        valid_save(game, segment)
    end

    local injury = ctx:get(segments[1], component.HEALTH)
    injury.current = 1
    ctx:set(segments[1], component.HEALTH, injury)
    tentacles.refresh(game, head)
    harness.equal(ctx:get(head, component.HEALTH).current, 1,
        "connector damage propagates to the attached head")

    local retract = tentacles.act(game, head, ctx:get(head, component.POSITION))
    harness.equal(retract.kind, require("constants.intent").MONSTER_MOVE,
        "an attached tentacle retracts when its parent has no foe")

    for _, child in ipairs(children) do
        harness.equal(ctx:get(child, "combat.attached_tentacle").parent,
            caster, "tentacle persists its parent")
        harness.equal(ctx:get(child, component.ACTOR).kind_id,
            monsters.MONS_STARSPAWN_TENTACLE, "correct child species")
    end
end

function test.run(ctx)
    dance_test(ctx)
    chaos_test(ctx)
    chaos_outcomes(ctx)
    gateway_test(ctx)
    druid_test(ctx)
    tentacle_test(ctx)
end

return test
