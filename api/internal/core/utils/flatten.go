package utils

func Flatten(slices [][]string) []string {
	// Optionally, preallocate the capacity if you know the total length.
	total := 0
	for _, s := range slices {
		total += len(s)
	}

	flat := make([]string, 0, total)
	for _, s := range slices {
		flat = append(flat, s...) // using the ... operator to append all elements of s
	}
	return flat
}
