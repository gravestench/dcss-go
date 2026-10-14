package game

import (
	"testing"

	"dcrawl-go/internal/character"
)

func TestSavedHumanAdvancementValidatesAppliedAndPendingLevels(t *testing.T) {
	g := newStepGame(t)
	profile, err := character.BuildStartProfile(
		g.catalog, "SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER",
	)
	if err != nil {
		t.Fatal(err)
	}
	snapshot := g.Snapshot()
	var playerIndex int
	for index, record := range snapshot.Entities {
		if record.ID == snapshot.PlayerID {
			playerIndex = index
			break
		}
	}
	player := snapshot.Entities[playerIndex]
	species, _ := g.catalog.Species("SP_HUMAN")
	player.Progression.TotalXP = 9
	player.Progression.Level = 2
	player.Health.Max, err = character.HumanMaxHP(2, species, player.Skills.Entries)
	if err != nil {
		t.Fatal(err)
	}
	player.Magic.Max = 2
	if got, err := validateSavedHumanAdvancement(player, profile, g.catalog); err != nil || got != 9 {
		t.Fatalf("valid XL2 save = %d XP, %v", got, err)
	}

	player.Progression.TotalXP = 29
	player.Progression.PendingStatLevel = 3
	if got, err := validateSavedHumanAdvancement(player, profile, g.catalog); err != nil || got != 29 {
		t.Fatalf("pending XL3 save = %d XP, %v", got, err)
	}
	player.Progression.PendingStatLevel = 0
	if _, err := validateSavedHumanAdvancement(player, profile, g.catalog); err == nil {
		t.Fatal("accepted XP past a missing stat choice")
	}
	player.Progression.Level = 3
	player.Attributes.Strength += 2
	player.Health.Max, err = character.HumanMaxHP(3, species, player.Skills.Entries)
	if err != nil {
		t.Fatal(err)
	}
	player.Magic.Max = 3
	if got, err := validateSavedHumanAdvancement(player, profile, g.catalog); err != nil || got != 29 {
		t.Fatalf("chosen XL3 save = %d XP, %v", got, err)
	}
	player.Attributes.Strength--
	player.Attributes.Intelligence++
	if _, err := validateSavedHumanAdvancement(player, profile, g.catalog); err == nil {
		t.Fatal("accepted a split manual stat choice")
	}
	player.Attributes.Strength++
	player.Attributes.Intelligence--
	player.Attributes.Strength++
	if _, err := validateSavedHumanAdvancement(player, profile, g.catalog); err == nil {
		t.Fatal("accepted unearned player attribute")
	}
}
