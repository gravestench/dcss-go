package game

import (
	"reflect"
	"strconv"
	"strings"
	"testing"

	"dcrawl-go/internal/terrain"
)

func TestFogAndPoisonScrollsPlaceSavedClouds(t *testing.T) {
	for _, kind := range []string{"SCR_FOG", "SCR_POISON"} {
		t.Run(kind, func(t *testing.T) {
			g := newStepGame(t)
			scroll := addIdentificationTestItem(t, g, kind, true)
			result, err := g.Step(Command{
				Kind:   CommandRead,
				ItemID: uint64(scroll),
			})

			if err != nil {
				t.Fatal(err)
			}

			clouds := g.scripts.Components()["world.cloud"].Entities()

			if result.Spent != 10 || len(clouds) == 0 {
				t.Fatalf("%s placed %d clouds, spent %d aut",
					kind, len(clouds), result.Spent)
			}

			if len(g.View().Clouds) == 0 {
				t.Fatalf("%s clouds are absent from the map view", kind)
			}

			restored, err := Restore(g.Snapshot())

			if err != nil {
				t.Fatal(err)
			}

			if got := len(restored.scripts.Components()["world.cloud"].Entities()); got != len(clouds) {
				t.Fatalf("restored %d clouds; want %d", got, len(clouds))
			}
		})
	}
}

func TestSummoningScrollsCreateOwnedSavedAllies(t *testing.T) {
	for _, kind := range []string{"SCR_SUMMONING", "SCR_BUTTERFLIES"} {
		t.Run(kind, func(t *testing.T) {
			g := newStepGame(t)
			movePlayerToOpenSummoningRoom(t, g)
			scroll := addIdentificationTestItem(t, g, kind, true)
			result, err := g.Step(Command{
				Kind:   CommandRead,
				ItemID: uint64(scroll),
			})

			if err != nil {
				t.Fatal(err)
			}

			store := g.scripts.Components()["magic.summon"]
			summoned := store.Entities()

			if result.Spent != 10 || len(summoned) == 0 {
				t.Fatalf("%s created %d allies, spent %d aut",
					kind, len(summoned), result.Spent)
			}

			for _, entity := range summoned {
				state, _ := store.Get(entity)
				owner, _ := state.Get("owner")
				source, _ := state.Get("source_id")
				hostile, _ := state.Get("hostile")

				if owner != g.player ||
					source != kind ||
					hostile != false {
					t.Fatalf("%s summon state: owner=%v source=%v hostile=%v",
						kind, owner, source, hostile)
				}
			}

			restored, err := Restore(g.Snapshot())

			if err != nil {
				t.Fatal(err)
			}

			if got := len(restored.scripts.Components()["magic.summon"].Entities()); got != len(summoned) {
				t.Fatalf("restored %d summons; want %d", got, len(summoned))
			}
		})
	}
}

func TestAcquirementKeepsOffersOnCancelAndGrantsSelectedItem(t *testing.T) {
	g := newStepGame(t)
	scroll := addIdentificationTestItem(t, g, "SCR_ACQUIREMENT", true)
	first, err := g.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(scroll),
	})

	if err != nil {
		t.Fatal(err)
	}

	if first.Spent != 0 ||
		first.Selection == nil ||
		first.Selection.Kind != "offer" ||
		len(first.Selection.Options) != 4 {
		t.Fatalf("acquirement offers: %+v", first)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	cancelled, err := restored.Step(Command{
		Kind:      CommandRead,
		ItemID:    uint64(scroll),
		Cancelled: true,
	})

	if err != nil {
		t.Fatal(err)
	}

	if cancelled.Spent != 0 {
		t.Fatalf("acquirement cancellation spent %d aut", cancelled.Spent)
	}

	second, err := restored.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(scroll),
	})

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(first.Selection, second.Selection) {
		t.Fatalf("acquirement offers changed: %+v, %+v",
			first.Selection, second.Selection)
	}

	gold := ""

	for _, option := range second.Selection.Options {
		if strings.Contains(option.Label, "gold") {
			gold = option.ID
		}
	}

	if gold == "" {
		t.Fatal("acquirement omitted its guaranteed gold offer")
	}

	chosen, err := restored.Step(Command{
		Kind:     CommandRead,
		ItemID:   uint64(scroll),
		TargetID: gold,
	})

	if err != nil {
		t.Fatal(err)
	}

	if chosen.Spent != 10 {
		t.Fatalf("acquirement spent %d aut", chosen.Spent)
	}

	found := false
	position, _ := restored.stores.Positions.Get(restored.player)

	for _, entity := range restored.stores.Items.Entities() {
		item, _ := restored.stores.Items.Get(entity)
		floor, onFloor := restored.stores.Positions.Get(entity)

		if item.KindID == "OBJ_GOLD" &&
			onFloor &&
			floor.LevelID == position.LevelID &&
			floor.X == position.X &&
			floor.Y == position.Y {
			found = item.Quantity >= 200 && item.Quantity <= 1400
		}
	}

	if !found {
		t.Fatal("selected acquirement gold did not appear at player's feet")
	}
}

func TestMagicMappingScrollRevealsAndRestoresMapKnowledge(t *testing.T) {
	g := newStepGame(t)
	scroll := addIdentificationTestItem(t, g, "SCR_MAGIC_MAPPING", true)
	before := countMappedCells(g.levels[1].KnownCells())

	result, err := g.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(scroll),
	})

	if err != nil {
		t.Fatal(err)
	}

	after := countMappedCells(g.levels[1].KnownCells())

	if result.Spent != 10 || after <= before {
		t.Fatalf("mapping spent %d aut and revealed %d cells from %d",
			result.Spent, after, before)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	if got := countMappedCells(restored.levels[1].KnownCells()); got != after {
		t.Fatalf("restored map has %d cells; want %d", got, after)
	}
}

func countMappedCells(cells [][]terrain.ID) int {
	count := 0

	for _, row := range cells {
		for _, feature := range row {
			if feature != terrain.Unseen {
				count++
			}
		}
	}

	return count
}

func TestFearScrollFrightensVisibleRat(t *testing.T) {
	g := newZapGame(t)
	scroll := addIdentificationTestItem(t, g, "SCR_FEAR", true)
	rat := ratID(t, g)
	result, err := g.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(scroll),
	})

	if err != nil {
		t.Fatal(err)
	}

	state, found := g.scripts.Components()["magic.monster_mass_enchant"].Get(rat)

	if result.Spent != 10 || !found {
		t.Fatalf("fear spent %d aut, effect present %v",
			result.Spent, found)
	}

	remaining, err := state.Get("fear_aut")

	if err != nil {
		t.Fatal(err)
	}

	if remaining.(int64) <= 0 {
		t.Fatalf("fear duration %v: %v", remaining, err)
	}
}

func TestReadIdentifyRequestsOneFreeItemSelection(t *testing.T) {
	g := newStepGame(t)
	scroll := addIdentificationTestItem(t, g, "SCR_IDENTIFY", true)
	potion := addIdentificationTestItem(t, g, "POT_CURING", true)
	before := g.Snapshot()

	result, err := g.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(scroll),
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 ||
		result.Selection == nil ||
		result.Selection.Kind != "item" {
		t.Fatalf("read selection: spent %d, selection %+v, events %+v",
			result.Spent, result.Selection, result.Events)
	}

	foundPotion := false
	wantedID := strconv.FormatUint(uint64(potion), 10)

	for _, option := range result.Selection.Options {
		if option.ID == wantedID {
			foundPotion = true
		}
	}

	if !foundPotion {
		t.Fatalf("unknown potion missing from identify choices: %+v",
			result.Selection)
	}

	if after := g.Snapshot(); after.CurrentAut != before.CurrentAut {
		t.Fatal("selecting an item spent a turn")
	}
}

func TestReadIdentifyDiscoversItemAndKnownCancelIsFree(t *testing.T) {
	g := newStepGame(t)
	scroll := addIdentificationTestItem(t, g, "SCR_IDENTIFY", true)
	spare := addIdentificationTestItem(t, g, "SCR_IDENTIFY", true)
	potion := addIdentificationTestItem(t, g, "POT_CURING", true)
	choice := strconv.FormatUint(uint64(potion), 10)

	result, err := g.Step(Command{
		Kind:     CommandRead,
		ItemID:   uint64(scroll),
		TargetID: choice,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 ||
		itemNameInInventory(t, g, potion) != "potion of curing" {
		t.Fatalf("identify result: spent %d, name %q",
			result.Spent, itemNameInInventory(t, g, potion))
	}

	before := g.Snapshot()
	result, err = g.Step(Command{
		Kind:      CommandRead,
		ItemID:    uint64(spare),
		Cancelled: true,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 || g.Snapshot().CurrentAut != before.CurrentAut {
		t.Fatalf("known scroll cancellation spent %d aut", result.Spent)
	}

	if itemNameInInventory(t, g, spare) != "scroll of identify" {
		t.Fatal("known scroll disappeared on cancellation")
	}
}

func TestUnknownIdentifyCancellationConsumesScroll(t *testing.T) {
	g := newStepGame(t)
	scroll := addIdentificationTestItem(t, g, "SCR_IDENTIFY", true)
	before := g.Snapshot()

	result, err := g.Step(Command{
		Kind:      CommandRead,
		ItemID:    uint64(scroll),
		Cancelled: true,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 ||
		g.Snapshot().CurrentAut != before.CurrentAut+10 {
		t.Fatalf("unknown cancellation spent %d aut", result.Spent)
	}

	if _, exists := g.stores.Items.Get(scroll); exists {
		t.Fatal("unknown cancelled scroll was not consumed")
	}
}

func TestReadIdentifyCanSelectFloorItem(t *testing.T) {
	g := newStepGame(t)
	scroll := addIdentificationTestItem(t, g, "SCR_IDENTIFY", true)
	potion := addIdentificationTestItem(t, g, "POT_CURING", false)
	wanted := strconv.FormatUint(uint64(potion), 10)

	result, err := g.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(scroll),
	})

	if err != nil {
		t.Fatal(err)
	}

	for _, option := range result.Selection.Options {
		if option.ID == wanted {
			return
		}
	}

	t.Fatal("identify selection omitted floor item at player's feet")
}

func TestEnchantScrollsRespectSourceCaps(t *testing.T) {
	cases := []struct {
		name       string
		scrollKind string
		itemKind   string
		startPlus  int
		wantPlus   int
	}{
		{
			name:       "weapon reaches plus nine",
			scrollKind: "SCR_ENCHANT_WEAPON",
			itemKind:   "WPN_RAPIER",
			startPlus:  8,
			wantPlus:   9,
		},

		{
			name:       "body armour reaches AC cap",
			scrollKind: "SCR_ENCHANT_ARMOUR",
			itemKind:   "ARM_RING_MAIL",
			startPlus:  4,
			wantPlus:   5,
		},
	}

	for _, test := range cases {
		t.Run(test.name, func(t *testing.T) {
			g := newStepGame(t)
			scroll := addIdentificationTestItem(t, g, test.scrollKind, true)
			target := addIdentificationTestItem(t, g, test.itemKind, true)
			item, _ := g.stores.Items.Get(target)

			item.Plus = test.startPlus
			g.stores.Items.Set(target, *item)

			result, err := g.Step(Command{
				Kind:     CommandRead,
				ItemID:   uint64(scroll),
				TargetID: strconv.FormatUint(uint64(target), 10),
			})

			if err != nil {
				t.Fatal(err)
			}

			updated, _ := g.stores.Items.Get(target)

			if result.Spent != 10 || updated.Plus != test.wantPlus {
				t.Fatalf("enchant spent %d aut, plus %d; want %d",
					result.Spent, updated.Plus, test.wantPlus)
			}
		})
	}
}

func TestBrandWeaponChangesEgoAndSurvivesRestore(t *testing.T) {
	g := newStepGame(t)
	scroll := addIdentificationTestItem(t, g, "SCR_BRAND_WEAPON", true)
	target := addIdentificationTestItem(t, g, "WPN_RAPIER", true)

	result, err := g.Step(Command{
		Kind:     CommandRead,
		ItemID:   uint64(scroll),
		TargetID: strconv.FormatUint(uint64(target), 10),
	})

	if err != nil {
		t.Fatal(err)
	}

	item, _ := g.stores.Items.Get(target)

	if result.Spent != 10 || item.Ego == "" {
		t.Fatalf("branding spent %d aut, ego %q", result.Spent, item.Ego)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	restoredItem, _ := restored.stores.Items.Get(target)

	if restoredItem.Ego != item.Ego {
		t.Fatalf("restored brand %q; want %q", restoredItem.Ego, item.Ego)
	}
}

func TestReadNoiseConsumesScrollAndRevealsType(t *testing.T) {
	g := newStepGame(t)
	scroll := addIdentificationTestItem(t, g, "SCR_NOISE", true)
	spare := addIdentificationTestItem(t, g, "SCR_NOISE", true)

	result, err := g.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(scroll),
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 ||
		itemNameInInventory(t, g, spare) != "scroll of noise" {
		t.Fatalf("noise spent %d aut, spare %q",
			result.Spent, itemNameInInventory(t, g, spare))
	}

	if _, exists := g.stores.Items.Get(scroll); exists {
		t.Fatal("read noise scroll remained in inventory")
	}

	found := false

	for _, event := range result.Events {
		if event.Text == "You hear a loud clanging noise!" {
			found = true
		}
	}

	if !found {
		t.Fatal("noise scroll did not emit its audible event")
	}
}

func TestReadSilencePreventsAnotherScroll(t *testing.T) {
	g := newStepGame(t)
	silence := addIdentificationTestItem(t, g, "SCR_SILENCE", true)
	noise := addIdentificationTestItem(t, g, "SCR_NOISE", true)

	first, err := g.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(silence),
	})

	if err != nil {
		t.Fatal(err)
	}

	second, err := g.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(noise),
	})

	if err != nil {
		t.Fatal(err)
	}

	if first.Spent != 10 || second.Spent != 0 {
		t.Fatalf("silence and blocked read spent %d and %d aut",
			first.Spent, second.Spent)
	}

	if _, exists := g.stores.Items.Get(noise); !exists {
		t.Fatal("silence consumed the blocked noise scroll")
	}
}

func TestImmolationScrollMarksVisibleMonster(t *testing.T) {
	g := newZapGame(t)
	scroll := addIdentificationTestItem(t, g, "SCR_IMMOLATION", true)
	rat := ratID(t, g)

	result, err := g.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(scroll),
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 ||
		!g.scripts.Components()["zap.inner_flame"].Has(rat) {
		t.Fatal("immolation did not mark the visible rat")
	}
}

func TestAmnesiaScrollForgetsSelectedSpell(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_MAGIC_DART")
	scroll := addIdentificationTestItem(t, g, "SCR_AMNESIA", true)

	selection, err := g.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(scroll),
	})

	if err != nil {
		t.Fatal(err)
	}

	if selection.Spent != 0 ||
		selection.Selection == nil ||
		selection.Selection.Kind != "spell" {
		t.Fatal("amnesia did not request a free spell selection")
	}

	result, err := g.Step(Command{
		Kind:     CommandRead,
		ItemID:   uint64(scroll),
		TargetID: "SPELL_MAGIC_DART",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 {
		t.Fatalf("amnesia spent %d aut", result.Spent)
	}

	for _, spell := range g.View().Spells {
		if spell.ID == "SPELL_MAGIC_DART" && spell.KnownSlot > 0 {
			t.Fatal("amnesia left Magic Dart memorised")
		}
	}
}

func TestTormentScrollHurtsReaderAndVisibleMonster(t *testing.T) {
	g := newZapGame(t)
	scroll := addIdentificationTestItem(t, g, "SCR_TORMENT", true)
	rat := ratID(t, g)
	playerHealth, _ := g.stores.Health.Get(g.player)
	ratHealth, _ := g.stores.Health.Get(rat)

	playerHealth.Current = 100
	playerHealth.Max = 100
	ratHealth.Current = 100
	ratHealth.Max = 100
	g.stores.Health.Set(g.player, *playerHealth)
	g.stores.Health.Set(rat, *ratHealth)

	result, err := g.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(scroll),
	})

	if err != nil {
		t.Fatal(err)
	}

	afterPlayer, _ := g.stores.Health.Get(g.player)
	afterRat, _ := g.stores.Health.Get(rat)

	if result.Spent != 10 ||
		afterPlayer.Current >= 100 ||
		afterRat.Current >= 100 {
		t.Fatalf("torment spent %d aut; player %d HP, rat %d HP",
			result.Spent, afterPlayer.Current, afterRat.Current)
	}
}

func TestVulnerabilityScrollLowersWillAcrossSave(t *testing.T) {
	g := newZapGame(t)
	scroll := addIdentificationTestItem(t, g, "SCR_VULNERABILITY", true)
	rat := ratID(t, g)

	result, err := g.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(scroll),
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 {
		t.Fatalf("vulnerability spent %d aut", result.Spent)
	}

	status, present := g.scripts.Components()["magic.player_status"].Get(g.player)

	if !present {
		t.Fatal("vulnerability did not create player status")
	}

	remaining, _ := status.Get("lowered_will_aut")

	if remaining.(int64) <= 0 ||
		!g.scripts.Components()["magic.monster_lowered_will"].Has(rat) {
		t.Fatal("vulnerability did not lower both player and monster will")
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !restored.scripts.Components()["magic.monster_lowered_will"].Has(rat) {
		t.Fatal("monster vulnerability did not survive restore")
	}
}

func TestBlinkScrollMovesToSelectedVisibleCell(t *testing.T) {
	g := newStepGame(t)
	scroll := addIdentificationTestItem(t, g, "SCR_BLINKING", true)
	before := g.View()

	request, err := g.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(scroll),
	})

	if err != nil {
		t.Fatal(err)
	}

	if request.Spent != 0 ||
		request.Selection == nil ||
		request.Selection.Kind != "cell" {
		t.Fatal("blinking did not request a free map cell")
	}

	for y := 0; y < before.Height; y++ {
		for x := 0; x < before.Width; x++ {
			dx := x - before.PlayerX
			dy := y - before.PlayerY

			if dx == 0 && dy == 0 {
				continue
			}

			if before.Cells[y*before.Width+x].State != Visible ||
				!g.levels[before.LevelID].Walkable(x, y) {
				continue
			}

			occupied := false

			for _, entity := range before.Entities {
				if entity.Role == "monster" &&
					entity.X == x &&
					entity.Y == y {
					occupied = true
				}
			}

			if occupied {
				continue
			}

			result, err := g.Step(Command{
				Kind:   CommandRead,
				ItemID: uint64(scroll),
				DX:     dx,
				DY:     dy,
			})

			if err != nil {
				t.Fatal(err)
			}

			if result.Spent != 10 ||
				result.View.PlayerX != x || result.View.PlayerY != y {
				t.Fatalf("blink spent %d aut, landed at %d,%d; want %d,%d",
					result.Spent, result.View.PlayerX, result.View.PlayerY,
					x, y)
			}

			return
		}
	}

	t.Fatal("test level has no visible open blink destination")
}

func TestTeleportScrollDelaySurvivesRestore(t *testing.T) {
	g := newStepGame(t)
	quietMonsters(g)
	scroll := addIdentificationTestItem(t, g, "SCR_TELEPORTATION", true)

	result, err := g.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(scroll),
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 ||
		!g.scripts.Components()["magic.player_teleport"].Has(g.player) {
		t.Fatal("teleport scroll did not start a saved delay")
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	quietMonsters(restored)

	for turn := 0; turn < 6; turn++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}

		if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if g.scripts.Components()["magic.player_teleport"].Has(g.player) ||
		restored.scripts.Components()["magic.player_teleport"].Has(
			restored.player) {
		t.Fatal("teleport delay did not expire")
	}

	first := g.View()
	second := restored.View()

	if first.PlayerX != second.PlayerX || first.PlayerY != second.PlayerY {
		t.Fatalf("teleport changed across restore: %d,%d vs %d,%d",
			first.PlayerX, first.PlayerY, second.PlayerX, second.PlayerY)
	}
}
