
local capabilities = require("constants.mutation_capabilities")
local abilities = require("ids.abilities")
local classes = require("constants.mutation_classes")
local component = require("constants.component")
local effects = require("policy.mutations.effects.registry")
local harness = require("tests.harness")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local registry = require("policy.abilities.registry")
local forms = require("policy.magic.effects.forms.player")
local levels = require("policy.mutations.levels")
local vampire = require("policy.character.vampire")

local test = {}

-- Search the actual ability registry so blood-state tests cover menu gating.
local function available(ctx, player, id)
    for _, option in ipairs(registry.available(ctx, player)) do
        if option.id == id then
            return true
        end
    end

    return false
end

-- Partial-turn ritual saves are rejected.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.ATTRIBUTES, {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })

    records.grant_acquired(ctx, player, mutations.MUT_VAMPIRISM, 1)
    vampire.start(ctx, player)

    harness.truthy(vampire.alive(ctx, player),
        "new vampires begin alive")
    harness.equal(effects.sum(ctx, player,
        capabilities.HP_REGEN_BONUS), 20,
        "living vampire regeneration bonus")
    harness.equal(effects.sum(ctx, player,
        capabilities.HP_PERCENT), 0,
        "living vampire HP is unchanged")
    harness.truthy(available(ctx, player, abilities.EXSANGUINATE),
        "living vampire can exsanguinate")
    harness.falsy(available(ctx, player, abilities.REVIVIFY),
        "living vampire cannot revivify")
    harness.falsy(available(ctx, player, abilities.BAT_FORM),
        "level-one living vampire cannot use Bat Form")

    vampire.begin(ctx, player, abilities.EXSANGUINATE)
    vampire.advance(ctx, player, 5)

    local ritual = ctx:get(player, component.VAMPIRE)

    -- The blood ritual progresses in action units even when the action uses fewer aut.
    harness.equal(ritual.ritual_remaining_aut, 40,
        "a fast action advances the ritual by one source turn")

    ritual.ritual_remaining_aut = 55
    ctx:set(player, component.VAMPIRE, ritual)

    local valid = pcall(vampire.validate, ctx, player)

    -- Restore validation rejects an impossible ritual remainder.
    harness.falsy(valid, "partial-turn ritual saves are rejected")
    ritual.ritual_remaining_aut = 40
    ctx:set(player, component.VAMPIRE, ritual)
    vampire.interrupt(ctx, player)

    local state = ctx:get(player, component.VAMPIRE)

    state.alive = false
    ctx:set(player, component.VAMPIRE, state)

    -- Ability availability and regeneration read the persisted vampire state after completion.
    harness.truthy(vampire.bloodless(ctx, player),
        "bloodless state is authoritative")
    harness.equal(effects.sum(ctx, player,
        capabilities.HP_PERCENT), -20,
        "bloodless vampire loses twenty percent max HP")
    harness.equal(effects.sum(ctx, player,
        capabilities.COLD_RESISTANCE), 2,
        "bloodless vampire has two cold resistance pips")
    harness.equal(effects.sum(ctx, player,
        capabilities.NEGATIVE_ENERGY_RESISTANCE), 3,
        "bloodless vampire has three negative energy pips")
    harness.equal(effects.sum(ctx, player,
        capabilities.STEALTH_BONUS), 100,
        "bloodless vampire has two stealth pips")
    harness.equal(effects.sum(ctx, player,
        capabilities.HP_REGEN_INHIBITED), 1,
        "nearby threats stop bloodless vampire regeneration")
    harness.equal(effects.sum(ctx, player,
        capabilities.POISON_RESISTANCE), 3,
        "bloodless vampire is immune to poison")
    harness.equal(effects.sum(ctx, player,
        capabilities.TORMENT_RESISTANCE), 2,
        "bloodless vampire is immune to torment")
    harness.falsy(available(ctx, player, abilities.EXSANGUINATE),
        "bloodless vampire cannot exsanguinate")
    harness.truthy(available(ctx, player, abilities.REVIVIFY),
        "bloodless vampire can revivify")
    records.grant_acquired(ctx, player, mutations.MUT_VAMPIRISM, 1)
    harness.truthy(available(ctx, player, abilities.BAT_FORM),
        "level-two bloodless vampire can use Bat Form")

    local attributes = ctx:get(player, component.ATTRIBUTES)

    attributes.strength = 2
    ctx:set(player, component.ATTRIBUTES, attributes)

    for _, option in ipairs(registry.available(ctx, player)) do
        if option.id == abilities.BAT_FORM then
            harness.truthy(option.confirmation_needed,
                "Bat Form warns before its stat drain reaches zero")
        end
    end

    records.delete(ctx, player, mutations.MUT_VAMPIRISM,
        classes.ACQUIRED, 2)
    vampire.changed(ctx, player)
    harness.falsy(ctx:has(player, component.VAMPIRE),
        "removing Vampirism removes blood state")

    local acquired = ctx:create()

    records.grant_acquired(ctx, acquired, mutations.MUT_VAMPIRISM, 1)
    vampire.changed(ctx, acquired)
    harness.truthy(ctx:has(acquired, component.VAMPIRE),
        "acquiring Vampirism creates blood state")

    local innate = ctx:create()

    records.grant_innate(ctx, innate, mutations.MUT_VAMPIRISM, 2)
    records.grant_innate(ctx, innate, mutations.MUT_FANGS, 3)
    vampire.start(ctx, innate)

    local blood = ctx:get(innate, component.VAMPIRE)

    blood.alive = false
    ctx:set(innate, component.VAMPIRE, blood)
    ctx:add(innate, component.PLAYER_FORM, {
        form_id = "bat",
        remaining_aut = 10,
        power = 100,
    })

    harness.equal(levels.effective(ctx, innate,
        mutations.MUT_FANGS), 3,
        "innate Vampire fangs remain active in Bat Form")
    forms.tick(ctx, innate, 100)

    local form = ctx:get(innate, component.PLAYER_FORM)

    harness.equal(form.remaining_aut, 10,
        "Vampire Bat Form does not expire with time")

    ctx:add(innate, component.ATTRIBUTES, {
        strength = 0,
        intelligence = 10,
        dexterity = 10,
    })

    local end_available = false

    for _, option in ipairs(registry.available(ctx, innate)) do
        if option.id == abilities.END_TRANSFORMATION then
            end_available = true
            harness.truthy(option.confirmation_needed,
                "ending Bat Form warns when a stat remains at zero")
        end
    end

    harness.truthy(end_available,
        "Bat Form exposes the generic end transformation ability")
end

return test
