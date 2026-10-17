---
name: seqfu-orf
description: Extract open reading frames (ORFs) from nucleotide FASTA/FASTQ sequences, with optional translation to amino acids. Supports reverse complement scanning, multiple NCBI genetic codes, configurable minimum ORF size, and paired-end joining. Use for gene prediction, functional annotation preparation, or ORF-based sequence analysis.
license: MIT
compatibility: opencode
---

# seqfu orf

Extract ORFs from nucleotide sequences. Scans all three forward reading frames by default.

## Key Flags

| Flag | Description |
|------|-------------|
| `-m, --min-size INT` | Minimum ORF length in amino acids [default: 25] |
| `-r, --scan-reverse` | Also scan reverse complement strand (6-frame) |
| `-c, --code INT` | NCBI genetic code table [default: 1 = Standard] |
| `-t, --translate` | Output amino acid sequences instead of nucleotides |
| `-j, --join` | Attempt paired-end joining before ORF extraction |
| `--min-overlap INT` | Minimum overlap for PE joining [default: 12] |
| `-1 FILE`, `-2 FILE` | R1/R2 files for paired-end joining mode |

## Common NCBI Genetic Codes

| Code | Name |
|------|------|
| 1 | Standard (default) |
| 2 | Vertebrate Mitochondrial |
| 4 | Mold/Protozoan/Coelenterate Mitochondrial |
| 11 | Bacterial, Archaeal, Plant Plastid |

## Examples

```bash
# Extract ORFs >= 100 aa from assembly
seqfu orf --min-size 100 assembly.fa > orfs.fa

# 6-frame ORF extraction
seqfu orf -r --min-size 50 contigs.fa > orfs_6frame.fa

# Translate to protein
seqfu orf -r -t --min-size 100 contigs.fa > proteins.faa

# ORF extraction with bacterial genetic code
seqfu orf --code 11 --min-size 30 bacterial_assembly.fa

# Paired-end joining then ORF extraction
seqfu orf -j -1 r1.fq.gz -2 r2.fq.gz --min-size 29 > orfs.fa
```
