package core

import (
\t"math"
\t"runtime"
\t"sync"
)

// Matrix - basic matrix type
type Matrix struct {
\tData  []float32
\tRows  int
\tCols  int
}

func NewMatrix(rows, cols int) *Matrix {
\treturn &Matrix{
\t\tData: make([]float32, rows*cols),
\t\tRows: rows,
\t\tCols: cols,
\t}
}

func (m *Matrix) At(r, c int) float32 {
\treturn m.Data[r*m.Cols+c]
}

func (m *Matrix) Set(r, c int, v float32) {
\tm.Data[r*m.Cols+c] = v
}

// Parallel MatMul
func (a *Matrix) MatMul(b *Matrix, result *Matrix) {
\tvar wg sync.WaitGroup
\tnWorkers := runtime.NumCPU()
\t
\tfor i := 0; i < a.Rows; i++ {
\t\twg.Add(1)
\t\tgo func(row int) {
\t\t\tdefer wg.Done()
\t\t\tfor j := 0; j < b.Cols; j++ {
\t\t\t\tsum := float32(0)
\t\t\t\tfor k := 0; k < a.Cols; k++ {
\t\t\t\t\tsum += a.At(row, k) * b.At(k, j)
\t\t\t\t}
\t\t\t\tresult.Set(row, j, sum)
\t\t\t}
\t\t}(i)
\t}
\twg.Wait()
}

// Softmax with numerical stability
func Softmax(input []float32, temp float32) []float32 {
\tmaxVal := float32(-math.MaxFloat32)
\tfor _, v := range input {
\t\tif v > maxVal {
\t\t\tmaxVal = v
\t\t}
\t}
\t
\tsum := float32(0)
\toutput := make([]float32, len(input))
\tfor i, v := range input {
\t\texpV := float32(math.Exp(float64((v-maxVal)/temp)))
\t\toutput[i] = expV
\t\tsum += expV
\t}
\t
\tfor i := range output {
\t\toutput[i] /= sum
\t}
\treturn output
}

// Top-k + Top-p sampling
func TopKTopP(probs []float32, k int, p float32) []float32 {
\tif k >= len(probs) {
\t\treturn probs
\t}
\t
\t// Top-k
\tsorted := make([]float32, len(probs))
\tcopy(sorted, probs)
\t
\t// Simple sort for demo (production: quickselect)
\tfor i := range sorted {
\t\tfor j := i + 1; j < len(sorted); j++ {
\t\t\tif sorted[i] < sorted[j] {
\t\t\t\tsorted[i], sorted[j] = sorted[j], sorted[i]
\t\t\t}
\t\t}
\t}
\t
\t// Top-p (nucleus)
\tcumsum := float32(0)
\tcutoff := 0
\tfor i, prob := range sorted {
\t\tcumsum += prob
\t\tif cumsum > p {
\t\t\tcutoff = i
\t\t\tbreak
\t\t}
\t}
\t
\tif cutoff < k-1 {
\t\tk = cutoff + 1
\t}
\t
\trenorm := make([]float32, len(probs))
\tsum := float32(0)
\tfor i := 0; i < k; i++ {
\t\tsum += sorted[i]
\t}
\tfor i, prob := range probs {
\t\tif i < k {
\t\t\trenorm[i] = prob / sum
\t\t} else {
\t\t\trenorm[i] = 0
\t\t}
\t}
\treturn renorm
}

// GELU activation
func GELU(x float32) float32 {
\treturn x * 0.5 * (1.0 + float32(math.Erf(float64(x)/math.Sqrt2)))
}

// RMSNorm
func RMSNorm(x []float32, weight []float32) []float32 {
\tsumSq := float32(0)
\tfor _, v := range x {
\t\tsumSq += v * v
\t}
\trms := float32(math.Sqrt(float64(sumSq / float32(len(x)))))
\t
\tresult := make([]float32, len(x))
\tfor i, v := range x {
\t\tresult[i] = float32(v) * weight[i] / (rms + 1e-6)
\t}
\treturn result
}
