package core

import (
\t"fmt"
\t"log"
\t"os"
\t"runtime"
\t"syscall"
\t"time"
)

type InferenceStats struct {
\tTokensPerSec float64
\tTotalTokens  int
\tPeakRAMMB    int64
\tDurationSec  float64
}

type AuroraRuntime struct {
\tmodel    *AuroraModel
\tkvCache  []Matrix // Simplified
\tstats    InferenceStats
\tmaxRAMMB int
}

func NewAuroraRuntime(modelPath string, maxRAMMB int) (*AuroraRuntime, error) {
\t// Set resource limits
\tvar rlim syscall.Rlimit
\trlim.Cur = uint64(maxRAMMB * 1024 * 1024)
\trlim.Max = uint64(maxRAMMB * 1024 * 1024)
\tsyscall.Setrlimit(syscall.RLIMIT_AS, &rlim)
\t
\tmodel, err := LoadModel(modelPath)
\tif err != nil {
\t\treturn nil, err
\t}
\t
\trt := &AuroraRuntime{
\t\tmodel:    model,
\t\tmaxRAMMB: maxRAMMB,
\t}
\t
\t// Resource monitoring goroutine
\tgo rt.monitorResources()
\t
\treturn rt, nil
}

func (rt *AuroraRuntime) monitorResources() {
\tfor {
\t\ttime.Sleep(100 * time.Millisecond)
\t\tif rss := rt.getRSS(); rss > int64(rt.maxRAMMB*1024*1024*0.9) {
\t\t\tlog.Printf("RSS limit hit: %dMB", rss/1024/1024)
\t\t\tos.Exit(1)
\t\t}
\t}
}

func (rt *AuroraRuntime) getRSS() int64 {
\tvar stat syscall.Stat_t
\tsyscall.Stat("/proc/self/stat", &stat)
\treturn int64(stat.Size)
}

func (rt *AuroraRuntime) Embed(token int) *Matrix {
\temb := NewMatrix(1, rt.model.DModel)
\ttokenEmb := rt.model.TokenEmb.Dequant()
\tfor i := 0; i < rt.model.DModel; i++ {
\t\temb.Set(0, i, tokenEmb.At(token%rt.model.VocabSize, i))
\t}
\treturn emb
}

func (rt *AuroraRuntime) Forward(emb *Matrix) *Matrix {
\tx := emb
\t
\t// Through all layers
\tfor _, layer := range rt.model.Layers {
\t\t// Self-attention (simplified)
\t\tnorm1 := RMSNorm(x.Data, layer.Norm1)
\t\t// MHA would go here (simplified)
\t\tx = x // residual
\t\t
\t\t// FFN
\t\tnorm2 := RMSNorm(x.Data, layer.Norm2)
\t\tff1 := layer.FF1.Dequant()
\t\tffOut := NewMatrix(1, rt.model.DModel)
\t\tff1.MatMul(x, ffOut) // Simplified
\t\tx.Data = append(x.Data, ffOut.Data...)
\t}
\t
\t// Final LM head
\tlogits := NewMatrix(1, rt.model.VocabSize)
\tlmHead := rt.model.LMHead.Dequant()
\tlmHead.MatMul(x, logits)
\t
\treturn logits
}

func (rt *AuroraRuntime) Generate(prompt string, maxTokens int, temp float32) (string, InferenceStats) {
\tstart := time.Now()
\t
\tvar output []rune
\ttokensGenerated := 0
\t
\tfor tokensGenerated < maxTokens {
\t\t// Simplified tokenization
\t\ttoken := 1000 + tokensGenerated // dummy
\t\t
\t\temb := rt.Embed(token)
\t\tlogits := rt.Forward(emb)
\t\t
\t\t// Sampling
\t\tprobs := Softmax(logits.Data, temp)
\t\tprobs = TopKTopP(probs, 50, 0.9)
\t\t
\t\t// Sample token (simplified)
\t\tnextToken := 1000 + tokensGenerated
\t\toutput = append(output, rune(nextToken))
\t\t
\t\ttokensGenerated++
\t}
\t
\tstats := InferenceStats{
\t\tTokensPerSec: float64(tokensGenerated) / time.Since(start).Seconds(),
\t\tTotalTokens:  tokensGenerated,
\t\tPeakRAMMB:    rt.getRSS() / 1024 / 1024,
\t\tDurationSec:  time.Since(start).Seconds(),
\t}
\t
\treturn string(output), stats
}
