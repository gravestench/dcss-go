-- The Box calls a temporary mutant beast whose tier and two facets are
-- saved on the summoned actor. Failed placement costs a turn but keeps
-- the box's XP charge, as in the source evocation path.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local conduct = require("policy.religion.conduct")
local conduct_ids = require("constants.religion_conduct")
local effects = require("policy.inventory.evokers.effects")
local form = require("policy.monsters.mutant_beast.form")
local hit_points = require("policy.population.hit_points")
local items = require("ids.items")
local monsters = require("ids.monsters")
local profile = require("policy.monsters.mutant_beast.profile")
local power = require("policy.magic.power")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")

local box = {}
box.summon_kind_id = monsters.MONS_MUTANT_BEAST

local tier_hit_dice = { 3, 9, 15, 21, 27 }

-- Two seven-way draws give the source triangular skill variation. The
-- first tier whose HD threshold contains the result becomes the beast.
function box.hit_dice(ctx, skill)
    local adjusted = math.min(27, skill +
        ctx:random(streams.EVOKER, 7) -
        ctx:random(streams.EVOKER, 7))

    for _, hd in ipairs(tier_hit_dice) do
        if adjusted <= hd then
            return hd
        end
    end

    return 27
end

-- Create the source beast body before announcing it. The shared summon
-- owner places and times the actor; its saved form controls later combat.
function box.resolve(ctx, player)
    local skill = power.training(ctx, player, skills.SK_EVOCATIONS, 1)
    local hd = box.hit_dice(ctx, skill)
    local definition = catalog.get(categories.MONSTERS,
        monsters.MONS_MUTANT_BEAST)
    local body = form.roll(ctx, hd)
    local average = hit_points.scaled_average(ctx,
        definition.average_hp_10x, definition.hd, hd)
    local hp = hit_points.roll(ctx, average)
    local duration = 3 + ctx:random(streams.EVOKER, 3)

    ctx:emit("evoke", "You open the lid...")

    local beast = summons.spawn(ctx, player, items.MISC_BOX_OF_BEASTS,
        monsters.MONS_MUTANT_BEAST, duration, nil, {
            source_category = categories.ITEMS,
            stream = streams.EVOKER,
            silent_failure = true,
            hp = hp,
            hd = hd,
        })

    if not beast then
        ctx:emit("evoke", "...but nothing happens.")

        return {
            charge = false,
            practice = 0,
        }
    end

    ctx:add(beast, component.MONSTER_MUTANT_BEAST, {
        tier = body.tier,
        hit_dice = body.hit_dice,
        facets = body.facets,
    })

    local actor = ctx:get(beast, component.ACTOR)

    actor.speed = profile.speed(actor.speed, body)
    ctx:set(beast, component.ACTOR, actor)
    conduct.record(ctx, {
        id = conduct_ids.CHAOS,
        level = 5 + ctx:random(streams.EVOKER, 6),
        known = true,
    })
    ctx:emit("evoke", "...and a mutant beast leaps out!")

    return {
        charge = true,
        practice = 1,
    }
end

effects.add(items.MISC_BOX_OF_BEASTS, box)

return box
