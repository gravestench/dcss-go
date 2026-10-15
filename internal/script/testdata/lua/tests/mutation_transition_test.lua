local classes = require("constants.mutation_classes")
local choices = require("constants.mutation_choices")
local mutations = require("ids.mutations")
local species = require("ids.species")
local records = require("policy.mutations.records")
local levels = require("policy.mutations.levels")
local transition = require("policy.mutations.transition")
local harness = require("tests.harness")

local test = {}

local function player(ctx, species_id)
    local owner = ctx:create()

    ctx:add(owner, "core.player", {
        species_id = species_id or species.SP_HUMAN,
        job_id = "JOB_FIGHTER",
        name = "Mutation test",
    })

    return owner
end

function test.run(ctx)
    local trade = player(ctx)
    records.grant_acquired(ctx, trade, mutations.MUT_FRAIL, 1)

    local traded = transition.grant(ctx, trade, mutations.MUT_ROBUST,
        classes.ACQUIRED, false)

    harness.equal(traded.kind, "traded", "opposed mutations trade one level")
    harness.equal(levels.base(ctx, trade, mutations.MUT_FRAIL), 0,
        "trade removes the old level")
    harness.equal(levels.base(ctx, trade, mutations.MUT_ROBUST), 0,
        "trade does not grant the new mutation")

    local forced = player(ctx)
    records.grant_acquired(ctx, forced, mutations.MUT_FRAIL, 2)

    local forced_result = transition.grant(ctx, forced, mutations.MUT_ROBUST,
        classes.ACQUIRED, true)

    harness.equal(forced_result.kind, "traded",
        "forced ordinary trade still consumes one level")
    harness.equal(levels.base(ctx, forced, mutations.MUT_FRAIL), 1,
        "forced trade removes one old level")

    local innate = player(ctx)
    records.grant_innate(ctx, innate, mutations.MUT_FRAIL, 1)

    local blocked = transition.grant(ctx, innate, mutations.MUT_ROBUST,
        classes.ACQUIRED, true)

    harness.equal(blocked.kind, "blocked", "innate conflict cannot be removed")
    harness.equal(levels.base(ctx, innate, mutations.MUT_FRAIL), 1,
        "blocked conflict preserves innate level")

    local temporary = player(ctx)
    records.grant_temporary(ctx, temporary, mutations.MUT_FRAIL, 1, 40)

    local allowed = transition.grant(ctx, temporary, mutations.MUT_ROBUST,
        classes.ACQUIRED, false)

    harness.equal(allowed.kind, "granted", "ordinary and temporary conflicts coexist")
    harness.equal(levels.base(ctx, temporary, mutations.MUT_FRAIL), 1,
        "temporary conflicting level survives")
    harness.equal(levels.base(ctx, temporary, mutations.MUT_ROBUST), 1,
        "ordinary conflicting level is granted")

    local regeneration = player(ctx)
    records.grant_acquired(ctx, regeneration,
        mutations.MUT_INHIBITED_REGENERATION, 1)

    local ordered = transition.grant(ctx, regeneration,
        mutations.MUT_REGENERATION, classes.ACQUIRED, false)

    harness.equal(ordered.kind, "traded",
        "later regeneration conflict trades after the earlier ignore row")

    local forced_regeneration = player(ctx)
    records.grant_acquired(ctx, forced_regeneration,
        mutations.MUT_INHIBITED_REGENERATION, 1)

    local cleared = transition.grant(ctx, forced_regeneration,
        mutations.MUT_REGENERATION, classes.ACQUIRED, true)

    harness.equal(cleared.kind, "granted",
        "forced earlier conflict clears all levels before trade row")
    harness.equal(levels.base(ctx, forced_regeneration,
        mutations.MUT_INHIBITED_REGENERATION), 0,
        "forced conflict clears opposed levels")
    harness.equal(levels.base(ctx, forced_regeneration,
        mutations.MUT_REGENERATION), 1,
        "forced conflict grants requested mutation")

    local innate_regeneration = player(ctx)
    records.grant_acquired(ctx, innate_regeneration,
        mutations.MUT_INHIBITED_REGENERATION, 1)

    local innate_growth = transition.grant(ctx, innate_regeneration,
        mutations.MUT_REGENERATION, classes.INNATE, false)

    harness.equal(innate_growth.kind, "granted",
        "innate acquisition is forced by its source permanence class")
    harness.equal(levels.base(ctx, innate_regeneration,
        mutations.MUT_INHIBITED_REGENERATION), 0,
        "innate acquisition clears a non-innate conflict")

    local both_temporary = player(ctx)
    records.grant_temporary(ctx, both_temporary,
        mutations.MUT_FRAIL, 1, 30)

    local temporary_trade = transition.grant(ctx, both_temporary,
        mutations.MUT_ROBUST, classes.TEMPORARY, false, 30)

    harness.equal(temporary_trade.kind, "traded",
        "two temporary conflicting mutations trade")

    local human = player(ctx)
    local wings = transition.grant(ctx, human, mutations.MUT_BIG_WINGS,
        classes.ACQUIRED, false)
    local spike = transition.grant(ctx, human, mutations.MUT_TENTACLE_SPIKE,
        classes.ACQUIRED, false)

    harness.equal(wings.kind, "blocked", "ordinary Human cannot grow wings")
    harness.equal(spike.kind, "blocked", "Human has no tentacles for a spike")

    local octopode = player(ctx, species.SP_OCTOPODE)
    local horns = transition.grant(ctx, octopode, mutations.MUT_HORNS,
        classes.ACQUIRED, false)

    harness.equal(horns.kind, "blocked", "boneless Octopode cannot grow horns")

    local felid = player(ctx, species.SP_FELID)
    records.grant_innate(ctx, felid, mutations.MUT_PAWS, 1)

    local claws = transition.grant(ctx, felid, mutations.MUT_CLAWS,
        classes.ACQUIRED, false)

    harness.equal(claws.kind, "blocked", "Felid paws prevent further claws")

    local gargoyle = player(ctx, species.SP_GARGOYLE)
    local allowed_wings = transition.grant(ctx, gargoyle,
        mutations.MUT_BIG_WINGS, classes.ACQUIRED, false)

    harness.equal(allowed_wings.kind, "granted",
        "Gargoyle can grow wings")

    local permanence = player(ctx)
    records.grant_temporary(ctx, permanence, mutations.MUT_ROBUST, 1, 40)
    records.grant_acquired(ctx, permanence, mutations.MUT_ROBUST, 2)

    local became_innate = transition.grant(ctx, permanence,
        mutations.MUT_ROBUST, classes.INNATE, false)
    local permanent_record = records.find(ctx, permanence,
        mutations.MUT_ROBUST).state

    harness.equal(became_innate.kind, "permanent",
        "innate grant converts a non-innate level at the cap")
    harness.equal(permanent_record.innate, 1, "converted level is innate")
    harness.equal(permanent_record.acquired, 2,
        "temporary level is converted first")
    harness.equal(permanent_record.temporary, 0,
        "temporary level was removed")
    harness.equal(records.timer(ctx, permanence).remaining_xp, 0,
        "temporary expiry resets after conversion")

    local growing = player(ctx)
    records.grant_acquired(ctx, growing, mutations.MUT_ROBUST, 3)

    transition.grant_scheduled(ctx, growing, {
        mutations = {
            {
                id = mutations.MUT_ROBUST,
                level = 2,
                amount = 1,
            },
        },
    }, 2)

    local grown = records.find(ctx, growing, mutations.MUT_ROBUST).state

    harness.equal(grown.innate, 1,
        "level-up growth promotes an existing acquired mutation")
    harness.equal(grown.acquired, 2,
        "level-up growth keeps the mutation cap")

    local vital = player(ctx)

    ctx:add(vital, "core.progression", { level = 1 })
    ctx:add(vital, "core.skills", { entries = {} })
    ctx:add(vital, "core.health", {
        current = 13,
        max = 13,
    })
    ctx:add(vital, "core.regeneration", { hp_progress = 0 })

    transition.grant(ctx, vital, mutations.MUT_ROBUST,
        classes.ACQUIRED, false)

    local health = ctx:get(vital, "core.health")

    harness.equal(health.max, 14,
        "mutation transition immediately updates maximum HP")

    local resistant = player(ctx)

    records.grant_acquired(ctx, resistant,
        mutations.MUT_MUTATION_RESISTANCE, 3)

    local refused = transition.grant(ctx, resistant,
        mutations.MUT_STRONG, classes.ACQUIRED, false)

    harness.equal(refused.kind, "resisted",
        "maximum intrinsic mutation resistance refuses acquisition")
    harness.equal(levels.base(ctx, resistant, mutations.MUT_STRONG), 0,
        "resisted acquisition does not change levels")

    local forced_gain = transition.grant(ctx, resistant,
        mutations.MUT_STRONG, classes.ACQUIRED, true)

    harness.equal(forced_gain.kind, "granted",
        "forced mutation bypasses intrinsic resistance")

    local removable = player(ctx)

    records.grant_acquired(ctx, removable, mutations.MUT_STRONG, 1)
    records.grant_acquired(ctx, removable, mutations.MUT_ROBUST, 1)

    local deleted = transition.remove_random(ctx, removable,
        choices.ANY, false)

    harness.equal(deleted.kind, "removed",
        "random deletion removes an acquired mutation")
    harness.equal(deleted.mutation_id, mutations.MUT_ROBUST,
        "zero draws select the last eligible source ID")
    harness.equal(levels.base(ctx, removable, mutations.MUT_STRONG), 1,
        "other acquired mutations survive deletion")

    records.grant_acquired(ctx, removable,
        mutations.MUT_MUTATION_RESISTANCE, 3)

    local protected = transition.remove_random(ctx, removable,
        choices.ANY, false)

    harness.equal(protected.kind, "resisted",
        "maximum intrinsic resistance blocks mutation loss")

    local forced_loss = transition.remove_random(ctx, removable,
        choices.ANY, true)

    harness.equal(forced_loss.kind, "removed",
        "forced mutation loss bypasses intrinsic resistance")

    local partly_resistant = player(ctx)

    records.grant_acquired(ctx, partly_resistant,
        mutations.MUT_MUTATION_RESISTANCE, 2)
    records.grant_acquired(ctx, partly_resistant,
        mutations.MUT_STRONG, 1)

    local resisted_loss = transition.remove_random(ctx,
        partly_resistant, choices.ANY, false)

    harness.equal(resisted_loss.kind, "resisted",
        "level-two resistance blocks loss on the source coin flip")

    local mummy = player(ctx, species.SP_MUMMY)

    records.grant_acquired(ctx, mummy, mutations.MUT_STRONG, 1)

    local undead_loss = transition.remove_random(ctx, mummy,
        choices.ANY, false)

    harness.equal(undead_loss.kind, "blocked",
        "lifeless undead resist ordinary mutation deletion")

    local forced_undead_loss = transition.remove_random(ctx, mummy,
        choices.ANY, true)

    harness.equal(forced_undead_loss.kind, "removed",
        "forced deletion can remove an undead acquired mutation")

    ctx:add(mummy, "core.attributes", {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })

    local unsafe_gain = transition.grant(ctx, mummy,
        mutations.MUT_AGILE, classes.ACQUIRED, false)

    harness.equal(unsafe_gain.kind, "decomposed",
        "direct acquired mutation decomposes an unsafe undead body")
    harness.equal(levels.base(ctx, mummy, mutations.MUT_AGILE), 0,
        "decomposition does not add a mutation level")

    local temporary_draws = harness.random_context(ctx, { 0 })
    local unsafe_temporary = transition.grant(temporary_draws, mummy,
        mutations.MUT_AGILE, classes.TEMPORARY, false)

    harness.equal(unsafe_temporary.kind, "blocked",
        "temporary mutation can fail before undead decomposition")
    harness.equal(temporary_draws:draws_used(), 1,
        "unsafe temporary mutation makes the source coinflip")

    local qazlal = player(ctx)
    local qazlal_gain = transition.grant_random(ctx, qazlal,
        choices.QAZLAL, classes.ACQUIRED, false)

    harness.equal(qazlal_gain.kind, "granted",
        "Qazlal grants a mutation when the first source candidate is valid")
    harness.equal(levels.base(ctx, qazlal,
        mutations.MUT_HEAT_VULNERABILITY), 2,
        "Qazlal grants two source levels when the mutation has room")

    local corrupt = player(ctx)
    local corrupt_draws = harness.random_context(ctx, { 3 })
    local corrupt_gain = transition.grant_random(corrupt_draws, corrupt,
        choices.CORRUPT, classes.ACQUIRED, false)

    harness.equal(corrupt_gain.kind, "granted",
        "Corrupt chooses a source bad mutation")
    harness.equal(levels.base(ctx, corrupt, mutations.MUT_WEAK), 2,
        "Corrupt grants two levels of a multi-level bad mutation")

    local nearly_full = player(ctx)

    records.grant_acquired(ctx, nearly_full,
        mutations.MUT_HEAT_VULNERABILITY, 2)

    local final_level = transition.grant_random(ctx, nearly_full,
        choices.QAZLAL, classes.ACQUIRED, false)

    harness.equal(final_level.kind, "granted",
        "Qazlal can fill a mutation's final level")
    harness.equal(levels.base(ctx, nearly_full,
        mutations.MUT_HEAT_VULNERABILITY), 3,
        "two-level roll stops at the source maximum")

    local saturated = player(ctx)

    for _, entry in ipairs({
        { id = mutations.MUT_STRONG, levels = 2 },
        { id = mutations.MUT_AGILE, levels = 2 },
        { id = mutations.MUT_CLEVER, levels = 2 },
        { id = mutations.MUT_ROBUST, levels = 3 },
        { id = mutations.MUT_HIGH_MAGIC, levels = 3 },
        { id = mutations.MUT_TOUGH_SKIN, levels = 3 },
    }) do
        records.grant_acquired(ctx, saturated, entry.id, entry.levels)
    end

    local forced_draws = harness.random_context(ctx, {
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    })
    local forced_random = transition.grant_random(forced_draws, saturated,
        choices.ANY, classes.ACQUIRED, true)

    harness.equal(forced_random.kind, "removed",
        "forced saturation bypasses the one-in-three refusal")
end

return test
