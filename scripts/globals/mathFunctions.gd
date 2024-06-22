extends Node3D

func Lerp(from, to, weight):
	var difference = Wrapf(to - from, -180, 180)
	return from + difference * weight

func Wrapf(value, minimum, maximum):
	var degrees = maximum - minimum
	return minimum + fmod((value - minimum), degrees) + (degrees if value < minimum else 0)

func RoundToNearestDegrees(angle, degrees):
	return round(angle / degrees) * degrees