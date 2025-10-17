---
title: votuderep
published: true
---

[CheckV]({{ site.baseurl }}/modules/Mining/2000-02-10-checkv) offers two scripts to perform the dereplication.

For **EBAME 10** we packaged the two scripts (and some more) into a Python package
called **votuderep**, that works with *subcommands*.

![votuderep]({{ site.baseurl }}{% link img/votuderep.png %})


## Installation

* You can install from Bioconda:

```bash
mamba install -c conda-forge -c bioconda votuderep
```

## Downloading EBAME files

The tool contains two modules to download:

* the reads and coassembly, using *trainingdata*:

```bash
votuderep trainingdata -o ~/virome/
```

* the databases (for Genomad and CheckV), using *getdbs*:

```bash
votuderep getdbs -o ~/db/
```

## Dereplicate vOTUs

```text
votuderep derep --help
                                                                          
 Usage: votuderep derep [OPTIONS]                                         
                                                                          
 Dereplicate vOTUs using BLAST and ANI clustering.                        
 This command: 1. Creates a BLAST database from input sequences 2.        
 Performs all-vs-all BLAST comparison 3. Calculates ANI and coverage for  
 sequence pairs 4. Clusters sequences by ANI using greedy algorithm 5.    
 Outputs cluster representatives (longest sequences)                      
 The algorithm selects the longest sequence from each cluster as the      
 representative, effectively removing shorter redundant sequences.        
                                                                          
╭─ Options ──────────────────────────────────────────────────────────────╮
│ *  --input     -i  FILE     Input FASTA file containing vOTUs          │
│                             [required]                                 │
│    --output    -o  FILE     Output FASTA file with dereplicated vOTUs  │
│    --threads   -t  INTEGER  Number of threads for BLAST                │
│    --tmp           TEXT     Directory for temporary files (default:    │
│                             $TEMP or /tmp or ./)                       │
│    --min-ani       FLOAT    Minimum ANI to consider two vOTUs as the   │
│                             same                                       │
│    --min-tcov      FLOAT    Minimum target coverage to consider two    │
│                             vOTUs as the same                          │
│    --keep                   Keep the temporary directory after         │
│                             completion                                 │
│    --help                   Show this message and exit.                │
╰────────────────────────────────────────────────────────────────────────╯
```

The input is a FASTA file with the predicted vOTU (`-i FASTA`)
and with `-o dereplicated.fasta`.

As you can see you can tweak the BLAST parameters with `--min-ani` and `--min-tcov`,
and you can specify the number of threads with `-t`.

## Filter FASTA with CheckV

CheckV generates a table with a summary of its predictions. 
With `filter` you can extract from the
corresponding FASTA file only the sequences based on CheckV quality metrics including length, completeness, contamination, and quality classification.

**Inputs**

- FASTA: Input FASTA file with viral contigs
- CHECKV_OUT: TSV output file from CheckV analysis

## Quality Levels (Hierarchical)

From highest to lowest confidence:

1. **Complete** - Complete genomes
2. **High-quality** - High confidence sequences
3. **Medium-quality** - Moderate confidence sequences
4. **Low-quality** - Lower confidence but valid sequences

Additionally:
* **Not-determined** - Quality undetermined (it does not mean low quality!)

## Main Flags

### Output
- `-o, --output` - Output FASTA file (default: STDOUT)

###  Filters

- `-m, --min-len` - Minimum contig length
- `--max-len` - Maximum contig length (0 = unlimited)
- `--min-quality [low|medium|high]` - Minimum quality threshold (default: low)
  - `low`: Keeps Low-quality and above
  - `medium`: Keeps Medium-quality and above  
  - `high`: Keeps High-quality and Complete only
- `--complete` - Keep only Complete genomes
- `--exclude-undetermined` - Exclude Not-determined sequences
- `-c, --min-completeness` - Minimum completeness percentage
- `--max-contam` - Maximum contamination percentage
- `--provirus` - Keep only proviruses
- `--no-warnings` - Exclude contigs with warnings