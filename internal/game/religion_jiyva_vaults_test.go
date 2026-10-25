package game

import (
	"reflect"
	"slices"
	"testing"

	"crawl/internal/terrain"
	"crawl/internal/vault"
)

const structuralTravelHP = 10000

// A structural branch test protects its player from incidental monsters.
// Level advancement can replace the boosted cap during travel; retain that
// new derived cap instead of resetting it to an obsolete starting value.
func restoreStructuralTravelHealth(g *Game, previousMax int) {
	health, _ := g.stores.Health.Get(g.player)

	if health.Max == structuralTravelHP {
		health.Max = previousMax
	}

	health.Current = health.Max
}

// An allied kill can earn enough XP for a stat choice during the monster
// phase. Complete the same free prompt a player would see before testing
// another action on the restored floor.
func chooseStructuralTravelStats(t *testing.T, g *Game) {
	t.Helper()

	for choice := 0; choice < 27; choice++ {
		progress, found := g.stores.Progression.Get(g.player)

		if !found {
			t.Fatal("structural travel player has no progression")
		}

		if progress.PendingStatLevel == 0 {
			return
		}

		if _, err := g.ChooseStat("dex"); err != nil {
			t.Fatal(err)
		}
	}

	t.Fatal("structural travel never cleared stat choices")
}

// A sixth-star reward earned before Slime:5 must open the authored walls
// on first entry. The saved worship bit survives the branch journey and
// restore without rerunning the C++ vault script.
func TestJiyvaRewardOpensSlimePitOnEntryAfterRestore(t *testing.T) {
	g := newGeneratedTestGame(t, 423)
	lairParent := 0
	slimeParent := 0

	for _, entry := range g.branchSchedule.Entries {
		if entry.BranchID == "BRANCH_LAIR" {
			lairParent = entry.ParentDepth
		}

		if entry.BranchID == "BRANCH_SLIME" {
			slimeParent = entry.ParentDepth
		}
	}

	if lairParent == 0 || slimeParent == 0 {
		t.Fatal("generated run has no scheduled Slime route")
	}

	descendGeneratedTo(t, g, lairParent)

	health, _ := g.stores.Health.Get(g.player)
	firstMax := health.Max

	health.Max = structuralTravelHP
	health.Current = health.Max

	lair := followBranch(t, g, g.levels[lairParent], "BRANCH_LAIR")
	lair = descendBranch(t, g, lair, slimeParent)
	slime := followBranch(t, g, lair, "BRANCH_SLIME")
	parent := descendBranch(t, g, slime, 4)

	worship, found := g.scripts.Components()["religion.worship"].Get(g.player)

	if !found {
		t.Fatal("player has no worship state")
	}

	if err := worship.Set("god_id", "GOD_JIYVA"); err != nil {
		t.Fatal(err)
	}

	if err := worship.Set("piety", int64(160)); err != nil {
		t.Fatal(err)
	}

	if err := worship.Set("one_time_abilities", map[string]any{
		"GOD_JIYVA": true,
	}); err != nil {
		t.Fatal(err)
	}

	restoreStructuralTravelHealth(g, firstMax)

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
	chooseStructuralTravelStats(t, loaded)

	loadedHealth, _ := loaded.stores.Health.Get(loaded.player)
	loadedMax := loadedHealth.Max

	loadedHealth.Max = structuralTravelHP
	loadedHealth.Current = loadedHealth.Max

	parent = loaded.levels[parent.ID]
	var departure StairLink

	for _, link := range parent.StairLinks() {
		if link.Pending && link.TargetBranchID == "" {
			if _, occupied := parent.ActorAt(link.X, link.Y); !occupied {
				departure = link
				break
			}
		}
	}

	if !departure.Pending {
		t.Fatal("Slime:4 has no free down stair")
	}

	if err := parent.MoveActor(loaded.player,
		departure.X, departure.Y); err != nil {
		t.Fatal(err)
	}

	result, err := loaded.Step(Command{Kind: CommandDownstairs})

	if err != nil {
		t.Fatal(err)
	}

	end := loaded.levels[departure.ToLevelID]

	if end == nil || result.View.LevelID != end.ID {
		t.Fatal("Jiyva's Slime descent did not reach its linked floor")
	}

	if end.VaultID() != "slime_pit" {
		t.Fatalf("Slime end map = %s", end.VaultID())
	}

	walls := 0

	for _, record := range end.VaultRecords() {
		if record.Kind == vault.KindMarker &&
			record.SourceID == "slime_pit" &&
			record.Identity == "slime_seal_wall" {
			walls++

			if end.Cells()[record.Y][record.X] != terrain.Floor {
				t.Fatalf("Jiyva left seal at (%d,%d)", record.X,
					record.Y)
			}
		}
	}

	if walls == 0 {
		t.Fatal("Slime end has no authored seal walls")
	}

	if !slices.Contains(loaded.messages,
		"You hear the sound of toppling stones.") {
		t.Fatal("Jiyva's Slime entry announcement is missing")
	}

	heard := false

	for _, event := range result.Events {
		if event.Text == "You hear the sound of toppling stones." {
			heard = true
			break
		}
	}

	if !heard {
		t.Fatal("stair result omitted Jiyva's Slime announcement")
	}

	restoreStructuralTravelHealth(loaded, loadedMax)

	before := loaded.Snapshot()
	restored, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(before, restored.Snapshot()) {
		t.Fatal("Jiyva-unsealed Slime floor changed across restore")
	}
	chooseStructuralTravelStats(t, restored)

	protected := 0

	for _, record := range restored.levels[end.ID].VaultRecords() {
		if record.Kind == vault.KindProperty &&
			record.SourceID == "slime_pit" &&
			record.Identity == "no_jiyva" {
			protected++
		}
	}

	if protected == 0 {
		t.Fatal("generated Slime:5 lost its source no-Jiyva cells")
	}

	clock, found := restored.scripts.Components()["religion.jiyva_ecology"].Get(restored.player)

	if !found {
		t.Fatal("Slime:5 run has no Jiyva ecology clock")
	}

	if err := clock.Set("next_due_aut", int64(restored.currentAut+10)); err != nil {
		t.Fatal(err)
	}

	// Incidental Slime combat during the structural descent may accumulate
	// penance. Exercise the reward and timer while this saved worshipper is
	// deliberately in good standing, as the scenario intends.
	worshipState, _ := restored.scripts.Components()["religion.worship"].Get(restored.player)

	if err := worshipState.Set("penance", map[string]any{}); err != nil {
		t.Fatal(err)
	}

	forceJiyvaSpawnRoll(t, restored)

	restoredHealth, _ := restored.stores.Health.Get(restored.player)
	restoredMax := restoredHealth.Max

	restoredHealth.Max = structuralTravelHP
	restoredHealth.Current = restoredHealth.Max

	if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}
	chooseStructuralTravelStats(t, restored)

	if len(restored.scripts.Components()["religion.jiyva_spawn"].Entities()) == 0 {
		t.Fatal("Jiyva timer created no jelly on unsealed Slime:5")
	}

	restoreStructuralTravelHealth(restored, restoredMax)

	spawnedSave, err := Restore(restored.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer spawnedSave.Close()
}
