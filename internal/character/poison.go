package character

import (
	"fmt"
	"math"
)

const maxHumanPoison = math.MaxInt32

const poisonDenominator = 5.0

const poisonMinRate = 100.0

const poisonMaxRate = 5000.0

// DecayHumanPoison follows player.cc:4204-4339 for an ordinary living Human.
// Amounts are thousandths of one eventual HP of poison damage.
func DecayHumanPoison(amountScaled, elapsedAut int) (int, int, error) {
	if amountScaled < 1000 || amountScaled > maxHumanPoison || elapsedAut <= 0 {
		return 0, 0, fmt.Errorf(
			"invalid Human poison %d over %d aut",
			amountScaled,
			elapsedAut,
		)
	}

	remainingAut := poisonDurationToAut(float64(amountScaled)) -
		float64(elapsedAut)
	remainingDuration := poisonAutToDuration(remainingAut)

	if remainingDuration < -float64(maxHumanPoison) ||
		remainingDuration > float64(maxHumanPoison) {
		return 0, 0, fmt.Errorf("poison decay exceeded source integer range")
	}

	// C++ truncates the inverse duration before counting lost whole points.
	nextAmount := int(remainingDuration)
	damage := amountScaled/1000 - nextAmount/1000

	if nextAmount < 1000 {
		nextAmount = 0
	}

	return nextAmount, damage, nil
}

func poisonDurationToAut(duration float64) float64 {
	minimumDuration := poisonDenominator * poisonMinRate * 10
	maximumDuration := poisonDenominator * poisonMaxRate * 10
	decay := math.Log(poisonDenominator / (poisonDenominator - 1))

	if duration < minimumDuration {
		return duration / poisonMinRate
	}

	if duration < maximumDuration {
		return 10 * (poisonDenominator + math.Log(duration/minimumDuration)/decay)
	}

	maximumRateAut := 10 * (poisonDenominator + math.Log(poisonMaxRate/poisonMinRate)/decay)

	return maximumRateAut + (duration-maximumDuration)/poisonMaxRate
}

func poisonAutToDuration(remainingAut float64) float64 {
	minimumRateAut := poisonDenominator * 10

	if remainingAut < minimumRateAut {
		return remainingAut * poisonMinRate
	}

	decay := math.Log(poisonDenominator / (poisonDenominator - 1))
	maximumRateAut := 10 * (poisonDenominator + math.Log(poisonMaxRate/poisonMinRate)/decay)

	if remainingAut < maximumRateAut {
		return 10 * poisonDenominator * poisonMinRate *
			math.Exp(decay/10*(remainingAut-minimumRateAut))
	}

	return poisonDenominator*10*poisonMaxRate +
		poisonMaxRate*(remainingAut-maximumRateAut)
}
