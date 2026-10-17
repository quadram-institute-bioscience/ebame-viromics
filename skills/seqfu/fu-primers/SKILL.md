---
name: fu-primers
description: Remove primers from paired-end amplicon FASTQ reads. Supports IUPAC degenerate bases in primer sequences, mismatch tolerance, dimer/concatemer detection, and multithreading. Outputs interleaved FASTQ to stdout. Use for 16S, ITS, or other amplicon workflows where primer trimming is required before downstream analysis.
license: MIT
compatibility: opencode
---

# fu-primers

Trim primers from paired-end amplicon FASTQ reads. Part of the SeqFu utility suite.

Outputs interleaved FASTQ to stdout; pipe to `seqfu deinterleave` to split back to R1/R2.

## Key Flags

| Flag | Description |
|------|-------------|
| `-1, --first FILE` | Forward reads (R1) file |
| `-2, --second FILE` | Reverse reads (R2) file — auto-detected if omitted |
| `-f, --fwd-primer SEQ` | Forward primer sequence (IUPAC degenerate bases allowed) |
| `-r, --rev-primer SEQ` | Reverse primer sequence (IUPAC degenerate bases allowed) |
| `-m, --min-len INT` | Minimum read length after trimming [default: 50] |
| `--primer-mismatches INT` | Maximum mismatches allowed in primer match [default: 2] |
| `-t, --threads INT` | Worker threads [default: 8] |
| `--check-dimers` | Detect and discard primer dimers |

## Common Amplicon Primers

```
16S V3-V4:
  Forward: CCTACGGGNGGCWGCAG
  Reverse:  GGACTACHVGGGTATCTAATCC

ITS1-ITS2:
  Forward: CTTGGTCATTTAGAGGAAGTAA
  Reverse:  GCTGCGTTCTTCATCGATGC
```

## Examples

```bash
# Auto-detect R2 and trim 16S primers
fu-primers -1 sample_R1.fq.gz \
  -f CCTACGGGNGGCWGCAG \
  -r GGACTACHVGGGTATCTAATCC > trimmed_interleaved.fq

# Allow 3 mismatches
fu-primers -1 r1.fq -2 r2.fq \
  -f CCTACGGGNGGCWGCAG \
  -r GGACTACHVGGGTATCTAATCC \
  --primer-mismatches 3 > trimmed.fq

# Trim then split back to R1/R2
fu-primers -1 r1.fq -2 r2.fq \
  -f FORWARD_PRIMER -r REVERSE_PRIMER | \
  seqfu deinterleave -o trimmed -

# Full amplicon pipeline
fu-primers -1 r1.fq.gz -f CCTACGGGNGGCWGCAG -r GGACTACHVGGGTATCTAATCC \
  | seqfu deinterleave -o trimmed - \
  && seqfu merge -1 trimmed_R1.fq -2 trimmed_R2.fq \
  | seqfu derep -m 2 > derep.fa
```

## Notes

- Output is interleaved FASTQ; use `seqfu deinterleave` to produce separate R1/R2 files.
- Primer sequences support all IUPAC degenerate bases.
