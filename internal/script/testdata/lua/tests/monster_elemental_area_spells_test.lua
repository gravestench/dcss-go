-- These casts borrow existing zap profiles but select victims by the source
-- monster's special targeting rules. The fixture uses production catalog
-- definitions, so a content change remains visible to these expectations.
local accuracy = require("constants.beam_accuracy")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local contact = require("policy.combat.monster_beams.contact")
local harness = require("tests.harness")
local power = require("policy.combat.monster_beams.power")
local spells = require("ids.spells")
local targets = require("policy.ai.targets")
local terrain = require("constants.terrain")
local zaps = require("constants.zap_ids")

local lightning = require(
    "policy.combat.monster_spells.call_down_lightning")
local frost = require("policy.combat.monster_spells.creeping_frost")

local test = {}
local caster = 11
local foe = 22
local other_foe = 33
local ally = 44
local neutral = 55

-- An open cell at distance three is a valid lightning target. Frost instead
-- needs a wall next to its selected foe, and may catch another visible foe.
local function context()
    local positions = {
        [caster] = {
            level_id = 1,
            x = 0,
            y = 0,
        },

        [foe] = {
            level_id = 1,
            x = 3,
            y = 0,
        },

        [other_foe] = {
            level_id = 1,
            x = 4,
            y = 0,
        },

        [ally] = {
            level_id = 1,
            x = 3,
            y = 1,
        },

        [neutral] = {
            level_id = 1,
            x = 2,
            y = 0,
        },
    }
    local ctx = {
        wall_visible = true,
    }

    -- The ordinary area owner discovers live ECS actors through this query.
    function ctx:get(entity, id)
        if id == component.POSITION then
            return positions[entity]
        end

        if id == component.HEALTH then
            return { current = 30 }
        end

        return nil
    end

    -- The source considers a wall only when both the victim and wall are
    -- visible without transparent obstruction.
    function ctx:visible_no_trans(_, _, _, _, x, y)
        if x == 3 and y == -1 then
            return self.wall_visible
        end

        return true
    end

    -- Direct strikes use their spell's reach and the visible foe cell.
    function ctx:visible()
        return true
    end

    function ctx:cell(_, x, y)
        if x == 3 and y == -1 then
            return terrain.DNGN_ROCK_WALL
        end

        return terrain.DNGN_FLOOR
    end

    function ctx:walkable(level_id, x, y)
        return self:cell(level_id, x, y) ~= terrain.DNGN_ROCK_WALL
    end

    function ctx:query()
        return { caster, foe, other_foe, ally, neutral }
    end

    return ctx, positions
end

-- Call Down Lightning starts its bolt at the foe, so intervening actors
-- cannot block it; the foe still makes an ordinary evasion roll.
local function lightning_rules(ctx, positions, hits)
    local profile = catalog.get(categories.MONSTER_BEAMS,
        spells.SPELL_CALL_DOWN_LIGHTNING)

    harness.equal(profile.zap_id, zaps.ZAP_LIGHTNING_BOLT,
        "lightning uses the source electrical zap")
    harness.equal(profile.power_hd_factor, 16,
        "the source gives this spell sixteen power per HD")
    harness.falsy(lightning.plan(ctx, caster, nil),
        "lightning needs a selected foe")

    positions[foe].x = 2
    harness.falsy(lightning.plan(ctx, caster, foe),
        "lightning is not worthwhile inside three cells")

    positions[foe].x = 3
    local plan = lightning.plan(ctx, caster, foe)

    harness.truthy(plan, "a visible distant foe offers lightning")
    lightning.resolve(ctx, caster, foe, nil, plan)
    harness.equal(#hits, 1,
        "lightning makes one contact at the foe's cell")
    harness.equal(hits[1].victim, foe,
        "an intervening actor is not struck")
    harness.truthy(hits[1].to_hit ~= accuracy.AUTOMATIC_HIT,
        "the smite-targeted bolt can still miss")
end

-- Creeping Frost independently hits every visible enemy beside a visible
-- wall, even though only one foe was saved in the cast intent.
local function frost_rules(ctx, hits)
    local profile = catalog.get(categories.MONSTER_BEAMS,
        spells.SPELL_CREEPING_FROST)

    harness.equal(profile.zap_id, zaps.ZAP_FLASH_FREEZE,
        "creeping frost uses the source ice zap")

    ctx.wall_visible = false
    harness.falsy(frost.plan(ctx, caster, foe),
        "an unseen adjacent wall cannot justify a cast")

    ctx.wall_visible = true
    local plan = frost.plan(ctx, caster, foe)

    harness.truthy(plan, "a visible adjacent wall offers frost")
    frost.resolve(ctx, caster, foe, nil, plan)
    harness.equal(#hits, 3,
        "both enemies and an unaligned neutral are hit; the ally is not")
    harness.equal(hits[1].to_hit, accuracy.AUTOMATIC_HIT,
        "frost grips without an evasion roll")
    harness.falsy(hits[1].hook.skip_damage,
        "unlike Flash Freeze, repeated frost can still deal damage")
end

-- Stub only the final contact: targeting, catalog lookup, actor discovery,
-- and the spell policy remain production code under test.
function test.run()
    local previous = {
        enemy = targets.enemy,
        aligned = targets.aligned,
        contact = contact.resolve,
        caster_power = power.caster_power,
    }
    local hits = {}
    local ctx, positions = context()

    targets.enemy = function(_, _, actor)
        return actor == foe or actor == other_foe
    end

    targets.aligned = function(_, _, actor)
        return actor == ally or actor == caster
    end

    contact.resolve = function(_, _, victim, _, _, to_hit, hook)
        hits[#hits + 1] = {
            victim = victim,
            to_hit = to_hit,
            hook = hook,
        }
    end

    power.caster_power = function()
        return 100
    end

    lightning_rules(ctx, positions, hits)
    hits = {}
    frost_rules(ctx, hits)

    targets.enemy = previous.enemy
    targets.aligned = previous.aligned
    contact.resolve = previous.contact
    power.caster_power = previous.caster_power
end

return test
