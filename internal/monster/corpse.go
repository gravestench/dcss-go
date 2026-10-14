package monster

import "fmt"

const FreshestCorpse = 110
const CorpseRotIntervalAut = 200
const corpseRotFactor = 20

// RollCorpse follows the ordinary 50% drop check and corpse appearance roll.
// A missed drop consumes no appearance draw.
func RollCorpse(roller Roller) (appearance int, dropped bool, err error) {
	coin, err := drawCorpse(roller, 2)

	if err != nil || coin == 1 {
		return 0, false, err
	}

	appearance, err = drawCorpse(roller, 255)

	if err != nil {
		return 0, false, err
	}

	return appearance + 1, true, nil
}

// AgeCorpse applies one source timed-effect interval. appearance is nonzero
// only when skeletonisation rerolls it. The caller owns the floor entity.
func AgeCorpse(
	roller Roller,
	kindID string,
	freshness, elapsedAut int,
) (nextKind string, nextFreshness, appearance int, alive bool, err error) {
	validKind := kindID == "CORPSE_BODY" || kindID == "CORPSE_SKELETON"

	if !validKind || freshness < 1 ||
		freshness > FreshestCorpse || elapsedAut < 0 {
		return "", 0, 0, false, fmt.Errorf("invalid corpse decay input %q/%d/%d", kindID, freshness, elapsedAut)
	}

	nextFreshness = freshness - elapsedAut/corpseRotFactor

	if nextFreshness > 0 {
		return kindID, nextFreshness, 0, true, nil
	}

	if kindID == "CORPSE_SKELETON" {
		return "", 0, 0, false, nil
	}

	roll, err := drawCorpse(roller, 255)

	if err != nil {
		return "", 0, 0, false, err
	}

	return "CORPSE_SKELETON", FreshestCorpse, roll + 1, true, nil
}

func drawCorpse(roller Roller, bound int) (int, error) {
	if roller == nil {
		return 0, fmt.Errorf("corpse roller is nil")
	}

	value, err := roller.Intn("corpse", bound)

	if err != nil {
		return 0, err
	}

	if value < 0 || value >= bound {
		return 0, fmt.Errorf("corpse roll %d outside [0,%d)", value, bound)
	}

	return value, nil
}
