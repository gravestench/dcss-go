package monster

import (
	"testing"

	"dcrawl-go/internal/content"
)

func TestOrdinaryDaggerCanRollVenomAndEnchantment(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	roller := &gearRoller{
		rolls: []gearRoll{
			{
				bound: 200,
				value: 0,
			},

			{
				bound: 300,
				value: 0,
			},

			{
				bound: 100,
				value: 0,
			},

			{
				bound: 3,
				value: 2,
			},

			{
				bound: 425,
				value: 424,
			},
		},
	}

	quality, err := RollOrdinaryWeaponQuality(
		roller,
		catalog,
		"WPN_DAGGER",
		2,
	)

	if err != nil {
		t.Fatal(err)
	}

	if quality.Plus != 2 ||
		quality.Ego != "SPWPN_VENOM" ||
		len(roller.rolls) != 0 {
		t.Fatalf("dagger quality = %+v, remaining %+v", quality, roller.rolls)
	}
}

func TestOrdinaryUnbrandedLowEnchantmentIsSquashed(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	roller := &gearRoller{
		rolls: []gearRoll{
			{
				bound: 200,
				value: 0,
			},

			{
				bound: 300,
				value: 0,
			},

			{
				bound: 100,
				value: 28,
			},

			{
				bound: 3,
				value: 2,
			},

			{
				bound: 425,
				value: 424,
			},
		},
	}

	quality, err := RollOrdinaryWeaponQuality(
		roller,
		catalog,
		"WPN_DAGGER",
		1,
	)

	if err != nil {
		t.Fatal(err)
	}

	if quality != (WeaponQuality{}) || len(roller.rolls) != 0 {
		t.Fatalf("unsquashed dagger quality = %+v, remaining %+v", quality, roller.rolls)
	}
}

func TestMundaneClubConsumesQualityChanceButStaysPlain(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	roller := &gearRoller{
		rolls: []gearRoll{
			{
				bound: 200,
				value: 0,
			},
		},
	}

	quality, err := RollOrdinaryWeaponQuality(
		roller,
		catalog,
		"WPN_CLUB",
		1,
	)

	if err != nil {
		t.Fatal(err)
	}

	if quality != (WeaponQuality{}) || len(roller.rolls) != 0 {
		t.Fatalf("club quality = %+v, remaining %+v", quality, roller.rolls)
	}
}

func TestNiceWeaponPlussesAlternateIncrementAndStopDraws(t *testing.T) {
	roller := &gearRoller{
		rolls: []gearRoll{
			{
				bound: 3,
				value: 2,
			},

			{
				bound: 425,
				value: 0,
			},

			{
				bound: 3,
				value: 1,
			},

			{
				bound: 425,
				value: 424,
			},
		},
	}

	plus, err := RollNiceWeaponPlusses(roller, 2)

	if err != nil {
		t.Fatal(err)
	}

	if plus != 3 || len(roller.rolls) != 0 {
		t.Fatalf("weapon enchantment = %d, remaining %+v", plus, roller.rolls)
	}
}

func TestOrdinaryWeaponQualityRejectsUnsupportedKind(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := RollOrdinaryWeaponQuality(
		&gearRoller{},
		catalog,
		"MI_STONE",
		1,
	); err == nil {
		t.Fatal("accepted missile as ordinary weapon")
	}
}
