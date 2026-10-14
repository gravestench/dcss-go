package game

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/save"
)

func TestPlayerRatKillAwardsOneExperienceOnlyOnce(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}
	current, _ := g.stores.Health.Get(rat)
	current.Current = 1
	playerHealth, _ := g.stores.Health.Get(g.player)
	playerHealth.Current, playerHealth.Max = 100, 100
	for attempt := 0; attempt < 100 && g.world.EntityExists(rat); attempt++ {
		if _, err := g.Step(Command{Kind: CommandMove, DX: 1}); err != nil {
			t.Fatal(err)
		}
	}
	if g.world.EntityExists(rat) {
		t.Fatal("rat survived 100 attacks")
	}
	progress, found := g.stores.Progression.Get(g.player)
	if !found || progress.TotalXP != 1 || g.View().ExperienceLevel != 1 || g.View().NextLevelPercent != 11 {
		t.Fatalf("rat kill progression %+v found %v view %+v", progress, found, g.View())
	}
	if _, err := g.Step(Command{Kind: CommandWait}); err != nil || progress.TotalXP != 1 {
		t.Fatalf("rat kill credited twice: XP %+v, err %v", progress, err)
	}
}

func TestPreDeadRatCleanupDoesNotAwardExperience(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)
	health.Current = 0
	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}
	progress, _ := g.stores.Progression.Get(g.player)
	if progress.TotalXP != 0 {
		t.Fatalf("pre-dead rat awarded %d XP", progress.TotalXP)
	}
}

func TestExperienceSaveRoundTripAndOlderFieldDefault(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	if err := g.levels[1].RemoveActor(rat); err != nil {
		t.Fatal(err)
	}
	if !g.world.DestroyEntity(rat) {
		t.Fatal("could not build killed-rat save fixture")
	}
	progress, _ := g.stores.Progression.Get(g.player)
	progress.TotalXP = 1
	loaded, err := Restore(g.Snapshot(), testCatalog(t))
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatal("XP snapshot changed on restore")
	}
	loaded.Close()
	old := g.Snapshot()
	for i := range old.Entities {
		if old.Entities[i].ID == old.PlayerID {
			old.Entities[i].Progression = nil
		}
	}
	loaded, err = Restore(old, testCatalog(t))
	if err != nil {
		t.Fatal(err)
	}
	defer loaded.Close()
	oldProgress, found := loaded.stores.Progression.Get(loaded.player)
	if !found || oldProgress.TotalXP != 0 {
		t.Fatalf("old version-%d save progressed %+v", save.Version, oldProgress)
	}
}

func TestRestoreRejectsClaimedRatXPWhileRatAlive(t *testing.T) {
	g := newStepGame(t)
	before := g.Snapshot()
	bad := g.Snapshot()
	for i := range bad.Entities {
		if bad.Entities[i].ID == bad.PlayerID {
			bad.Entities[i].Progression.TotalXP = 1
		}
	}
	if loaded, err := Restore(bad, testCatalog(t)); err == nil {
		loaded.Close()
		t.Fatal("restored XP already awarded for a living rat")
	}
	if !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatal("failed restore changed the live game")
	}
}

func TestExperienceRestoreRejectsMalformedProgression(t *testing.T) {
	g := newStepGame(t)
	for _, xp := range []int{-1, 2, 9} {
		bad := g.Snapshot()
		for i := range bad.Entities {
			if bad.Entities[i].ID == bad.PlayerID {
				bad.Entities[i].Progression.TotalXP = xp
			}
		}
		if restored, err := Restore(bad, testCatalog(t)); err == nil {
			restored.Close()
			t.Fatalf("restored impossible fixed-scenario XP %d", xp)
		}
	}
}
