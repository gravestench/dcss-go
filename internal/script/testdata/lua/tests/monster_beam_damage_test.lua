
local catalog = require("policy.catalog")
local damage = require("policy.combat.monster_beams.damage")
local harness = require("tests.harness")
local component = require("constants.component")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local test = {}

-- Maximum legal rolls expose armour and resistance rounding boundaries.
local function maximum_random()
    local ctx = { draws = 0 }

    -- Count each maximum damage die to compare flavour-specific resistance after rolling.
    function ctx:random(_, bound)
        self.draws = self.draws + 1

        return bound - 1
    end

    return ctx
end

-- Bolt of Magma resists only its fifty-five-percent fire portion.
function test.run()
    local fire = catalog.get("monster_beams", spells.SPELL_BOLT_OF_FIRE)
    local lightning = catalog.get("monster_beams",
        spells.SPELL_LIGHTNING_BOLT)
    local cold = catalog.get("monster_beams", spells.SPELL_BOLT_OF_COLD)
    local ice = catalog.get("monster_beams", spells.SPELL_THROW_ICICLE)
    local lava = catalog.get("monster_beams", spells.SPELL_BOLT_OF_MAGMA)
    local poison = catalog.get("monster_beams", spells.SPELL_VENOM_BOLT)
    local poison_arrow = catalog.get("monster_beams",
        spells.SPELL_POISON_ARROW)
    local dart = catalog.get("monster_beams", spells.SPELL_MAGIC_DART)
    local damnation = catalog.get("monster_beams",
        spells.SPELL_HURL_DAMNATION)
    local energy = catalog.get("monster_beams", spells.SPELL_ENERGY_BOLT)
    local dispel = catalog.get("monster_beams",
        spells.SPELL_DISPEL_UNDEAD_RANGE)
    local holy = catalog.get("monster_beams", spells.SPELL_HOLY_BREATH)
    local crystal = catalog.get("monster_beams", spells.SPELL_CRYSTAL_BOLT)
    local miasma = catalog.get("monster_beams", spells.SPELL_MIASMA_BREATH)
    local stunning = catalog.get("monster_beams",
        spells.SPELL_STUNNING_BURST)
    local metal = catalog.get("monster_beams",
        spells.SPELL_METAL_SPLINTERS)
    local wood = catalog.get("monster_beams",
        spells.SPELL_SPLINTERSPRAY)
    local ctx = maximum_random()

    harness.equal(damage.armour(ctx, 20, 4, fire), 16,
        "Bolt of Fire uses ordinary beam armour")
    harness.equal(damage.armour(ctx, 20, 4, lightning), 18,
        "Lightning Bolt uses half beam armour")
    harness.equal(damage.armour(ctx, 20, 4, stunning), 16,
        "Stunning Burst uses ordinary beam armour")
    local before_frag = ctx.draws

    harness.equal(damage.armour(ctx, 20, 4, metal), 8,
        "Metal Splinters rolls armour three times")
    harness.equal(ctx.draws - before_frag, 3,
        "fragment armour consumes three saved draws")
    harness.equal(damage.armour(ctx, 20, 4, wood), 8,
        "Splinterspray uses the same triple armour rule")

    -- Damnation and Dispel Undead bypass armour without consuming an armour
    -- roll, preserving subsequent seeded beam damage.
    local before = ctx.draws

    harness.equal(damage.armour(ctx, 20, 4, damnation), 20,
        "Damnation bypasses beam armour")
    harness.equal(ctx.draws, before,
        "Damnation does not roll armour")
    harness.equal(damage.armour(ctx, 20, 4, dispel), 20,
        "Dispel Undead ignores beam armour")
    harness.equal(ctx.draws, before,
        "Dispel Undead does not roll armour")

    -- Supply only the defender records used by beam damage, rejecting unrelated actor lookups.
    function ctx:get(entity, id)
        if entity ~= 101 and entity ~= 102 and
            entity ~= 103 and entity ~= 104 and entity ~= 105 then
            return nil
        end

        if id == component.ACTOR then
            if entity == 104 then
                return { kind_id = monsters.MONS_SKELETON }
            end

            if entity == 105 then
                return { kind_id = monsters.MONS_OPHAN }
            end

            if entity == 103 then
                return { kind_id = monsters.MONS_ORB_OF_DESTRUCTION }
            end

            if entity == 102 then
                return { kind_id = monsters.MONS_HELLION }
            end

            return { kind_id = monsters.MONS_FIRE_DRAGON }
        end

        if id == component.HEALTH then
            return { current = 40 }
        end

        return nil
    end

    -- Keep optional status components absent so resistance alone determines the result.
    function ctx:has()
        return false
    end

    -- Use an unrelated player ID so monster beam calculations never take a player-only path.
    function ctx:player()
        return 999
    end

    -- One defender table below supplies distinct holiness and resistances for
    -- each beam flavor, including immunity and vulnerability cases.
    harness.equal(damage.resisted(ctx, 101, 20, fire), 4,
        "fire dragon rF2 divides Bolt of Fire damage by five")
    harness.equal(damage.resisted(ctx, 101, 20, cold), 30,
        "fire dragon rC-1 amplifies Bolt of Cold damage")
    harness.equal(damage.resisted(ctx, 101, 20, dart), 20,
        "Magic Dart has no elemental resistance adjustment")
    harness.equal(damage.resisted(ctx, 101, 20, metal), 20,
        "metal fragments have no elemental resistance")
    harness.equal(damage.resisted(ctx, 101, 20, wood), 20,
        "wood fragments have no elemental resistance")
    harness.equal(damage.resisted(ctx, 101, 20, ice), 24,
        "Throw Icicle resists only its forty-percent cold portion")
    harness.equal(damage.resisted(ctx, 101, 20, lava), 11,
        "Bolt of Magma resists only its fifty-five-percent fire portion")
    harness.equal(damage.resisted(ctx, 101, 20, poison), 6,
        "rPois1 divides a Venom Bolt's poison damage by three")
    harness.equal(damage.resisted(ctx, 101, 20, poison_arrow), 10,
        "Poison Arrow leaves its thirty-percent physical part")
    harness.equal(damage.resisted(ctx, 101, 20, damnation), 20,
        "Damnation bypasses ordinary elemental resistance")
    harness.equal(damage.resisted(ctx, 102, 20, damnation), 0,
        "a damnation-resistant monster takes no Damnation damage")
    harness.equal(damage.resisted(ctx, 101, 20, energy), 20,
        "Energy Bolt deals untyped devastation damage")
    harness.equal(damage.resisted(ctx, 103, 20, energy), 0,
        "an orb of destruction is immune to Energy Bolt")
    harness.equal(damage.resisted(ctx, 101, 20, dispel), 0,
        "Dispel Undead leaves a living monster unaffected")
    harness.equal(damage.resisted(ctx, 104, 20, dispel), 20,
        "Dispel Undead damages an undead monster")
    harness.equal(damage.resisted(ctx, 104, 20, holy), 30,
        "Holy Breath amplifies damage against undead monsters")
    harness.equal(damage.resisted(ctx, 105, 20, holy), 0,
        "a holy monster ignores Holy Breath")
    harness.equal(damage.resisted(ctx, 104, 20, miasma), 0,
        "an undead monster ignores Miasma Breath")
    harness.equal(damage.resisted(ctx, 101, 20, miasma), 20,
        "a living monster takes Miasma Breath damage")
    harness.equal(damage.resisted(ctx, 101, 20, crystal), 30,
        "Crystal Bolt can select cold against a cold-vulnerable monster")

    -- Force zero for the later stochastic damage branch after fixed-dice expectations.
    function ctx:random()
        return 0
    end

    harness.equal(damage.resisted(ctx, 101, 20, crystal), 4,
        "Crystal Bolt can select fire against a fire-resistant monster")
end

return test
