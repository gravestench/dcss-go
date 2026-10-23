-- Theory of operation: Beogh offers visible orcs one sight conversion after
-- reaching three stars. A lethal blow from the player or a follower can also
-- rescue an orc at the deathbed. Successful converts carry a saved god-gift
-- tag, which allegiance, XP, desertion, and wrath can all read directly.
local attitudes = require("constants.attitude")
local behaviors = require("constants.ai_behaviors")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local gods = require("constants.gods")
local monsters = require("ids.monsters")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local invisibility = require("policy.potions.invisibility")
local monster_stats = require("policy.combat.monster_stats")
local display = require("policy.combat.monster_support.display")
local piety = require("policy.religion.piety")
local senses = require("policy.character.senses")
local targets = require("policy.ai.targets")

local beogh = {}

-- Source random2(0) yields zero and does not ask the runtime for an invalid
-- bound. All four conversion contests share the religion stream.
local function roll(ctx, bound, stream)
    if bound <= 1 then
        return 0
    end

    return ctx:random(stream or streams.RELIGION, bound)
end

-- The monster genus, rather than its name, includes the full orc family
-- while excluding shapeshifters merely wearing an orc body.
local function orc_definition(ctx, entity)
    local actor = ctx:get(entity, component.ACTOR)

    if not actor then
        return nil
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    if definition.genus_id ~= monsters.MONS_ORC or
        ctx:has(entity, component.SUMMON) or
        ctx:has(entity, component.MONSTER_SHAPESHIFTER) then
        return nil
    end

    return definition
end

-- The passive appears at three stars, but penance suspends its conversion
-- roll after the source has recorded this monster's one sight attempt.
local function worship_state(ctx, player)
    local identity = ctx:get(player, component.PLAYER)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if not identity or identity.species_id ~= species.SP_HILL_ORC or
        not state or state.god_id ~= gods.BEOGH or
        piety.rank(gods.BEOGH, state.piety) < 3 then
        return nil
    end

    return state
end

-- A follower's god-gift identity survives even when wrath or desertion
-- changes its side. A band relation is left untouched.
local function make_follower(ctx, entity, previous)
    local state = previous or {
        attitude = attitudes.HOSTILE,
        attempted = false,
        gift = false,
    }

    state.attitude = attitudes.FRIENDLY
    state.attempted = true
    state.gift = true

    if ctx:has(entity, component.BEOGH_ORC) then
        ctx:set(entity, component.BEOGH_ORC, state)
    else
        ctx:add(entity, component.BEOGH_ORC, state)
    end

    local health = ctx:get(entity, component.HEALTH)
    local rescued = health and health.current <= 0

    if rescued then
        local minimum = math.max(1, math.floor(health.max / 5))
        local maximum = math.max(minimum,
            math.floor(health.max * 2 / 5))

        health.current = minimum + roll(ctx, maximum - minimum + 1)
        ctx:set(entity, component.HEALTH, health)
    end

    -- An orc that pledges allegiance should follow the player instead of
    -- returning to its old patrol point after combat ends.
    if ctx:has(entity, component.MONSTER_PATROL) then
        ctx:remove(entity, component.MONSTER_PATROL)
    end

    -- The source selects among several monspeak lines. Use its first
    -- reaction for each route until the speech catalog is imported.
    local name = display.name(ctx, entity)

    if rescued then
        ctx:emit(channels.RELIGION,
            "The " .. name .. " surrenders.")
    else
        ctx:emit(channels.RELIGION,
            "The " .. name .. " stares at you in amazement and kneels.")
    end

    return true
end

-- The monster must see the potential messiah. Source conversion is offered
-- on sight or contact, not just because two actors share a level.
local function sees_player(ctx, player, monster)
    local origin = ctx:get(player, component.POSITION)
    local position = ctx:get(monster, component.POSITION)

    if not origin or not position or
        origin.level_id ~= position.level_id then
        return false
    end

    local distance = math.max(math.abs(origin.x - position.x),
        math.abs(origin.y - position.y))

    return distance <= 7 and
        invisibility.visible_to(ctx, player, monster) and
        ctx:visible(origin.level_id, position.x, position.y, 7,
            origin.x, origin.y)
end

-- A first encounter follows source piety, XL, monster HD, and a five-sided
-- resistance roll in that order. Sight needs mutual visibility; a player
-- strike also gives an unseen orc its one conversion opportunity.
local function attempt(ctx, player, entity, contact)
    local worship = worship_state(ctx, player)
    local definition = orc_definition(ctx, entity)

    if not worship or not definition or
        targets.attitude(ctx, entity) == attitudes.FRIENDLY or
        not contact and not sees_player(ctx, player, entity) then
        return false
    end

    local state = ctx:get(entity, component.BEOGH_ORC) or {
        attitude = attitudes.HOSTILE,
        attempted = false,
        gift = false,
    }

    if state.attempted then
        return false
    end

    state.attempted = true
    if ctx:has(entity, component.BEOGH_ORC) then
        ctx:set(entity, component.BEOGH_ORC, state)
    else
        ctx:add(entity, component.BEOGH_ORC, state)
    end

    if (worship.penance[gods.BEOGH] or 0) > 0 then
        return false
    end

    local progress = ctx:get(player, component.PROGRESSION)
    -- Source experience level is the stored HD before temporary draining.
    local hd = monster_stats.base_hit_dice(ctx, entity, definition)
    local favor = roll(ctx, math.floor(worship.piety / 15)) +
        roll(ctx, 4 + math.floor(progress.level / 3))
    local resistance = roll(ctx, hd) + hd + roll(ctx, 5)

    if favor <= resistance then
        return false
    end

    return make_follower(ctx, entity, state)
end

-- A visible monster normally decides whether to join before choosing an
-- action; its saved attempt flag makes subsequent turns deterministic.
function beogh.convert_on_turn(ctx, player, entity)
    return attempt(ctx, player, entity, false)
end

-- Beogh also offers the conversion contest when a player's hit first
-- alerts an orc, including projectile and spell damage from out of sight.
function beogh.convert_on_contact(ctx, player, entity)
    return attempt(ctx, player, entity, true)
end

-- A visible orc struck dead by its messiah or a friendly follower receives
-- three source saving throws. The later generic death system sees revived HP.
function beogh.deathbed(ctx, entity, source)
    local definition = orc_definition(ctx, entity)
    local health = ctx:get(entity, component.HEALTH)

    if not definition or not health or health.current > 0 then
        return false
    end

    local player = ctx:player()

    if not player then
        return false
    end

    local worship = worship_state(ctx, player)
    local existing = ctx:get(entity, component.BEOGH_ORC)

    if not worship or (worship.penance[gods.BEOGH] or 0) > 0 or
        (existing and existing.gift) or
        not senses.player_sees_cell(ctx,
            ctx:get(entity, component.POSITION)) then
        return false
    end

    if source ~= player then
        if not source or
            targets.real_attitude(ctx, source) ~= attitudes.FRIENDLY or
            roll(ctx, 3) == 0 then
            return false
        end
    end

    local progress = ctx:get(player, component.PROGRESSION)
    local hd = monster_stats.hit_dice(ctx, entity, definition)
    local experience = monster_stats.base_hit_dice(ctx, entity,
        definition)

    if roll(ctx, worship.piety) < piety.breakpoint(1) or
        roll(ctx, progress.level) < roll(ctx, hd) or
        roll(ctx, experience) <= 2 then
        return false
    end

    return make_follower(ctx, entity, existing)
end

-- Renunciation flips every surviving companion, including off-level ones.
-- The gift bit remains so killing an old follower cannot award XP.
function beogh.leave(ctx)
    for _, entity in ipairs(ctx:query({ component.BEOGH_ORC })) do
        local state = ctx:get(entity, component.BEOGH_ORC)

        if state.gift and state.attitude == attitudes.FRIENDLY then
            state.attitude = attitudes.HOSTILE
            ctx:set(entity, component.BEOGH_ORC, state)
        end
    end
end

-- Restore checks the saved gift's orc identity and the one-shot conversion
-- state before combat can trust its stored allegiance.
function beogh.validate(ctx, entity)
    local state = ctx:get(entity, component.BEOGH_ORC)

    if not state then
        return
    end

    local valid_attitude = state.attitude == attitudes.HOSTILE or
        state.attitude == attitudes.FRIENDLY
    local valid_transition = (not state.gift and
        state.attitude == attitudes.HOSTILE) or
        (state.gift and state.attempted)

    if not orc_definition(ctx, entity) or not valid_attitude or
        not valid_transition or
        not ctx:has(entity, component.AI) or
        not ctx:has(entity, component.HEALTH) or
        not ctx:has(entity, component.POSITION) then
        error("invalid saved Beogh orc allegiance " .. ctx:id(entity))
    end
end

-- Penance tests every nearby gift, including one the player cannot see.
-- A failed saving throw changes its real side and alerts its AI.
function beogh.abandon(ctx, player, stream)
    local origin = ctx:get(player, component.POSITION)
    local total = 0
    local visible = 0
    local changed = false

    for _, entity in ipairs(ctx:query({
        component.BEOGH_ORC,
        component.POSITION,
        component.HEALTH,
    })) do
        local state = ctx:get(entity, component.BEOGH_ORC)
        local position = ctx:get(entity, component.POSITION)
        local health = ctx:get(entity, component.HEALTH)
        local distance = math.max(math.abs(position.x - origin.x),
            math.abs(position.y - origin.y))

        if state.gift and health.current > 0 and
            position.level_id == origin.level_id and distance <= 7 and
            ctx:visible(origin.level_id, origin.x, origin.y, 7,
                position.x, position.y) then
            total = total + 1

            local ai = ctx:get(entity, component.AI)
            local asleep = ai and ai.behavior == behaviors.SLEEP
            local stasis = ctx:get(entity, component.MONSTER_STASIS)
            local confused = ctx:get(entity, component.MONSTER_CONFUSION)
            local paralysed = ctx:get(entity, component.PARALYSIS)

            if sees_player(ctx, player, entity) and not asleep and
                not (stasis and (stasis.hibernating or
                    stasis.petrified_aut > 0)) and
                not (confused and confused.remaining_aut > 0) and
                not (paralysed and paralysed.remaining_aut > 0) then
                local actor = ctx:get(entity, component.ACTOR)
                local definition = catalog.get(categories.MONSTERS,
                    actor.kind_id)
                local hd = monster_stats.base_hit_dice(ctx, entity,
                    definition)

                if roll(ctx, 20, stream) <= roll(ctx, hd, stream) then
                    state.attitude = attitudes.HOSTILE
                    ctx:set(entity, component.BEOGH_ORC, state)
                    changed = true

                    if ai then
                        ai.behavior = behaviors.SEEK
                        ai.target_x = origin.x
                        ai.target_y = origin.y
                        ctx:set(entity, component.AI, ai)
                    end

                    if senses.player_sees_actor(ctx, entity) then
                        visible = visible + 1
                    end
                end
            end
        end
    end

    if not changed then
        return false
    end

    ctx:emit(channels.RELIGION,
        "Beogh's voice booms out, \"Who do you think you are?\"")

    if visible > 0 then
        local message = "Some of your followers decide to abandon you."

        if visible == 1 and total > 1 then
            message = "One of your followers decides to abandon you."
        elseif visible == total then
            message = "Your followers decide to abandon you."
        end

        ctx:emit(channels.MONSTER, message)
    end

    return true
end

return beogh
