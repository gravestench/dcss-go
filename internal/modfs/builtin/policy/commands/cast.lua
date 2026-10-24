local catalog = require("policy.catalog")
local effects = require("policy.magic.effects.registry")
local range = require("policy.magic.range")
local records = require("policy.character.spell_records")
local resources = require("policy.magic.resources")
local silence = require("policy.world.silence")
local confusion = require("policy.magic.player_confusion")
local availability = require("policy.character.skill_availability")
local hex_status = require("policy.combat.monster_hexes.status")
local engulf = require("policy.combat.engulf")
local command_kind = require("constants.command_kind")

local cast = {}

-- Check spell metadata locally before deciding whether this cast needs a target.
local function has_flag(spell, wanted)
    for _, flag in ipairs(spell.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Only target/direction flags demand input coordinates; non-target spells reach effect preflight with zero offsets.
local function needs_aim(spell)
    return has_flag(spell, "target") or
        has_flag(spell, "dir") or
        has_flag(spell, "dir_or_target")
end

-- Ability casting asks the same target question as ordinary casting. This
-- shared predicate keeps spell flags from being interpreted twice.
function cast.requires_aim(spell)
    return needs_aim(spell)
end

-- Source: spl-cast.cc:cast_a_spell and spl-util.cc:
-- casting_uselessness_reason. A rejected choice leaves time and RNG alone.
-- Example: cast.prepare(ctx, player, { spell_id = spells.SPELL_MAGIC_DART, dx = 1 }) checks a cast.
function cast.prepare(ctx, player, input, allow_library)
    local spell_id = input.spell_id
    local known = records.find(ctx, player, spell_id)

    if not known or
        (known.state.known_slot == 0 and
            (not allow_library or not known.state.in_library)) then
        return { message = "You don't know that spell." }
    end

    if confusion.active(ctx, player) then
        return { message = "You're too confused to cast spells." }
    end

    if hex_status.cannot_cast(ctx, player) then
        return { message = "Your magic has been temporarily blocked." }
    end

    local spell = catalog.get("spells", spell_id)
    local progress = ctx:get(player, "core.progression")

    if availability.forbidden_spell(ctx, player, spell) then
        return { message = "You cannot use spells of this school." }
    end

    if silence.actor(ctx, player) then
        return { message = "You cannot cast spells when silenced!" }
    end

    if engulf.silenced(ctx, player) then
        return { message = "You cannot cast spells while unable to breathe!" }
    end

    -- Exegesis can borrow a library spell above the player's experience
    -- level; it still needs the ordinary spell resource and usable school.
    if not allow_library and progress.level < spell.level then
        return { message = "You aren't experienced enough to cast this spell." }
    end

    local cost = resources.spell_cost(ctx, player, spell.level)
    local no_resource = resources.cannot_pay(ctx, player, cost)

    if no_resource then
        return { message = no_resource }
    end

    local dx = input.dx or 0
    local dy = input.dy or 0

    if needs_aim(spell) then
        if dx == 0 and dy == 0 then
            return { message = "Okay, then." }
        end

        if math.max(math.abs(dx), math.abs(dy)) >
            range.for_spell(ctx, player, spell) then
            return { message = "That is beyond your range." }
        end
    end

    local effect = effects.get(spell_id)

    if not effect then
        return { message = "That spell is not available yet." }
    end

    if effect.prepare then
        local rejection = effect.prepare(ctx, player, spell, dx, dy,
            input)

        if rejection then
            if type(rejection) == "table" and
                type(rejection.confirmation) == "string" then
                return rejection
            end

            return { message = rejection }
        end
    end

    if input.kind ~= command_kind.FORCE_CAST and
        effect.can_target and
        not effect.can_target(ctx, player, spell) then
        return {
            message = "You can't see any susceptible monsters within range! " ..
                "(Use Z to cast anyway.)",
        }
    end

    return {
        intent = {
            kind = 15,
            spell_id = spell_id,
            dx = dx,
            dy = dy,
            forced = input.kind == command_kind.FORCE_CAST,
        },
        cost = 10,
    }
end

return cast
