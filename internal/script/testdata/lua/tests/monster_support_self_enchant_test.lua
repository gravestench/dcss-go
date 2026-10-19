local boons = require("policy.combat.monster_support.boons")
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local target_kind = require("constants.target_kind")

local test = {}

-- Each source self-enchantment targets the caster. Its real consumer must
-- observe the saved timer, and a second cast must not spend a book slot.
function test.run(ctx)
    local caster = ctx:create()
    local player = ctx:create()
    local game = setmetatable({}, { __index = ctx })

    -- The isolated rule harness has no host-selected player. Bind one
    -- handle while retaining the production ECS reads and writes.
    function game.player()
        return player
    end

    ctx:add(caster, component.ACTOR, {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })

    local haste = effects.effect(spells.SPELL_HASTE)
    local haste_plan = haste.plan(game, caster)

    harness.equal(haste_plan.kind, target_kind.ENTITY,
        "Haste uses the entity intent target")
    harness.equal(haste_plan.entity, caster,
        "Haste chooses the caster")

    haste.resolve(game, caster, nil, nil, haste_plan)

    harness.truthy(boons.hasted(ctx, caster),
        "Haste creates active actor-owned state")
    harness.equal(boons.speed(ctx, caster, 10), 15,
        "Haste changes action energy")
    harness.falsy(haste.plan(game, caster),
        "Haste does not recast while active")

    local might = effects.effect(spells.SPELL_MIGHT)
    local might_plan = might.plan(game, caster)

    might.resolve(game, caster, nil, nil, might_plan)

    harness.equal(boons.damage(ctx, caster, 10), 15,
        "Might changes melee damage")
    harness.falsy(might.plan(game, caster),
        "Might does not recast while active")

    local invisible = effects.effect(spells.SPELL_INVISIBILITY)
    local invis_plan = invisible.plan(game, caster)

    invisible.resolve(game, caster, nil, nil, invis_plan)

    local enchant = ctx:get(caster, component.MONSTER_ENCHANT)

    harness.truthy(enchant.invisible_aut > 0,
        "Invisibility uses the existing saved enchant owner")
    harness.falsy(invisible.plan(game, caster),
        "Invisibility does not recast while active")

    local sprint = effects.effect(spells.SPELL_SPRINT)
    local sprint_plan = sprint.plan(game, caster)

    sprint.resolve(game, caster, nil, nil, sprint_plan)

    harness.truthy(boons.swift_active(ctx, caster),
        "Sprint creates movement-only Swift state")
    harness.falsy(sprint.plan(ctx, caster),
        "Sprint does not recast while active")
end

return test
