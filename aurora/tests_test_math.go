package core_test

import ("testing"; "aurora-ai-engine/core")

func TestMatrix(t *testing.T) {
\tm := core.NewMatrix(2, 3)
\tm.Set(0, 0, 1.0)
\tif m.At(0, 0) != 1.0 {
\t\tt.Error("Matrix failed")
\t}
}
