---
name: seqfu-deinterleave
description: Split an interleaved FASTQ file (alternating R1/R2 reads) into separate R1 and R2 output files. Use when converting interleaved FASTQ to the two-file paired format required by most tools.
license: MIT
compatibility: opencode
---

# seqfu deinterleave

Split an interleaved FASTQ file into separate R1 and R2 files.

Short alias: `seqfu dei`

## Key Flags

| Flag | Description |
|------|-------------|
| `-o, --output-basename STR` | Output basename; creates `<base>_R1.fq` and `<base>_R2.fq` |
| `-f, --for-ext STR` | R1 output extension [default: `_R1.fq`] |
| `-r, --rev-ext STR` | R2 output extension [default: `_R2.fq`] |
| `-c, --check` | Verify alternating read names are consistent |
| `-s, --strip-comments` | Remove comments from output |

## Examples

```bash
# Split to sample_R1.fq and sample_R2.fq
seqfu deinterleave -o sample interleaved.fq

# Custom extensions (gzip output via shell)
seqfu deinterleave -o sample -f _1.fastq -r _2.fastq interleaved.fq

# In a pipeline: remove primers then split back
fu-primers -1 r1.fq -2 r2.fq | seqfu deinterleave -o trimmed -

# From stdin
cat interleaved.fq.gz | seqfu deinterleave -o output -
```

## See Also

- `seqfu interleave` — reverse operation
