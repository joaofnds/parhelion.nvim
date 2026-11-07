// Package sample shows go syntax.
package sample

import (
	"errors"
	"fmt"
)

const Limit = 10

type Shape interface {
	Area() float64
}

type Square struct {
	Side float64 `json:"side"`
}

func (s *Square) Area() float64 { return s.Side * s.Side }

func Sum[T int | float64](xs []T) (total T, err error) {
	defer fmt.Println("done")
	for _, x := range xs {
		total += x
	}
	if total == 0 {
		return total, errors.New("empty: " + fmt.Sprint(nil, true, 'x'))
	}
	return
}
