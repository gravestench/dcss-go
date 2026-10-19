-- A hostile Marshlight uses the normal saved foxfire actors. Their allegiance
-- must come from the caster, so the conjuration attacks the player.
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local fighter = require("policy.combat.fighter")
local fixture = require("tests.monster_ally_support_fixture")
local foxfire = require("policy.magic.effects.summons.foxfire")
local harness = require("tests.harness")
local intent_ids = require("constants.intent")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local test = {}

-- Only two adjacent cells are free. The cast creates two distinct source-owned
-- foxfires and one immediate contact hurts the nearby player.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 7, 5, 50)
    local caster = fixture.actor(ctx,
        monsters.MONS_WILL_O_THE_WISP, 5, 5, 30)
    local game = fixture.context(ctx, player)
    local effect = effects.effect(spells.SPELL_MARSHLIGHT)

    ctx:add(player, component.PLAYER, {})

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                game.walls[(5 + dx) .. ":" .. (5 + dy)] = true
            end
        end
    end

    game.walls["6:5"] = nil
    game.walls["5:6"] = nil

    function game:random()
        return 0
    end

    local plan = effect.plan(game, caster, player)

    harness.truthy(plan, "an open neighboring cell permits Marshlight")
    effect.resolve(game, caster, player, nil, plan)

    local created = {}

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local state = ctx:get(entity, component.SUMMON)

        if state.source_id == spells.SPELL_MARSHLIGHT then
            harness.equal(state.owner, caster,
                "foxfire keeps the monster caster as owner")
            created[#created + 1] = entity
        end
    end

    harness.equal(#created, 2, "Marshlight makes two adjacent foxfires")

    local near

    for _, entity in ipairs(created) do
        local position = ctx:get(entity, component.POSITION)

        if position.x == 6 and position.y == 5 then
            near = entity
        end
    end

    harness.truthy(near, "one foxfire appears next to the player")

    local position = ctx:get(near, component.POSITION)
    local before = ctx:get(player, component.HEALTH).current

    -- The construct can see the player, but source Foxfire contact also
    -- requires its summoner to see the target cell and its own foxfire.
    function game:visible(_, from_x, from_y, _, to_x, to_y)
        return not (from_x == 5 and from_y == 5 and
            to_x == 7 and to_y == 5)
    end

    local hidden = foxfire.act(game, near, position)

    harness.equal(hidden.kind, intent_ids.MONSTER_WAIT,
        "summoner line of sight gates foxfire contact")
    harness.equal(ctx:get(player, component.HEALTH).current, before,
        "unseen target takes no contact damage")

    game.visible = nil

    local owner_health = ctx:get(caster, component.HEALTH)
    owner_health.current = 0
    ctx:set(caster, component.HEALTH, owner_health)

    local orphaned = foxfire.act(game, near, position)

    harness.equal(orphaned.kind, intent_ids.MONSTER_WAIT,
        "a dead summoner cannot direct foxfire contact")
    owner_health.current = 30
    ctx:set(caster, component.HEALTH, owner_health)

    -- Maximum rolls show the monster's three seven-sided dice at capped
    -- power 50. A player with five AC removes a separate five points.
    local state = ctx:get(near, component.SUMMON_CONSTRUCT)
    state.power = 50
    ctx:set(near, component.SUMMON_CONSTRUCT, state)
    local previous_defense = fighter.defense
    local draws = {}

    fighter.defense = function()
        return { ac = 5 }
    end

    function game:random(stream, bound)
        draws[#draws + 1] = { stream = stream, bound = bound }

        return bound - 1
    end

    foxfire.act(game, near, position)

    fighter.defense = previous_defense

    harness.equal(ctx:get(player, component.HEALTH).current, before - 16,
        "monster foxfire rolls 3d7 and applies player AC")
    harness.equal(#draws, 4,
        "three damage dice and one armour die use saved RNG")
    harness.equal(draws[1].bound, 7,
        "hostile foxfire uses monster damage sides")
    harness.equal(draws[4].bound, 6,
        "player armour is drawn after damage dice")
end

return test
