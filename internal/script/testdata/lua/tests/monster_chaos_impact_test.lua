-- A selected chaos flavour uses the ordinary beam contact owner, while a
-- return arc to the original caster remains visual even at full power.
local accuracy = require("constants.beam_accuracy")
local component = require("constants.component")
local contact = require("policy.combat.monster_beams.contact")
local flavours = require("constants.beam_flavours")
local harness = require("tests.harness")
local hexes = require("policy.combat.monster_area.chaos_hexes")
local impact = require("policy.combat.monster_area.chaos_impact")
local pool = require("policy.combat.monster_area.chaos_flavours")

local test = {}
local caster = 11
local foe = 22

-- The real trajectory sees a foe two cells down an open row.
local function context()
    local ctx = {}

    -- Positions make the real trajectory traverse one empty cell first.
    function ctx:get(entity, id)
        if id ~= component.POSITION then
            return nil
        end

        if entity == caster then
            return {
                level_id = 1,
                x = 0,
                y = 0,
            }
        end

        return {
            level_id = 1,
            x = 2,
            y = 0,
        }
    end

    -- No wall interrupts the two-cell ray.
    function ctx:walkable()
        return true
    end

    -- Only the selected foe occupies a traversed cell.
    function ctx:actor_at(_, x, y)
        return x == 2 and y == 0 and foe or nil
    end

    return ctx
end

-- Source chaos dice are calculated from current arc power. The profile is
-- copied per contact so selecting fire cannot mutate a later cold arc.
function test.run()
    local old_contact = contact.resolve
    local old_choose = pool.choose
    local old_hex = hexes.apply
    local contacts = {}
    local choices = 0
    local selected_flavour = flavours.BEAM_FIRE
    local enchanted

    pool.choose = function()
        choices = choices + 1

        return selected_flavour
    end

    contact.resolve = function(context, source, victim, profile, power,
        to_hit, hook)
        contacts[#contacts + 1] = {
            source = source,
            victim = victim,
            profile = profile,
            power = power,
            to_hit = to_hit,
            hook = hook,
        }

        if hook and hook.after_hit then
            hook.after_hit(context, source, victim, profile)
        end
    end

    hexes.apply = function(_, _, victim, flavour, power)
        enchanted = {
            victim = victim,
            flavour = flavour,
            power = power,
        }
    end

    local ctx = context()
    local source = ctx:get(caster, component.POSITION)

    impact.apply(ctx, caster, source, foe, 17, false)
    impact.apply(ctx, caster, source, caster, 8, true)

    harness.equal(#contacts, 1,
        "a return to the caster cannot apply chaos")
    harness.equal(choices, 2,
        "source chaos draws once for each traversed cell, including floor")
    harness.equal(contacts[1].victim, foe,
        "the target actor receives the beam contact")
    harness.equal(contacts[1].profile.flavour, flavours.BEAM_FIRE,
        "the drawn flavour reaches the contact owner")
    harness.equal(contacts[1].profile.monster_damage.kind, "calcdice",
        "chaos retains the source calculated dice")
    harness.equal(contacts[1].power, 17,
        "dice use power before jump attenuation")
    harness.equal(contacts[1].to_hit, accuracy.AUTOMATIC_HIT,
        "chaos contact is automatic hit")

    selected_flavour = flavours.BEAM_CONFUSION

    impact.apply(ctx, caster, source, foe, 8, false)

    harness.equal(contacts[2].hook.skip_damage(ctx, foe), true,
        "an enchantment skips the direct chaos damage dice")
    harness.equal(enchanted.victim, foe,
        "the enchantment runs only after beam contact")
    harness.equal(enchanted.flavour, flavours.BEAM_CONFUSION,
        "the selected status reaches its owner")
    harness.equal(enchanted.power, 8,
        "the effect sees this arc's attenuated power")

    contact.resolve = old_contact
    pool.choose = old_choose
    hexes.apply = old_hex
end

return test
