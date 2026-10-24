package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/character"
	"crawl/internal/ecs"
	"crawl/internal/terrain"
	"github.com/gravestench/akara"
)

func grantSelfStatusSpell(t *testing.T, g *Game, spellID string) {
	t.Helper()
	grantTestSpell(t, g, spellID)

	attributes, _ := g.stores.Attributes.Get(g.player)

	attributes.Intelligence = 100

	skills, _ := g.stores.Skills.Get(g.player)
	seen := make(map[string]bool)
	trained := map[string]bool{
		"SK_SPELLCASTING":   true,
		"SK_AIR_MAGIC":      true,
		"SK_ICE_MAGIC":      true,
		"SK_NECROMANCY":     true,
		"SK_TRANSMUTATIONS": true,
		"SK_HEXES":          true,
	}

	for index := range skills.Entries {
		id := skills.Entries[index].ID

		if trained[id] {
			skills.Entries[index].Level = 27
		}

		seen[id] = true
	}

	for _, id := range []string{
		"SK_SPELLCASTING",
		"SK_AIR_MAGIC",
		"SK_ICE_MAGIC",
		"SK_NECROMANCY",
		"SK_TRANSMUTATIONS",
		"SK_HEXES",
	} {
		if !seen[id] {
			skills.Entries = append(skills.Entries, character.Skill{
				ID:    id,
				Level: 27,
			})
		}
	}

	if _, err := g.stores.Skills.Set(g.player, *skills); err != nil {
		t.Fatal(err)
	}
}

func grantStatusForSavedFixture(t *testing.T, g *Game, spellID string) func() {
	t.Helper()
	progress, _ := g.stores.Progression.Get(g.player)
	attributes, _ := g.stores.Attributes.Get(g.player)
	magic, _ := g.stores.Magic.Get(g.player)
	skills, _ := g.stores.Skills.Get(g.player)
	startProgress := *progress
	startAttributes := *attributes
	startMagic := *magic
	startSkills := append([]character.Skill(nil), skills.Entries...)
	grantSelfStatusSpell(t, g, spellID)

	return func() {
		earnedXP := progress.TotalXP

		*progress = startProgress
		progress.TotalXP = earnedXP
		*attributes = startAttributes
		*magic = startMagic
		skills.Entries = startSkills

		if _, err := g.stores.Progression.Set(g.player, *progress); err != nil {
			t.Fatal(err)
		}

		if _, err := g.stores.Attributes.Set(g.player, *attributes); err != nil {
			t.Fatal(err)
		}

		if _, err := g.stores.Magic.Set(g.player, *magic); err != nil {
			t.Fatal(err)
		}

		if _, err := g.stores.Skills.Set(g.player, *skills); err != nil {
			t.Fatal(err)
		}
	}
}

func TestSelfStatusSpellsUseLuaEffects(t *testing.T) {
	cases := []struct {
		spellID string
		field   string
		message string
	}{
		{
			spellID: "SPELL_SWIFTNESS",
			field:   "swift_aut",
			message: "You feel quick.",
		},

		{
			spellID: "SPELL_WEREBLOOD",
			field:   "wereblood_aut",
			message: "Your blood is infused with primal strength.",
		},

		{
			spellID: "SPELL_OZOCUBUS_ARMOUR",
			field:   "ice_armour_aut",
			message: "A film of ice covers your body!",
		},

		{
			spellID: "SPELL_DEATHS_DOOR",
			field:   "death_door_aut",
			message: "You stand defiantly in death's doorway!",
		},

		{
			spellID: "SPELL_SILENCE",
			field:   "silence_aut",
			message: "A profound silence engulfs you.",
		},
	}

	for _, tc := range cases {
		t.Run(tc.spellID, func(t *testing.T) {
			g := newZapGame(t)
			grantSelfStatusSpell(t, g, tc.spellID)
			result, err := g.Step(Command{
				Kind:    CommandForceCast,
				SpellID: tc.spellID,
			})

			if err != nil {
				t.Fatal(err)
			}

			if !g.scripts.Components()["magic.player_status"].Has(g.player) {
				t.Fatalf("%s produced no Lua status: %+v", tc.spellID, result.Events)
			}

			if result.Spent == 0 ||
				luaIntField(t, g, "magic.player_status", tc.field) <= 0 {
				t.Fatalf("%s produced no active Lua status: %+v", tc.spellID, result.Events)
			}

			for _, event := range result.Events {
				if strings.Contains(event.Text, tc.message) {
					return
				}
			}

			t.Fatalf("%s did not emit %q: %+v", tc.spellID, tc.message, result.Events)
		})
	}
}

func TestSwiftnessCastShortensMovement(t *testing.T) {
	g := newStepGame(t)
	grantSelfStatusSpell(t, g, "SPELL_SWIFTNESS")

	if _, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SWIFTNESS",
	}); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind: CommandMove,
		DX:   1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent < 7 || result.Spent > 8 {
		t.Fatalf("Swiftness move took %d aut, want 7 or 8", result.Spent)
	}
}

func TestOzocubusArmourStatusRaisesDisplayedAC(t *testing.T) {
	g := newStepGame(t)
	before := g.View().PlayerAC
	state := testPlayerStatus()

	state["ice_armour_aut"] = int64(400)
	state["ice_armour_power"] = int64(100)

	if _, err := g.scripts.Components()["magic.player_status"].Set(g.player, state); err != nil {
		t.Fatal(err)
	}

	after := g.View().PlayerAC

	if after <= before {
		t.Fatalf("Ozocubus Armour AC = %d, was %d", after, before)
	}
}

func TestSilenceCastStopsNextPlayerSpell(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_SILENCE")
	grantSelfStatusSpell(t, g, "SPELL_SWIFTNESS")

	cast, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SILENCE",
	})

	if err != nil {
		t.Fatal(err)
	}

	if luaIntField(t, g, "magic.player_status", "silence_aut") <= 0 {
		t.Fatalf("Silence failed to start: %+v", cast.Events)
	}

	blocked, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SWIFTNESS",
	})

	if err != nil {
		t.Fatal(err)
	}

	if blocked.Spent != 0 {
		t.Fatalf("spell cast inside Silence spent %d aut", blocked.Spent)
	}
}

func testPlayerStatus() map[string]any {
	return map[string]any{
		"swift_aut":               int64(0),
		"swift_return_aut":        int64(0),
		"swift_phase":             int64(0),
		"wereblood_aut":           int64(0),
		"wereblood_bonus":         int64(0),
		"silence_aut":             int64(0),
		"ice_armour_aut":          int64(0),
		"ice_armour_power":        int64(0),
		"death_door_aut":          int64(0),
		"death_door_hp":           int64(0),
		"death_door_cooldown_aut": int64(0),
		"blink_cooldown_aut":      int64(0),
		"confusing_touch_aut":     int64(0),
		"confusing_touch_power":   int64(0),
		"portal_projectile_aut":   int64(0),
		"portal_projectile_power": int64(0),
		"disjunction_aut":         int64(0),
		"vertigo_aut":             int64(0),
	}
}

func luaIntField(t *testing.T, g *Game, component, field string) int64 {
	return luaIntFieldOn(t, g, g.player, component, field)
}

func luaIntFieldOn(t *testing.T, g *Game, entity akara.Entity,
	component, field string) int64 {
	t.Helper()
	value, found := g.scripts.Components()[component].Get(entity)

	if !found {
		t.Fatalf("player has no %s", component)
	}

	raw, err := value.Get(field)

	if err != nil {
		t.Fatal(err)
	}

	integer, ok := raw.(int64)

	if !ok {
		t.Fatalf("%s.%s = %T", component, field, raw)
	}

	return integer
}

func testPlayerWait(t *testing.T, g *Game) {
	t.Helper()
	_, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}
}

func TestSwiftnessSecondPhasePersistsThroughSave(t *testing.T) {
	g := newStepGame(t)
	state := testPlayerStatus()

	state["swift_aut"] = int64(10)
	state["swift_return_aut"] = int64(40)
	state["swift_phase"] = int64(1)

	if _, err := g.scripts.Components()["magic.player_status"].Set(g.player, state); err != nil {
		t.Fatal(err)
	}

	testPlayerWait(t, g)

	if got := luaIntField(t, g, "magic.player_status", "swift_phase"); got != 2 {
		t.Fatalf("Swiftness phase = %d, want sluggish phase", got)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	for range 4 {
		testPlayerWait(t, loaded)
	}

	if got := luaIntField(t, loaded, "magic.player_status", "swift_phase"); got != 0 {
		t.Fatalf("saved sluggish phase ended at %d, want 0", got)
	}
}

func TestDeathsDoorBlocksPoisonDamageAndRegen(t *testing.T) {
	g := newStepGame(t)
	state := testPlayerStatus()

	state["death_door_aut"] = int64(50)
	state["death_door_hp"] = int64(3)

	if _, err := g.scripts.Components()["magic.player_status"].Set(g.player, state); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(g.player)

	health.Current = 3

	regen, _ := g.stores.Regeneration.Get(g.player)

	regen.HPProgress = 99

	if _, err := g.stores.Poison.Set(g.player, ecs.Poison{
		AmountScaled:    4000,
		SourceMonsterID: "MONS_ADDER",
	}); err != nil {
		t.Fatal(err)
	}

	testPlayerWait(t, g)

	if health.Current != 3 || regen.HPProgress != 99 {
		t.Fatalf("Death's Door HP/progress = %d/%d, want 3/99",
			health.Current, regen.HPProgress)
	}
}

func TestPlayerFormExpiresAfterSavedAut(t *testing.T) {
	g := newStepGame(t)

	if _, err := g.scripts.Components()["magic.player_form"].Set(g.player, map[string]any{
		"form_id":       "spider",
		"remaining_aut": int64(30),
		"power":         int64(20),
	}); err != nil {
		t.Fatal(err)
	}

	testPlayerWait(t, g)

	if got := luaIntField(t, g, "magic.player_form", "remaining_aut"); got != 20 {
		t.Fatalf("form aut = %d, want 20", got)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
	testPlayerWait(t, loaded)
	testPlayerWait(t, loaded)

	if loaded.scripts.Components()["magic.player_form"].Has(loaded.player) {
		t.Fatal("saved form did not expire")
	}
}

func TestIceFormSavedHPRescalesBackOnExpiry(t *testing.T) {
	g := newStepGame(t)
	health, _ := g.stores.Health.Get(g.player)
	baseMax := health.Max
	formedMax := baseMax * 12 / 10

	health.Max = formedMax
	health.Current = formedMax

	if _, err := g.scripts.Components()["magic.player_form"].Set(g.player, map[string]any{
		"form_id":       "ice_beast",
		"remaining_aut": int64(20),
		"power":         int64(40),
	}); err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
	testPlayerWait(t, loaded)
	testPlayerWait(t, loaded)

	stored, _ := loaded.stores.Health.Get(loaded.player)

	if stored.Max != baseMax || stored.Current != baseMax {
		t.Fatalf("Ice Form expiry HP = %d/%d, want %d/%d",
			stored.Current, stored.Max, baseMax, baseMax)
	}
}

func TestIceFormCastScalesHP(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_ICE_FORM")
	beforeHP, _ := g.stores.Health.Get(g.player)
	baseMax := beforeHP.Max

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_ICE_FORM",
	})

	if err != nil {
		t.Fatal(err)
	}

	form, found := g.scripts.Components()["magic.player_form"].Get(g.player)

	if !found {
		t.Fatalf("Ice Form did not start: %+v", result.Events)
	}

	formID, err := form.Get("form_id")

	if err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(g.player)

	if formID != "ice_beast" || health.Max <= baseMax {
		t.Fatalf("Ice Form = %v, HP %d -> %d", formID, baseMax, health.Max)
	}
}

func TestSpellFlightAllowsTransformationOverLava(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_SPIDER_FORM")
	position, _ := g.stores.Positions.Get(g.player)

	if err := g.levels[position.LevelID].SetCell(position.X, position.Y,
		terrain.Lava); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["zap.flight"].Set(g.player,
		map[string]any{"remaining_aut": int64(100)}); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SPIDER_FORM",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 ||
		!g.scripts.Components()["magic.player_form"].Has(g.player) {
		t.Fatalf("flight did not permit Spider Form over lava: %+v", result.Events)
	}
}

func TestIceFormProjectionRaisesAC(t *testing.T) {
	g := newStepGame(t)
	before := g.View().PlayerAC
	health, _ := g.stores.Health.Get(g.player)

	health.Max = health.Max * 12 / 10
	health.Current = health.Max

	if _, err := g.scripts.Components()["magic.player_form"].Set(g.player, map[string]any{
		"form_id":       "ice_beast",
		"remaining_aut": int64(300),
		"power":         int64(100),
	}); err != nil {
		t.Fatal(err)
	}

	after := g.View().PlayerAC

	if after <= before {
		t.Fatalf("Ice Form AC = %d, was %d", after, before)
	}
}

func TestLichFormRejectsDeathsDoorWithoutTime(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_NECROMUTATION")
	state := testPlayerStatus()

	state["death_door_aut"] = int64(100)
	state["death_door_hp"] = int64(3)

	if _, err := g.scripts.Components()["magic.player_status"].Set(g.player, state); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_NECROMUTATION",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 ||
		g.scripts.Components()["magic.player_form"].Has(g.player) {
		t.Fatalf("Lich Form bypassed Death's Door: %+v", result.Events)
	}
}

func TestPlayerFormSpellsRegisterRealLuaEffects(t *testing.T) {
	cases := []struct {
		spellID string
		formID  string
	}{
		{
			spellID: "SPELL_SPIDER_FORM",
			formID:  "spider",
		},

		{
			spellID: "SPELL_BLADE_HANDS",
			formID:  "blade_hands",
		},

		{
			spellID: "SPELL_STATUE_FORM",
			formID:  "statue",
		},

		{
			spellID: "SPELL_DRAGON_FORM",
			formID:  "dragon",
		},

		{
			spellID: "SPELL_NECROMUTATION",
			formID:  "lich",
		},

		{
			spellID: "SPELL_STORM_FORM",
			formID:  "storm",
		},
	}

	for _, tc := range cases {
		t.Run(tc.spellID, func(t *testing.T) {
			g := newZapGame(t)
			grantSelfStatusSpell(t, g, tc.spellID)

			result, err := g.Step(Command{
				Kind:    CommandForceCast,
				SpellID: tc.spellID,
			})

			if err != nil {
				t.Fatal(err)
			}

			form, found := g.scripts.Components()["magic.player_form"].Get(g.player)

			if !found {
				t.Fatalf("%s did not transform: %+v", tc.spellID, result.Events)
			}

			formID, err := form.Get("form_id")

			if err != nil {
				t.Fatal(err)
			}

			if formID != tc.formID {
				t.Fatalf("%s form = %v, want %s", tc.spellID, formID, tc.formID)
			}
		})
	}
}

func TestBeastlyAppendageGrantsSourceMutations(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_BEASTLY_APPENDAGE")

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_BEASTLY_APPENDAGE",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatalf("Beastly Appendage spent no time: %+v", result.Events)
	}

	if got := luaIntField(t, g, "magic.player_form", "appendage_mask"); got != 5 {
		t.Fatalf("human appendages = %d, want horns and talons", got)
	}

	seenHorns := false
	seenTalons := false

	for _, event := range result.Events {
		seenHorns = seenHorns || strings.Contains(event.Text, "large bovine horns")
		seenTalons = seenTalons ||
			strings.Contains(event.Text, "feet morph into talons")
	}

	if !seenHorns || !seenTalons {
		t.Fatalf("Beastly Appendage messages = %+v", result.Events)
	}

}

func TestBeastlyAppendageSavedMutationsExpire(t *testing.T) {
	g := newStepGame(t)

	if _, err := g.scripts.Components()["magic.player_form"].Set(g.player, map[string]any{
		"form_id":        "appendage",
		"remaining_aut":  int64(10),
		"power":          int64(20),
		"appendage_mask": int64(5),
	}); err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if got := luaIntField(t, loaded, "magic.player_form", "appendage_mask"); got != 5 {
		t.Fatalf("saved appendages = %d, want 5", got)
	}

	testPlayerWait(t, loaded)

	if loaded.scripts.Components()["magic.player_form"].Has(loaded.player) {
		t.Fatal("Beastly Appendage did not expire")
	}
}

func TestBeastlyAppendageTalonsAddAuxiliaryClaw(t *testing.T) {
	g := newStepGame(t)

	if _, err := g.scripts.Components()["magic.player_form"].Set(g.player, map[string]any{
		"form_id":        "appendage",
		"remaining_aut":  int64(300),
		"power":          int64(20),
		"appendage_mask": int64(4),
	}); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	rat := ratID(t, g)
	ratHealth, _ := g.stores.Health.Get(rat)

	ratHealth.Max = 1000
	ratHealth.Current = 1000

	playerHealth, _ := g.stores.Health.Get(g.player)

	playerHealth.Max = 1000
	playerHealth.Current = 1000

	progress, _ := g.stores.Progression.Get(g.player)

	progress.Level = 27

	for range 6 {
		result, err := g.Step(Command{
			Kind: CommandMove,
			DX:   1,
		})

		if err != nil {
			t.Fatal(err)
		}

		for _, event := range result.Events {
			if strings.Contains(event.Text, "You claw the rat") {
				return
			}
		}
	}

	t.Fatal("temporary talons produced no auxiliary claw attack")
}

func TestConfusingTouchStartsSavedContactStatus(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_CONFUSING_TOUCH")

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_CONFUSING_TOUCH",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 ||
		luaIntField(t, g, "magic.player_status", "confusing_touch_aut") <= 0 ||
		luaIntField(t, g, "magic.player_status", "confusing_touch_power") <= 0 {
		t.Fatalf("Confusing Touch did not start: %+v", result.Events)
	}

	for _, event := range result.Events {
		if strings.Contains(event.Text, "glow red") {
			return
		}
	}

	t.Fatalf("Confusing Touch emitted no source glow message: %+v", result.Events)
}

func TestConfusingTouchReplacesMeleeDamageWithConfusion(t *testing.T) {
	g := newStepGame(t)
	state := testPlayerStatus()

	state["confusing_touch_aut"] = int64(200)
	state["confusing_touch_power"] = int64(1000)

	if _, err := g.scripts.Components()["magic.player_status"].Set(g.player, state); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	rat := ratID(t, g)
	ratHealth, _ := g.stores.Health.Get(rat)

	ratHealth.Max = 1000
	ratHealth.Current = 1000

	playerHealth, _ := g.stores.Health.Get(g.player)

	playerHealth.Max = 1000
	playerHealth.Current = 1000

	for range 10 {
		result, err := g.Step(Command{
			Kind: CommandMove,
			DX:   1,
		})

		if err != nil {
			t.Fatal(err)
		}

		if !g.scripts.Components()["magic.monster_confusion"].Has(rat) {
			continue
		}

		if ratHealth.Current != 1000 {
			t.Fatalf("Confusing Touch dealt %d main damage: %+v",
				1000-ratHealth.Current, result.Events)
		}

		if got := luaIntField(t, g, "magic.player_status", "confusing_touch_aut"); got != 0 {
			t.Fatalf("successful touch retained %d aut", got)
		}

		return
	}

	t.Fatal("Confusing Touch did not confuse the rat")
}

func TestPortalProjectileStartsSavedAimingStatus(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_PORTAL_PROJECTILE")

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_PORTAL_PROJECTILE",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 ||
		luaIntField(t, g, "magic.player_status", "portal_projectile_aut") <= 0 ||
		luaIntField(t, g, "magic.player_status", "portal_projectile_power") <= 0 {
		t.Fatalf("Portal Projectile did not start: %+v", result.Events)
	}

	for _, event := range result.Events {
		if strings.Contains(event.Text, "begin teleporting projectiles") {
			return
		}
	}

	t.Fatalf("Portal Projectile emitted no source message: %+v", result.Events)
}

func TestPortalProjectileTargetsAimedMonsterAndSpendsOneMP(t *testing.T) {
	g := newStepGame(t)

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	cloneRatOnRay(t, g, 5, 1)
	equipPlayerLauncher(t, g, "WPN_SLING")

	state := testPlayerStatus()

	state["portal_projectile_aut"] = int64(200)
	state["portal_projectile_power"] = int64(1000)

	if _, err := g.scripts.Components()["magic.player_status"].Set(g.player, state); err != nil {
		t.Fatal(err)
	}

	near := ratID(t, g)
	far, found := g.levels[1].ActorAt(5, 1)

	if !found {
		t.Fatal("no distant rat")
	}

	nearHealth, _ := g.stores.Health.Get(near)
	farHealth, _ := g.stores.Health.Get(far)

	nearHealth.Max = 100
	nearHealth.Current = 100
	farHealth.Max = 100
	farHealth.Current = 100

	magic, _ := g.stores.Magic.Get(g.player)
	beforeMP := magic.Current

	result, err := g.Step(Command{
		Kind: CommandFire,
		DX:   2,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 ||
		nearHealth.Current != 100 ||
		farHealth.Current >= 100 ||
		magic.Current != beforeMP-1 {
		t.Fatalf("portal shot near/far HP %d/%d, MP %d -> %d: %+v",
			nearHealth.Current, farHealth.Current, beforeMP, magic.Current, result.Events)
	}
}

func TestMassEnchantmentsApplySavedFearAndAnguish(t *testing.T) {
	for _, tc := range []struct {
		spellID string
		field   string
	}{
		{
			spellID: "SPELL_CAUSE_FEAR",
			field:   "fear_aut",
		},

		{
			spellID: "SPELL_ANGUISH",
			field:   "anguish_aut",
		},
	} {
		t.Run(tc.spellID, func(t *testing.T) {
			g := newZapGame(t)
			grantSelfStatusSpell(t, g, tc.spellID)
			rat := ratID(t, g)

			result, err := g.Step(Command{
				Kind:    CommandForceCast,
				SpellID: tc.spellID,
			})

			if err != nil {
				t.Fatal(err)
			}

			if result.Spent == 0 ||
				!g.scripts.Components()["magic.monster_mass_enchant"].Has(rat) {
				t.Fatalf("%s did not enchant rat: %+v", tc.spellID, result.Events)
			}

			if got := luaIntFieldOn(t, g, rat, "magic.monster_mass_enchant", tc.field); got <= 0 {
				t.Fatalf("%s duration = %d", tc.spellID, got)
			}
		})
	}
}

func TestAnguishReflectsActualMonsterDamage(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if _, err := g.scripts.Components()["magic.monster_mass_enchant"].Set(rat, map[string]any{
		"fear_aut":    int64(0),
		"anguish_aut": int64(300),
	}); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	ratHealth, _ := g.stores.Health.Get(rat)

	ratHealth.Max = 1000
	ratHealth.Current = 1000

	playerHealth, _ := g.stores.Health.Get(g.player)

	playerHealth.Max = 1000
	playerHealth.Current = 1000

	for range 20 {
		result, err := g.Step(Command{Kind: CommandWait})

		if err != nil {
			t.Fatal(err)
		}

		for _, event := range result.Events {
			if strings.Contains(event.Text, "wracked by anguish") {
				if ratHealth.Current >= 1000 || playerHealth.Current >= 1000 {
					t.Fatalf("Anguish did not reflect actual damage: %+v", result.Events)
				}

				return
			}
		}
	}

	t.Fatal("Anguish never reflected the adjacent rat's attacks")
}

func TestCauseFearMakesMonsterRetreat(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if _, err := g.scripts.Components()["magic.monster_mass_enchant"].Set(rat, map[string]any{
		"fear_aut":    int64(200),
		"anguish_aut": int64(0),
	}); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for range 3 {
		testPlayerWait(t, g)
	}

	position, _ := g.stores.Positions.Get(rat)

	if position.X <= 4 {
		t.Fatalf("feared rat remained at %+v instead of retreating", *position)
	}
}

func TestIntoxicateConfusesHumanMonsterAndInflictsVertigo(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_INTOXICATE")
	rat := ratID(t, g)
	actor, _ := g.stores.Actors.Get(rat)

	actor.KindID = "MONS_HOBGOBLIN"

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_INTOXICATE",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 ||
		!g.scripts.Components()["magic.monster_confusion"].Has(rat) ||
		luaIntField(t, g, "magic.player_status", "vertigo_aut") <= 0 {
		t.Fatalf("Intoxicate did not confuse or induce vertigo: %+v", result.Events)
	}
}

func TestVertigoReducesDisplayedEV(t *testing.T) {
	g := newStepGame(t)
	before := g.View().PlayerEV
	state := testPlayerStatus()

	state["vertigo_aut"] = int64(100)

	if _, err := g.scripts.Components()["magic.player_status"].Set(g.player, state); err != nil {
		t.Fatal(err)
	}

	if after := g.View().PlayerEV; after != max(1, before-5) {
		t.Fatalf("Vertigo EV %d -> %d, want -5 with minimum 1", before, after)
	}
}

func TestEnfeebleAppliesWeaknessToAimedMonster(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_ENFEEBLE")
	rat := ratID(t, g)

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_ENFEEBLE",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 ||
		!g.scripts.Components()["magic.monster_enfeeble"].Has(rat) ||
		luaIntFieldOn(t, g, rat, "magic.monster_enfeeble", "weak_aut") <= 0 {
		t.Fatalf("Enfeeble did not weaken aimed rat: %+v", result.Events)
	}
}

func TestHibernationSleepsAimedMonster(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_HIBERNATION")
	rat := ratID(t, g)

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_HIBERNATION",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 ||
		!g.scripts.Components()["magic.monster_stasis"].Has(rat) {
		t.Fatalf("Hibernation did not sleep aimed rat: %+v", result.Events)
	}

	playerHealth, _ := g.stores.Health.Get(g.player)
	before := playerHealth.Current

	for range 3 {
		testPlayerWait(t, g)
	}

	if playerHealth.Current != before {
		t.Fatalf("hibernating rat attacked player: HP %d -> %d", before, playerHealth.Current)
	}
}

func TestPetrifyAdvancesFromSlowToStone(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_PETRIFY")
	rat := ratID(t, g)

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_PETRIFY",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 ||
		luaIntFieldOn(t, g, rat, "magic.monster_stasis", "petrifying_aut") <= 0 {
		t.Fatalf("Petrify did not start slow stage: %+v", result.Events)
	}

	second, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_PETRIFY",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if second.Spent == 0 ||
		luaIntFieldOn(t, g, rat, "magic.monster_stasis", "petrified_aut") <= 0 {
		t.Fatalf("second Petrify did not complete petrification: %+v", second.Events)
	}

	playerHealth, _ := g.stores.Health.Get(g.player)
	before := playerHealth.Current
	testPlayerWait(t, g)

	if playerHealth.Current != before {
		t.Fatalf("petrified rat attacked player: HP %d -> %d", before, playerHealth.Current)
	}
}

func TestCharmingMakesAimedMonsterFriendly(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_CHARMING")
	rat := ratID(t, g)

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_CHARMING",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 ||
		luaIntFieldOn(t, g, rat, "magic.monster_allegiance", "charm_aut") <= 0 {
		t.Fatalf("Charm did not enchant aimed rat: %+v", result.Events)
	}
}

func TestCharmedMonsterAttacksHostileMonster(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_CHARMING")
	cloneRatOnRay(t, g, 5, 1)
	friend := ratID(t, g)
	foe, found := g.levels[1].ActorAt(5, 1)

	if !found {
		t.Fatal("no second rat")
	}

	friendHealth, _ := g.stores.Health.Get(friend)
	foeHealth, _ := g.stores.Health.Get(foe)

	friendHealth.Max = 200
	friendHealth.Current = 200
	foeHealth.Max = 200
	foeHealth.Current = 200

	_, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_CHARMING",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if luaIntFieldOn(t, g, friend, "magic.monster_allegiance", "charm_aut") <= 0 {
		t.Fatal("first rat was not charmed")
	}

	for range 10 {
		testPlayerWait(t, g)

		if foeHealth.Current < 200 {
			return
		}
	}

	t.Fatal("charmed rat never damaged hostile rat")
}

func TestDiscordFrenzyTurnsMonstersAgainstEachOther(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_DISCORD")
	cloneRatOnRay(t, g, 5, 1)

	if err := g.levels[1].MoveActor(g.player, 1, 1); err != nil {
		t.Fatal(err)
	}

	first := ratID(t, g)
	second, found := g.levels[1].ActorAt(5, 1)

	if !found {
		t.Fatal("no second rat")
	}

	firstHealth, _ := g.stores.Health.Get(first)
	secondHealth, _ := g.stores.Health.Get(second)

	firstHealth.Max = 200
	firstHealth.Current = 200
	secondHealth.Max = 200
	secondHealth.Current = 200

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_DISCORD",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 ||
		luaIntFieldOn(t, g, first, "magic.monster_allegiance", "frenzy_aut") <= 0 {
		t.Fatalf("Discord did not frenzy first rat: %+v", result.Events)
	}

	for range 10 {
		testPlayerWait(t, g)

		if firstHealth.Current < 200 || secondHealth.Current < 200 {
			return
		}
	}

	t.Fatal("frenzied rats never damaged one another")
}

func TestPolymorphChangesMonsterIdentityAndKeepsOriginal(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_POLYMORPH")
	rat := ratID(t, g)

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_POLYMORPH",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	actor, _ := g.stores.Actors.Get(rat)

	if result.Spent == 0 ||
		actor.KindID == "MONS_RAT" ||
		!g.scripts.Components()["magic.monster_polymorph"].Has(rat) {
		t.Fatalf("Polymorph did not change rat: %s, %+v", actor.KindID, result.Events)
	}
}

// Monster placement rolls the source three-form set once. The same set must
// survive a save before any spell changes the body or rerolls its choices.
func TestMonsterPolymorphSetPersistsThroughSave(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	sets := g.scripts.Components()["monster.polymorph_set"]
	before, found := sets.Get(rat)

	if !found {
		t.Fatal("spawned rat has no polymorph set")
	}

	forms, err := before.Get("forms")

	if err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	after, found := loaded.scripts.Components()["monster.polymorph_set"].Get(rat)

	if !found {
		t.Fatal("restored rat lost its polymorph set")
	}

	restoredForms, err := after.Get("forms")

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(forms, restoredForms) {
		t.Fatalf("polymorph forms changed on restore: %v to %v",
			forms, restoredForms)
	}
}

func TestPolymorphIdentityPersistsThroughSave(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	actor, _ := g.stores.Actors.Get(rat)

	actor.KindID = "MONS_QUOKKA"
	actor.Speed = 12

	if _, err := g.scripts.Components()["magic.monster_polymorph"].Set(rat,
		map[string]any{"original_kind_id": "MONS_RAT"}); err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	seen := false

	for _, entity := range loaded.stores.Actors.Entities() {
		candidate, _ := loaded.stores.Actors.Get(entity)

		if candidate.KindID == "MONS_QUOKKA" &&
			loaded.scripts.Components()["magic.monster_polymorph"].Has(entity) {
			seen = true
			break
		}
	}

	if !seen {
		t.Fatal("restored monster lost polymorph identity")
	}
}

func TestDiscordFrenzyActionPersistsThroughSave(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if _, err := g.scripts.Components()["magic.monster_allegiance"].Set(rat,
		map[string]any{
			"charm_aut":   int64(0),
			"frenzy_aut":  int64(100),
			"fatigue_aut": int64(0),
		}); err != nil {
		t.Fatal(err)
	}

	testPlayerWait(t, g)
	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	for _, entity := range loaded.stores.Actors.Entities() {
		if loaded.scripts.Components()["magic.monster_allegiance"].Has(entity) &&
			luaIntFieldOn(t, loaded, entity,
				"magic.monster_allegiance", "frenzy_aut") > 0 {
			return
		}
	}

	t.Fatal("saved frenzy action lost monster status")
}

func TestPolymorphedMonsterDeathAndCorpseSave(t *testing.T) {
	g, err := NewScenario(corpseDropSeed(t, true), "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		g.Close()
	})

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	rat := ratID(t, g)
	actor, _ := g.stores.Actors.Get(rat)

	actor.KindID = "MONS_QUOKKA"
	actor.Speed = 12

	health, _ := g.stores.Health.Get(rat)

	health.Current = 1

	progress, _ := g.stores.Progression.Get(g.player)
	beforeXP := progress.TotalXP

	if _, err := g.scripts.Components()["magic.monster_polymorph"].Set(rat,
		map[string]any{"original_kind_id": "MONS_RAT"}); err != nil {
		t.Fatal(err)
	}

	for range 100 {
		if _, err := g.Step(Command{
			Kind: CommandMove,
			DX:   1,
		}); err != nil {
			t.Fatal(err)
		}

		if health.Current == 0 {
			break
		}
	}

	if health.Current > 0 {
		t.Fatal("player did not kill polymorphed quokka")
	}

	if progress.TotalXP <= beforeXP {
		t.Fatalf("polymorphed quokka gave %d XP", progress.TotalXP-beforeXP)
	}

	corpses := g.stores.Corpses.Entities()

	if len(corpses) != 1 {
		t.Fatalf("polymorphed quokka left %d corpses", len(corpses))
	}

	corpse, _ := g.stores.Corpses.Get(corpses[0])

	if corpse.MonsterID != "MONS_QUOKKA" {
		t.Fatalf("polymorphed corpse is %s", corpse.MonsterID)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
}

func TestEnglaciationSlowsVisibleColdVulnerableMonster(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_ENGLACIATION")
	rat := ratID(t, g)
	actor, _ := g.stores.Actors.Get(rat)
	before := actor.Speed

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_ENGLACIATION",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 || !g.scripts.Components()["projectile.slow"].Has(rat) {
		t.Fatalf("Englaciation did not slow visible rat: %+v", result.Events)
	}

	if actor.Speed >= before {
		t.Fatalf("Englaciation speed %d, was %d", actor.Speed, before)
	}
}

func TestToxicRadiancePoisonsVisibleMonsterAndPersists(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_OLGREBS_TOXIC_RADIANCE")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Max = 200
	health.Current = 200

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_OLGREBS_TOXIC_RADIANCE",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 ||
		luaIntField(t, g, "magic.area_status", "toxic_radiance_aut") <= 0 ||
		health.Current >= 200 ||
		!g.scripts.Components()["projectile.poison"].Has(rat) {
		t.Fatalf("Toxic Radiance did not poison rat: %+v", result.Events)
	}

	saved := newStepGame(t)

	if _, err := saved.scripts.Components()["magic.area_status"].Set(saved.player,
		map[string]any{
			"corpse_rot_aut":       int64(0),
			"corpse_rot_power":     int64(0),
			"toxic_radiance_aut":   int64(80),
			"toxic_radiance_power": int64(50),
			"noxious_bog_aut":      int64(0),
		}); err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(saved.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if luaIntField(t, loaded, "magic.area_status", "toxic_radiance_aut") <= 0 {
		t.Fatal("Toxic Radiance expired during restore")
	}
}

func TestIgnitePoisonBurnsAndCuresPoisonedMonster(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_IGNITE_POISON")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Max = 200
	health.Current = 200

	if _, err := g.scripts.Components()["projectile.poison"].Set(rat,
		map[string]any{
			"degree":        int64(4),
			"remaining_aut": int64(100),
			"max_aut":       int64(100),
			"source":        g.player,
		}); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_IGNITE_POISON",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 ||
		health.Current >= 200 ||
		g.scripts.Components()["projectile.poison"].Has(rat) {
		t.Fatalf("Ignite Poison did not burn and clear poison: %+v", result.Events)
	}
}

func TestIgnitePoisonSetsNearbyToxicBogAblaze(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_IGNITE_POISON")

	for y := 1; y <= 2; y++ {
		for x := 2; x <= 6; x++ {
			if err := g.levels[1].SetCell(x, y, terrain.ToxicBog); err != nil {
				t.Fatal(err)
			}
		}
	}

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_IGNITE_POISON",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatal("Ignite Poison spent no time")
	}

	for _, entity := range g.scripts.Components()["world.cloud"].Entities() {
		value, _ := g.scripts.Components()["world.cloud"].Get(entity)
		kind, _ := value.Get("kind_id")

		if kind == "CLOUD_FIRE" {
			return
		}
	}

	t.Fatal("Ignite Poison made no fire cloud on visible toxic bog")
}

func placeAuraVictim(t *testing.T, g *Game, rat akara.Entity) {
	t.Helper()

	if err := g.levels[1].MoveActor(rat, 4, 1); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}
}

func TestCorpseRotAuraCreatesSavedMiasmaOnKill(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_CORPSE_ROT")
	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_CORPSE_ROT",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 ||
		luaIntField(t, g, "magic.area_status", "corpse_rot_aut") <= 0 {
		t.Fatalf("Corpse Rot did not start aura: %+v", result.Events)
	}

	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = 1
	placeAuraVictim(t, g, rat)

	for range 20 {
		if _, err := g.runAction(g.player, ecs.Intent{
			Kind: ecs.IntentMove,
			DX:   1,
		}, 10, "player"); err != nil {
			t.Fatal(err)
		}

		if health.Current == 0 {
			break
		}
	}

	if health.Current > 0 ||
		len(g.scripts.Components()["world.cloud"].Entities()) == 0 {
		playerPosition, _ := g.stores.Positions.Get(g.player)
		ratPosition, _ := g.stores.Positions.Get(rat)
		t.Fatalf("Corpse Rot kill did not create miasma: HP=%d player=%+v rat=%+v",
			health.Current, playerPosition, ratPosition)
	}
}

func TestInfestationMarksMonsterAndRaisesDeathScarab(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_INFESTATION")
	rat := ratID(t, g)
	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_INFESTATION",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 ||
		!g.scripts.Components()["magic.monster_infestation"].Has(rat) {
		t.Fatalf("Infestation did not mark rat: %+v", result.Events)
	}

	health, _ := g.stores.Health.Get(rat)

	health.Current = 1
	placeAuraVictim(t, g, rat)

	for range 20 {
		if _, err := g.runAction(g.player, ecs.Intent{
			Kind: ecs.IntentMove,
			DX:   1,
		}, 10, "player"); err != nil {
			t.Fatal(err)
		}

		if health.Current == 0 {
			break
		}
	}

	if health.Current > 0 {
		playerPosition, _ := g.stores.Positions.Get(g.player)
		ratPosition, _ := g.stores.Positions.Get(rat)
		t.Fatalf("player did not kill infested rat: HP=%d player=%+v rat=%+v",
			health.Current, playerPosition, ratPosition)
	}

	for _, entity := range g.stores.Actors.Entities() {
		actor, _ := g.stores.Actors.Get(entity)

		if actor.KindID == "MONS_DEATH_SCARAB" {
			return
		}
	}

	t.Fatal("infested rat did not raise a death scarab")
}

func TestMiasmaSlowUsesSavedActionTiming(t *testing.T) {
	g := newStepGame(t)

	if _, err := g.scripts.Components()["character.slow"].Set(g.player,
		map[string]any{"remaining_aut": int64(100)}); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 15 {
		t.Fatalf("miasma slow wait spent %d aut, want 15", result.Spent)
	}
}

func TestStatueFormResistsCorpseRotMiasma(t *testing.T) {
	g := newStepGame(t)

	if _, err := g.scripts.Components()["magic.player_form"].Set(g.player,
		map[string]any{
			"form_id":       "statue",
			"remaining_aut": int64(100),
			"power":         int64(50),
		}); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)
	marker, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["world.cloud"].Set(marker,
		map[string]any{
			"kind_id":          "CLOUD_MIASMA",
			"level_id":         int64(position.LevelID),
			"x":                int64(position.X),
			"y":                int64(position.Y),
			"decay_aut":        int64(100),
			"spread_rate":      int64(0),
			"exclusion_radius": int64(0),
			"source_actor_id":  uint64(0),
			"kill_category":    "KC_OTHER",
			"killer_type":      "KILL_MISC",
			"opaque":           false,
			"special_ints":     map[string]any{},
		}); err != nil {
		t.Fatal(err)
	}

	testPlayerWait(t, g)

	if g.stores.Poison.Has(g.player) ||
		g.scripts.Components()["character.slow"].Has(g.player) {
		t.Fatal("statue form took miasma poison or slow")
	}
}

func TestVileClutchGripsAndDamagesAimedMonster(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_BORGNJORS_VILE_CLUTCH")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Max = 200
	health.Current = 200

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_BORGNJORS_VILE_CLUTCH",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 ||
		!g.scripts.Components()["magic.monster_vile_clutch"].Has(rat) ||
		health.Current >= 200 {
		t.Fatalf("Vile Clutch did not grip and damage rat: %+v", result.Events)
	}
}

func TestNoxiousBogChangesTerrainAndHurtsGroundedMonster(t *testing.T) {
	g := newZapGame(t)
	resetStats := grantStatusForSavedFixture(t, g, "SPELL_NOXIOUS_BOG")
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)
	originalMax := health.Max

	health.Max = 200
	health.Current = 200

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_NOXIOUS_BOG",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 ||
		luaIntField(t, g, "magic.area_status", "noxious_bog_aut") <= 0 ||
		len(g.scripts.Components()["world.temporary_terrain"].Entities()) == 0 {
		t.Fatalf("Noxious Bog did not create saved terrain: %+v", result.Events)
	}

	if err := g.levels[1].MoveActor(rat, 4, 2); err != nil {
		t.Fatal(err)
	}

	testPlayerWait(t, g)

	if health.Current >= 200 {
		t.Fatalf("Noxious Bog dealt no damage to rat: %+v", result.Events)
	}

	health.Max = originalMax
	health.Current = min(originalMax, health.Current)
	resetStats()
	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if len(loaded.scripts.Components()["world.temporary_terrain"].Entities()) == 0 {
		t.Fatal("saved Noxious Bog terrain disappeared after restore")
	}
}

func TestFlightAvoidsToxicBogDamage(t *testing.T) {
	g := newStepGame(t)
	position, _ := g.stores.Positions.Get(g.player)

	if err := g.levels[position.LevelID].SetCell(position.X, position.Y,
		terrain.ToxicBog); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["zap.flight"].Set(g.player,
		map[string]any{"remaining_aut": int64(100)}); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(g.player)
	before := health.Current

	testPlayerWait(t, g)

	if health.Current != before || g.stores.Poison.Has(g.player) {
		t.Fatal("flying player was harmed by toxic bog")
	}
}

func TestInfestationAndVileClutchMarksSurviveSave(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if _, err := g.scripts.Components()["magic.monster_infestation"].Set(rat,
		map[string]any{"remaining_aut": int64(100)}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["magic.monster_vile_clutch"].Set(rat,
		map[string]any{
			"remaining_aut":   int64(100),
			"power":           int64(60),
			"held_aut":        int64(20),
			"escape_attempts": int64(1),
		}); err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
	savedRat := ratID(t, loaded)

	if luaIntFieldOn(t, loaded, savedRat,
		"magic.monster_infestation", "remaining_aut") != 100 ||
		luaIntFieldOn(t, loaded, savedRat,
			"magic.monster_vile_clutch", "held_aut") != 20 {
		t.Fatal("Infestation or Vile Clutch changed during restore")
	}
}
