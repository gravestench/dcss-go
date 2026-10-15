package game

import (
	"testing"

	"dcrawl-go/internal/ecs"
)

func cloudDamageWithMutation(t *testing.T, kindID, mutationID string) int {
	t.Helper()

	g := newZapGame(t)
	position, _ := g.stores.Positions.Get(g.player)
	health, _ := g.stores.Health.Get(g.player)

	health.Current = 100
	health.Max = 100

	if mutationID != "" {
		entity, err := g.world.CreateEntity()

		if err != nil {
			t.Fatal(err)
		}

		store := g.scripts.Components()["character.mutation"]

		if _, err := store.Set(entity, map[string]any{
			"owner":       g.player,
			"mutation_id": mutationID,
			"acquired":    int64(1),
		}); err != nil {
			t.Fatal(err)
		}
	}

	cloud, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["magic.cloud"].Set(cloud, map[string]any{
		"kind_id":     kindID,
		"owner":       g.player,
		"level_id":    int64(position.LevelID),
		"x":           int64(position.X),
		"y":           int64(position.Y),
		"expires_aut": int64(1000),
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.runAction(g.player, ecs.Intent{
		Kind: ecs.IntentWait,
	}, 10, "player"); err != nil {
		t.Fatal(err)
	}

	return health.Current
}

func TestCloudImmunityMutationsPreventPlayerDamage(t *testing.T) {
	for _, vector := range []struct {
		cloud    string
		mutation string
	}{
		{
			cloud:    "CLOUD_FIRE",
			mutation: "MUT_FLAME_CLOUD_IMMUNITY",
		},

		{
			cloud:    "CLOUD_COLD",
			mutation: "MUT_FREEZING_CLOUD_IMMUNITY",
		},
	} {
		t.Run(vector.cloud, func(t *testing.T) {
			if got := cloudDamageWithMutation(t, vector.cloud, ""); got >= 100 {
				t.Fatalf("%s did not harm an unprotected player: HP %d",
					vector.cloud, got)
			}

			if got := cloudDamageWithMutation(t, vector.cloud, vector.mutation); got != 100 {
				t.Fatalf("%s hurt its immune player: HP %d", vector.cloud, got)
			}
		})
	}
}
