-- Portal Projectile is an actual equipped missile attack through a wall,
-- not a damage spell with an unrelated roll. Ordinary shots stay blocked.
local component = require("constants.component")
local effect = require("policy.combat.monster_spells.portal_projectile")
local equipment = require("policy.combat.equipment")
local fighter = require("policy.combat.fighter")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local ranged = require("policy.combat.ranged_actions")
local target_kind = require("constants.target_kind")

local test = {}
local caster = 11
local foe = 22
local launcher = 33

-- The spell's targeting test only needs two actors and the caster's gear.
-- The ranged owner is stubbed at its action boundary to inspect the option.
function test.run()
    local previous_worn = equipment.worn
    local previous_attack = ranged.monster
    local previous_defense = fighter.defense
    local shot
    local ctx = {}

    function ctx:player()
        return foe
    end

    function ctx:get(entity, id)
        if id == component.POSITION then
            return {
                level_id = 1,
                x = entity == caster and 1 or (self.target_x or 5),
                y = 2,
            }
        end

        if id == component.HEALTH then
            return { current = 10, max = 10 }
        end

        if id == component.ACTOR and entity == caster then
            return {
                kind_id = self.kind_id or monsters.MONS_ORC_WIZARD,
            }
        end

        return nil
    end

    function ctx:visible()
        return true
    end

    function ctx:projectile_clear()
        return false
    end

    equipment.worn = function()
        return {
            alternate_weapon = {
                entity = launcher,
                definition = {
                    weapon = { ammo_id = "MI_SLING_BULLET" },
                },
            },
        }
    end

    ranged.monster = function(_, source, intent, options)
        shot = {
            source = source,
            item_id = intent.item_id,
            portal = options.portal,
        }
    end

    local plan = effect.plan(ctx, caster, foe)

    harness.equal(plan.kind, target_kind.ENTITY,
        "a wall-hidden foe can receive a portal shot")
    effect.resolve(ctx, caster, foe, nil, plan)
    harness.equal(shot.source, caster,
        "the ranged attack belongs to the monster")
    harness.equal(shot.item_id, launcher,
        "the alternate launcher is selected")
    harness.equal(shot.portal, true,
        "the existing ranged owner receives portal mode")

    ctx.target_x = 2
    harness.falsy(effect.plan(ctx, caster, foe),
        "an ordinary caster cannot fire a portal shot in melee reach")
    ctx.kind_id = monsters.MONS_VASHNIA
    harness.truthy(effect.plan(ctx, caster, foe),
        "a source specialist archer can portal shoot in melee reach")
    ctx.target_x = 5

    ranged.monster = previous_attack
    equipment.worn = function()
        return {}
    end
    fighter.defense = function()
        return {}
    end

    -- Both calls stop at the missing equipment, unless ordinary targeting
    -- first rejects the blocked corridor. This isolates the travel rule.
    local ordinary, ordinary_error = pcall(ranged.monster,
        ctx, caster, { item_id = launcher })
    local portal, portal_error = pcall(ranged.monster,
        ctx, caster, { item_id = launcher }, { portal = true })

    harness.falsy(ordinary, "ordinary shot rejects blocked corridor")
    harness.truthy(ordinary_error:find("no clear shot", 1, true),
        "ordinary ranged attack keeps its corridor check")
    harness.falsy(portal, "missing equipment still prevents a portal shot")
    harness.truthy(portal_error:find("no equipped item", 1, true),
        "portal delivery passes the corridor check")

    ctx.target_x = 2

    local adjacent_portal, adjacent_error = pcall(ranged.monster,
        ctx, caster, { item_id = launcher }, { portal = true })

    harness.falsy(adjacent_portal,
        "the deliberately empty gear still prevents an adjacent shot")
    harness.truthy(adjacent_error:find("no equipped item", 1, true),
        "a specialist archer passes the adjacent portal check")

    fighter.defense = previous_defense
    equipment.worn = previous_worn
end

return test
