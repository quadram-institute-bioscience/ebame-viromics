---
name: seqfu-merge
description: Merge overlapping paired-end FASTQ reads into longer consensus sequences using quality-aware overlap detection. Supports multithreading. Use for amplicon sequencing workflows where R1 and R2 reads overlap, or when creating longer pseudo-reads from short paired-end data.
license: MIT
compatibility: opencode
---

# seqfu merge

Merge overlapping paired-end reads. Uses quality scores to resolve mismatches in the
overlap region.

Short alias: `seqfu mrg`

## Key Flags

| Flag | Description |
|------|-------------|
| `-1, --first FILE` | Forward reads (R1) |
| `-2, --second FILE` | Reverse reads (R2) — auto-detected if omitted |
| `-i, --min-id FLOAT` | Minimum overlap identity [default: 0.90] |
| `-m, --min-overlap INT` | Minimum overlap length in bases [default: 20] |
| `--keep-unmerged` | Output R1 read when merging fails (instead of discarding) |
| `-t, --threads INT` | Worker threads [default: 8] |

## Examples

```bash
# Basic merge (auto-detect R2)
seqfu merge -1 sample_R1.fq.gz > merged.fq

# Stricter overlap requirements
seqfu merge -i 0.95 -m 30 -1 r1.fq -2 r2.fq > merged.fq

# Preview merge statistics
seqfu merge -1 r1.fq | seqfu stats -n

# Keep unmerged reads
seqfu merge -1 r1.fq -2 r2.fq --keep-unmerged > all_reads.fq

# Multithreaded
seqfu merge -t 16 -1 large_R1.fq.gz > merged.fq
```

## Notes

- Merged reads receive a combined quality string; bases in the overlap are resolved
  by choosing the base with the higher quality score.
- Amplicon workflows: pair with `seqfu derep` after merging.
