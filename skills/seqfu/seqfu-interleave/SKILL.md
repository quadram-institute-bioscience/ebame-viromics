---
name: seqfu-interleave
description: Combine separate paired-end FASTQ files (R1 and R2) into a single interleaved FASTQ file, alternating forward and reverse reads. Use when a downstream tool requires interleaved input, or when archiving paired reads as a single file.
license: MIT
compatibility: opencode
---

# seqfu interleave

Combine R1 and R2 FASTQ files into a single interleaved FASTQ stream.

Short alias: `seqfu ilv`

## Key Flags

| Flag | Description |
|------|-------------|
| `-1, --first FILE` | Forward reads (R1) file |
| `-2, --second FILE` | Reverse reads (R2) file — auto-detected if omitted |
| `-c, --check` | Verify read names match between R1 and R2 |
| `-s, --strip-comments` | Remove comments from output |
| `-p, --prefix STRING` | Rename output reads with prefix |

## Auto-detection

If only `-1` is given, SeqFu infers the R2 file by substituting `_R1` → `_R2` (or `_1` → `_2`) in the filename.

## Examples

```bash
# Auto-detect R2 from R1 filename
seqfu interleave -1 sample_R1.fq.gz > interleaved.fq

# Explicit R1 and R2
seqfu interleave -1 sample_R1.fq.gz -2 sample_R2.fq.gz > interleaved.fq

# Verify matching read names
seqfu interleave -1 sample_R1.fq -2 sample_R2.fq -c > interleaved.fq

# Pipe into another tool
seqfu interleave -1 r1.fq | seqfu stats -n
```

## See Also

- `seqfu deinterleave` — reverse operation
- `seqfu merge` — merge overlapping paired reads
