package rules

// MeleeDamage is the controlled slice's damage roll, not full DCSS combat.
func MeleeDamage(baseDamage, roll int) int {
	if roll < 0 || baseDamage < 0 {
		return 0
	}
	if roll > baseDamage {
		return baseDamage
	}
	return roll
}
