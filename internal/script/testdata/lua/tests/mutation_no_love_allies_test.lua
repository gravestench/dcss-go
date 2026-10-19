
local allies = require("policy.character.allies")
local attitude = require("constants.attitude")
local availability = require("policy.character.skill_availability")
local catalog = require("policy.catalog")
local component = require("constants.component")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local levels = require("policy.mutations.levels")
local records = require("policy.mutations.records")
local spells = require("ids.spells")
local targets = require("policy.ai.targets")
local necrotise = require("policy.magic.effects.zaps.necrotise")
local zap_ids = require("policy.magic.effects.zaps.ids")
local harness = require("tests.harness")

local test = {}

-- Bind no love allies player lookup to this owner while preserving live ECS component reads.
local function player_context(ctx, player)
    local proxy = setmetatable({}, { __index = ctx })

    -- Bind policy ownership to no love allies fixture actor so player-only branches execute on that entity.
    function proxy.player()
        return player
    end

    return proxy
end

-- Create an owned summon or hostile actor for No Love checks.
local function monster(ctx, kind_id, owner, spell_id)
    local entity = ctx:create()

    ctx:add(entity, component.ACTOR, {
        kind_id = kind_id,
        speed = 10,
    })

    if spell_id then
        ctx:add(entity, component.SUMMON, {
            owner = owner,
            source_id = spell_id,
            expires_aut = 100,
            heads = 0,
        })
    end

    return entity
end

-- Read the same spell eligibility API used by the starting menu.
local function spell_forbidden(ctx, player, id)
    local spell = catalog.get("spells", id)

    return availability.forbidden_spell(ctx, player, spell)
end

-- An existing ally retains attitude until its next action.
function test.run(ctx)
    local player = ctx:create()
    local game = player_context(ctx, player)
    local rat = monster(ctx, monsters.MONS_RAT, player,
        spells.SPELL_SUMMON_SMALL_MAMMAL)
    local foxfire = monster(ctx, monsters.MONS_FOXFIRE, player,
        spells.SPELL_FOXFIRE)
    local golem = monster(ctx, monsters.MONS_GUARDIAN_GOLEM, player,
        spells.SPELL_SUMMON_GUARDIAN_GOLEM)
    local charmed = monster(ctx, monsters.MONS_RAT)

    ctx:add(charmed, component.MONSTER_ALLEGIANCE, {
        charm_aut = 100,
        frenzy_aut = 0,
        fatigue_aut = 0,
    })

    harness.truthy(targets.allied(game, rat),
        "ordinary summons are allied")
    harness.truthy(targets.allied(game, charmed),
        "charmed monsters are allied")
    harness.equal(allies.summoned_attitude(game, player,
        catalog.get("monsters", monsters.MONS_RAT)),
        attitude.FRIENDLY,
        "ordinary player summons a friendly rat")
    harness.falsy(spell_forbidden(game, player,
        spells.SPELL_ANIMATE_DEAD),
        "ordinary player can animate dead")

    records.grant_acquired(ctx, player,
        mutations.MUT_DEMONIC_GUARDIAN, 1)

    -- Establish the ordinary friendly summon before introducing the allegiance ban.
    harness.equal(levels.effective(game, player,
        mutations.MUT_DEMONIC_GUARDIAN), 1,
        "Demonic Guardian is active before No Love")

    records.grant_acquired(ctx, player, mutations.MUT_NO_LOVE, 1)

    harness.truthy(allies.forbidden(game, player),
        "No Love forbids allied creatures")
    harness.equal(levels.effective(game, player,
        mutations.MUT_DEMONIC_GUARDIAN), 0,
        "No Love suppresses the guardian mutation")
    -- Spell legality and monster attitude both consult the same mutation restriction.
    harness.truthy(spell_forbidden(game, player,
        spells.SPELL_SUMMON_SMALL_MAMMAL),
        "No Love forbids Summoning spells")

    for _, id in ipairs({
        spells.SPELL_ANIMATE_DEAD,
        spells.SPELL_DEATH_CHANNEL,
        spells.SPELL_SIMULACRUM,
        spells.SPELL_INFESTATION,
        spells.SPELL_TUKIMAS_DANCE,
    }) do
        harness.truthy(spell_forbidden(game, player, id),
            "No Love forbids the source ally spell " .. id)
    end

    harness.falsy(spell_forbidden(game, player, spells.SPELL_STING),
        "No Love leaves unrelated spells available")
    harness.equal(allies.summoned_attitude(game, player,
        catalog.get("monsters", monsters.MONS_RAT)),
        attitude.HOSTILE,
        "No Love makes a new XP-granting summon hostile")
    harness.equal(allies.summoned_attitude(game, player,
        catalog.get("monsters", monsters.MONS_FOXFIRE)),
        attitude.FRIENDLY,
        "conjured foxfire remains exempt")
    harness.equal(allies.summoned_attitude(game, player,
        catalog.get("monsters", monsters.MONS_GUARDIAN_GOLEM)),
        attitude.FRIENDLY,
        "no-XP golem is exempt at creation")
    -- Existing allies change at their own action boundary, not at mutation grant time.
    harness.truthy(targets.allied(game, rat),
        "an existing ally retains attitude until its next action")

    allies.on_monster_turn(game, rat)
    allies.on_monster_turn(game, charmed)
    allies.on_monster_turn(game, foxfire)
    allies.on_monster_turn(game, golem)

    harness.falsy(targets.allied(game, rat),
        "an existing rat summon becomes hostile when it acts")
    harness.falsy(targets.allied(game, charmed),
        "an existing charmed rat becomes hostile when it acts")
    harness.truthy(targets.allied(game, foxfire),
        "conjured foxfire remains allied after it acts")
    harness.falsy(targets.allied(game, golem),
        "non-conjured golem turns hostile on its next action")
    harness.truthy(targets.enemy(game, player, rat),
        "the player can target a hostile former ally")

    ctx:add(charmed, zap_ids.component.NECROTISE, {
        source = player,
        expires_aut = 10,
    })

    harness.falsy(necrotise.on_death(game, charmed,
        catalog.get("monsters", monsters.MONS_RAT), {}, false, false),
        "No Love prevents a previously marked corpse from being reaped")
end

return test
