---
name: seqfu
description: SeqFu is a high-performance FASTA/FASTQ toolkit. Use this skill to identify the right SeqFu subcommand for sequence processing tasks: statistics (seqfu stats), filtering/searching (seqfu grep, seqfu cat, seqfu head), counting (seqfu count), paired-end handling (seqfu interleave, seqfu deinterleave, seqfu merge), dereplication (seqfu derep), ORF extraction (seqfu orf), reverse complement (seqfu rc), format conversion (seqfu tab), and primer trimming (fu-primers).
license: MIT
compatibility: opencode
metadata:
  opencode/slash: "true"
---

# SeqFu Skills

SeqFu is a compiled (Rust) bioinformatics toolkit for FASTA/FASTQ file manipulation. All
tools accept gzip-compressed input, support Unix pipes (use `-` for stdin), and work with
both FASTA and FASTQ formats unless otherwise noted.

## Installation

```bash
conda install -c conda-forge -c bioconda "seqfu>=1.0,<2.0"
```

## Subcommand Reference

| Task | Command | Skill |
|------|---------|-------|
| Sequence statistics (N50, GC%, lengths) | `seqfu stats` | seqfu-stats |
| Filter/search by name or oligo | `seqfu grep` | seqfu-grep |
| Concatenate, rename, filter sequences | `seqfu cat` | seqfu-cat |
| Count sequences in files | `seqfu count` | seqfu-count |
| Extract first N sequences | `seqfu head` | seqfu-head |
| Sort sequences by length | `seqfu sort` | seqfu-sort |
| Deduplicate sequences | `seqfu derep` | seqfu-derep |
| Interleave R1/R2 into single file | `seqfu interleave` | seqfu-interleave |
| Split interleaved into R1/R2 files | `seqfu deinterleave` | seqfu-deinterleave |
| Merge overlapping paired-end reads | `seqfu merge` | seqfu-merge |
| Extract ORFs from nucleotide sequences | `seqfu orf` | seqfu-orf |
| Reverse complement sequences | `seqfu rc` | seqfu-rc |
| Convert FASTA/FASTQ ↔ TSV | `seqfu tab` | seqfu-tab |
| Remove primers from amplicon reads | `fu-primers` | fu-primers |

## General Patterns

```bash
# Pipe multiple tools
seqfu cat *.fq | seqfu grep -n "pattern" | seqfu stats -n

# Force output format
seqfu cat file.fastq --fasta
seqfu cat file.fasta --fastq

# Use stdin
cat file.fq.gz | seqfu head -n 100
```
