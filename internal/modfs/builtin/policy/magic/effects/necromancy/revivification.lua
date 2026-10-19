local catalog = require("policy.catalog")
local component = require("constants.component")
local player_constriction = require("policy.combat.player_constriction")
local spells = require("ids.spells")
local traits = require("policy.character.traits")
local forms = require("policy.magic.effects.forms.player")
local registry = require("policy.magic.effects.registry")
local statuses = require("policy.magic.effects.statuses.player")

local revivification = {}

-- Permanent undead species and active lich form both reject living-body restoration.
local function undead(ctx, player)
    local origin = ctx:get(player, component.PLAYER)
    local species = catalog.get("species", origin.species_id)
    local form = ctx:get(player, "magic.player_form")

    return species.undead_type == "US_UNDEAD" or
        (form and form.remaining_aut > 0 and form.form_id == "lich")
end

-- Source: spl-util.cc:casting_uselessness_reason. These abort before MP and
-- action time are spent.
-- Example: Revivification rejects a player at full HP before it can reduce maximum HP.
-- Guard against full health, low maximum HP, and undead form before permanent HP loss is possible.
function revivification.prepare(ctx, player)
    local health = ctx:get(player, component.HEALTH)

    if health.current >= health.max then
        return "You cannot be healed further."
    end

    if health.max < 21 then
        return "You lack the resilience to cast this spell."
    end

    if undead(ctx, player) then
        return "You are too dead."
    end

    return nil
end

-- Nine Bernoulli draws turn cast power into a bounded permanent HP cost.
local function hp_loss_percent(ctx, power)
    local successes = 0

    -- Source: random.cc:binomial(9, 8, pow). High power reduces loss.
    for _ = 1, 9 do
        if power <= 8 or ctx:random("spell", power) < 8 then
            successes = successes + 1
        end
    end

    return 6 + successes
end

-- Heal to the newly reduced maximum, then end Death's Door and apply its exit paralysis.
function revivification.resolve(ctx, player, _, _, power)
    local health = ctx:get(player, component.HEALTH)
    local percent = hp_loss_percent(ctx, power)
    local lost = math.floor(percent * health.max / 100)
    local permanent = ctx:get(player, component.PERMANENT_HP_LOSS)

    if permanent then
        permanent.amount = permanent.amount + lost
        ctx:set(player, component.PERMANENT_HP_LOSS, permanent)
    else
        ctx:add(player, component.PERMANENT_HP_LOSS, {
            amount = lost,
        })
    end

    forms.rescale_health(ctx, player, forms.max_hp(ctx, player))
    health = ctx:get(player, component.HEALTH)
    health.current = health.max
    ctx:set(player, component.HEALTH, health)
    ctx:emit("spell", "Your body is healed in an amazingly painful way.")

    if statuses.clear_death_door(ctx, player) then
        ctx:emit("duration", "Your life is in your own hands once again.")

        local origin = ctx:get(player, component.PLAYER)
        local species = catalog.get("species", origin.species_id)

        if not traits.stasis(species) then
            player_constriction.release_all(ctx, player)

            local turns = 2 + ctx:random("spell", 4)
            local paralysis = ctx:get(player, component.PLAYER_PARALYSIS)
            local remaining = turns * 10

            if paralysis then
                paralysis.remaining_aut = remaining
                ctx:set(player, component.PLAYER_PARALYSIS, paralysis)
            else
                ctx:add(player, component.PLAYER_PARALYSIS, {
                    remaining_aut = remaining,
                })
            end

            ctx:emit("status", "You suddenly lose the ability to move!")
        end
    end
end

registry.add(spells.SPELL_BORGNJORS_REVIVIFICATION, revivification)

return revivification
