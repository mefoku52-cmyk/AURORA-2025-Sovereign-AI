package core

import (
\t"encoding/binary"
\t"fmt"
\t"io/ioutil"
\t"os"
)

type QuantBlock struct {
\tData  []byte
\tScale float32
\tZero  int8
\tRows  int
\tCols  int
\tType  int // 0=INT8, 1=INT4
}

func (qb *QuantBlock) Dequant() *Matrix {
\tm := NewMatrix(qb.Rows, qb.Cols)
\t
\tswitch qb.Type {
\tcase 0: // INT8 symmetric
\t\tfor i := 0; i < qb.Rows*qb.Cols; i++ {
\t\t\tval := int8(qb.Data[i])
\t\t\tm.Data[i] = qb.Scale * float32(val)
\t\t}
\tcase 1: // INT4 packed
\t\tfor i := 0; i < qb.Rows*qb.Cols; i += 2 {
\t\t\tbyte1 := qb.Data[i/2]
\t\t\tval1 := int8(byte1>>4) - 8
\t\t\tval2 := int8(byte1&0xF) - 8
\t\t\tm.Data[i] = qb.Scale * float32(val1)
\t\t\tif i+1 < len(m.Data) {
\t\t\t\tm.Data[i+1] = qb.Scale * float32(val2)
\t\t\t}
\t\t}
\t}
\treturn m
}

type AuroraModel struct {
\tVocabSize int
\tDModel    int
\tNLayers   int
\tNHeads    int
\tMaxSeq    int
\tQuantType int
\t
\t// Weights
\tTokenEmb *QuantBlock
\tPosEmb   *QuantBlock
\tLayers   []*TransformerLayer
\tLNFinal  *QuantBlock
\tLMHead   *QuantBlock
}

type TransformerLayer struct {
\tAttnQKV *QuantBlock
\tAttnOut *QuantBlock
\tFF1     *QuantBlock
\tFF2     *QuantBlock
\tNorm1   []float32
\tNorm2   []float32
}

func LoadModel(path string) (*AuroraModel, error) {
\tdata, err := ioutil.ReadFile(path)
\tif err != nil {
\t\treturn nil, err
\t}
\t
\tif len(data) < 32 {
\t\treturn nil, fmt.Errorf("invalid aurora file")
\t}
\t
\tif string(data[:8]) != "AURORA01" {
\t\treturn nil, fmt.Errorf("invalid magic")
\t}
\t
\toffset := 8
\tversion := binary.LittleEndian.Uint32(data[offset : offset+4])
\tif version != 1 {
\t\treturn nil, fmt.Errorf("unsupported version %d", version)
\t}
\toffset += 4
\t
\tvocabSize := int(binary.LittleEndian.Uint32(data[offset : offset+4]))
\tdModel := int(binary.LittleEndian.Uint32(data[offset+4 : offset+8]))
\tnLayers := int(binary.LittleEndian.Uint32(data[offset+8 : offset+12]))
\tnHeads := int(binary.LittleEndian.Uint32(data[offset+12 : offset+16]))
\tmaxSeq := int(binary.LittleEndian.Uint32(data[offset+16 : offset+20]))
\tquantType := int(binary.LittleEndian.Uint32(data[offset+20 : offset+24]))
\toffset += 24
\t
\tmodel := &AuroraModel{
\t\tVocabSize: vocabSize,
\t\tDModel:    dModel,
\t\tNLayers:   nLayers,
\t\tNHeads:    nHeads,
\t\tMaxSeq:    maxSeq,
\t\tQuantType: quantType,
\t}
\t
\t// Load weights (simplified - real impl would parse block headers)
\tmodel.TokenEmb = &QuantBlock{Data: data[offset:], Rows: vocabSize, Cols: dModel}
\t
\treturn model, nil
}
