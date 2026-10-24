package game

import (
	"fmt"
	"testing"
)

// Game decisions retain the whole spell library. The terminal paginates
// it, so the engine must not reject a valid list above 52 choices.
func TestLargeSpellSelectionRequest(t *testing.T) {
	options := make([]any, 60)

	for index := range options {
		options[index] = map[string]any{
			"id":    fmt.Sprintf("SPELL_%02d", index),
			"label": fmt.Sprintf("Spell %02d", index),
		}
	}

	request, err := selectionFromDecision(map[string]any{
		"kind":    "spell",
		"title":   "Cast which spell?",
		"options": options,
	})

	if err != nil {
		t.Fatal(err)
	}

	if len(request.Options) != 60 {
		t.Fatalf("large spell selection: %+v, %v", request, err)
	}
}

// These three options come from the embedded Lua registry used by the
// terminal. A missing registration would make the power unreachable even
// if its policy unit test passed.
func assertSifAbilityMenu(t *testing.T, g *Game) {
	t.Helper()

	result, err := g.PresentationPolicy("presentation.abilities",
		map[string]any{
			"height": 24,
		})

	if err != nil {
		t.Fatal(err)
	}

	options, ok := result["options"].([]any)

	if !ok {
		t.Fatalf("ability menu options: %T", result["options"])
	}

	wanted := map[string]bool{
		"ABIL_SIF_MUNA_CHANNEL_ENERGY":  false,
		"ABIL_SIF_MUNA_FORGET_SPELL":    false,
		"ABIL_SIF_MUNA_DIVINE_EXEGESIS": false,
	}

	for _, value := range options {
		option, ok := value.(map[string]any)

		if !ok {
			t.Fatalf("ability menu option: %T", value)
		}

		id, ok := option["id"].(string)

		if !ok {
			t.Fatalf("ability menu id: %T", option["id"])
		}

		if _, needed := wanted[id]; needed {
			wanted[id] = true
		}
	}

	for id, seen := range wanted {
		if !seen {
			t.Fatalf("Sif Muna menu omitted %s", id)
		}
	}
}

// Channel Magic restores the real MP pool and persists its timer, while
// Forget Spell clears a known slot without erasing library knowledge.
func TestSifChannelAndForgetSpell(t *testing.T) {
	g, err := NewDungeonGame(3061, "SP_HUMAN", "JOB_CONJURER",
		"", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	for _, monster := range g.stores.MonsterEnergy.Entities() {
		position, found := g.stores.Positions.Get(monster)

		if !found {
			continue
		}

		if err := g.levels[position.LevelID].RemoveActor(monster); err != nil {
			t.Fatal(err)
		}

		for _, item := range g.stores.CarriedBy.Entities() {
			carrier, found := g.stores.CarriedBy.Get(item)

			if found && carrier.Holder == monster {
				g.world.DestroyEntity(item)
			}
		}

		g.world.DestroyEntity(monster)
	}

	_, err = g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_SIF_MUNA",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	assertSifAbilityMenu(t, g)
	spell := g.scripts.Components()["character.spell"]

	magic, found := g.stores.Magic.Get(g.player)

	if !found {
		t.Fatal("player has no MP")
	}

	magic.Current = 0

	if _, err := g.stores.Magic.Set(g.player, *magic); err != nil {
		t.Fatal(err)
	}

	channel := g.scripts.Components()["religion.sif_channel"]

	for attempt := 0; attempt < 20 &&
		!channel.Has(g.player); attempt++ {
		result, err := g.Step(Command{
			Kind:      CommandAbility,
			AbilityID: "ABIL_SIF_MUNA_CHANNEL_ENERGY",
		})

		if err != nil {
			t.Fatal(err)
		}

		if result.Spent != 10 {
			t.Fatalf("Channel Magic spent %d aut: %v", result.Spent, err)
		}
	}

	if !channel.Has(g.player) {
		t.Fatal("Channel Magic did not create a saved timer")
	}

	magic, _ = g.stores.Magic.Get(g.player)

	if magic.Current < 3 {
		t.Fatalf("Channel Magic restored only %d/%d MP",
			magic.Current, magic.Max)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !restored.scripts.Components()["religion.sif_channel"].Has(
		restored.player) {
		t.Fatal("restored run lost Channel Magic timer")
	}

	spell = restored.scripts.Components()["character.spell"]

	for _, entity := range spell.Entities() {
		value, found := spell.Get(entity)

		if !found {
			t.Fatal("spell disappeared from ECS store")
		}

		id, err := value.Get("spell_id")

		if err != nil {
			t.Fatal(err)
		}

		if id != "SPELL_MAGIC_DART" {
			continue
		}

		if err := value.Set("in_library", true); err != nil {
			t.Fatal(err)
		}
	}

	command := Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_SIF_MUNA_FORGET_SPELL",
	}

	choice, err := restored.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if choice.Spent != 0 ||
		choice.Selection == nil {
		t.Fatalf("Forget Spell selection: %+v, %v", choice, err)
	}

	command.SpellID = "SPELL_MAGIC_DART"

	confirmation, err := restored.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if confirmation.Spent != 0 ||
		confirmation.Confirmation == "" {
		t.Fatalf("Forget Spell confirmation: %+v, %v",
			confirmation, err)
	}

	command.Forced = true

	committed, err := restored.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if committed.Spent != 10 {
		t.Fatalf("Forget Spell action: %+v, %v", committed, err)
	}

	for _, entity := range spell.Entities() {
		value, found := spell.Get(entity)

		if !found {
			t.Fatal("spell disappeared from ECS store")
		}

		id, _ := value.Get("spell_id")

		if id != "SPELL_MAGIC_DART" {
			continue
		}

		known, _ := value.Get("known_slot")
		library, _ := value.Get("in_library")

		if known != int64(0) || library != true {
			t.Fatalf("forgotten spell: known %v, library %v",
				known, library)
		}
	}
}

// Exegesis casts a library-only spell through the ordinary Lua effect. The
// chosen spell must pay its MP while its known slot remains empty.
func TestSifDivineExegesisCastsLibrarySpell(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if err := g.levels[1].RemoveActor(rat); err != nil {
		t.Fatal(err)
	}

	g.world.DestroyEntity(rat)

	_, err := g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_SIF_MUNA",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	grantTestSpell(t, g, "SPELL_SWIFTNESS")
	spell := g.scripts.Components()["character.spell"]

	for _, entity := range spell.Entities() {
		value, found := spell.Get(entity)

		if !found {
			t.Fatal("spell disappeared from ECS store")
		}

		id, _ := value.Get("spell_id")

		if id != "SPELL_SWIFTNESS" {
			continue
		}

		if err := value.Set("known_slot", int64(0)); err != nil {
			t.Fatal(err)
		}

		if err := value.Set("letter_slot", int64(0)); err != nil {
			t.Fatal(err)
		}

		if err := value.Set("in_library", true); err != nil {
			t.Fatal(err)
		}
	}

	command := Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_SIF_MUNA_DIVINE_EXEGESIS",
	}

	choice, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if choice.Spent != 0 ||
		choice.Selection == nil {
		t.Fatalf("Exegesis selection: %+v, %v", choice, err)
	}

	command.SpellID = "SPELL_SWIFTNESS"

	for attempt := 0; attempt < 20; attempt++ {
		result, err := g.Step(command)

		if err != nil {
			t.Fatal(err)
		}

		if result.Spent != 10 {
			t.Fatalf("Exegesis action: %+v, %v", result, err)
		}

		if g.scripts.Components()["magic.player_status"].Has(
			g.player) {
			break
		}
	}

	if !g.scripts.Components()["magic.player_status"].Has(
		g.player) {
		t.Fatal("Exegesis never cast the library spell")
	}

	status, _ := g.scripts.Components()["magic.player_status"].Get(g.player)
	swift, err := status.Get("swift_aut")

	if err != nil {
		t.Fatal(err)
	}

	if swift.(int64) <= 0 {
		t.Fatalf("Exegesis did not apply Swiftness: %v, %v", swift, err)
	}

	for _, entity := range spell.Entities() {
		value, found := spell.Get(entity)

		if !found {
			t.Fatal("spell disappeared from ECS store")
		}

		id, _ := value.Get("spell_id")

		if id != "SPELL_SWIFTNESS" {
			continue
		}

		known, _ := value.Get("known_slot")

		if known != int64(0) {
			t.Fatalf("Exegesis memorized its borrowed spell: %v", known)
		}
	}
}

// Spell choice and aiming are separate free questions. The second replay
// keeps the chosen spell ID, then the aimed command spends one action.
func TestSifDivineExegesisTargetsLibrarySpell(t *testing.T) {
	g := newStepGame(t)

	_, err := g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_SIF_MUNA",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	grantTestSpell(t, g, "SPELL_MAGIC_DART")
	spells := g.scripts.Components()["character.spell"]

	for _, entity := range spells.Entities() {
		value, _ := spells.Get(entity)
		id, _ := value.Get("spell_id")

		if id == "SPELL_MAGIC_DART" {
			if err := value.Set("known_slot", int64(0)); err != nil {
				t.Fatal(err)
			}

			if err := value.Set("in_library", true); err != nil {
				t.Fatal(err)
			}
		}
	}

	command := Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_SIF_MUNA_DIVINE_EXEGESIS",
	}

	first, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if first.Selection == nil ||
		first.Selection.Kind != "spell" || first.Spent != 0 {
		t.Fatalf("spell choice: %+v, %v", first, err)
	}

	command.SpellID = "SPELL_MAGIC_DART"

	second, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if second.Selection == nil ||
		second.Selection.Kind != "cell" || second.Spent != 0 {
		t.Fatalf("target choice: %+v, %v", second, err)
	}

	command.DX = 1

	third, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if third.Spent != 10 {
		t.Fatalf("aimed Exegesis: %+v, %v", third, err)
	}
}
