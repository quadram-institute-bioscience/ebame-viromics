#!/usr/bin/env bash
#
# test-pipeline.sh — end-to-end smoke test of the EBAME viromics tutorial
#
# Exercises, in order: dataset download -> geNomad -> CheckV -> dereplication
# -> mapping (minimap2/samtools) -> abundance table (CoverM).
# (Anvi'o and the "Extras" material are intentionally out of scope.)
#
# Design goals:
#   * Everything happens under one -o/--outdir WORKDIR.
#   * If a conda env with the name we need already exists, it is reused as-is.
#   * The run is resumable: re-running the same command skips completed
#     steps. A step is only ever considered "done" after it fully succeeds
#     (a completion marker is written last) so an aborted/partial step
#     (killed download, interrupted mamba create, interrupted tool run)
#     is always redone cleanly on the next run rather than silently
#     treated as finished.
#
# Author: Andrea Telatin

set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults / globals
# ---------------------------------------------------------------------------

WORKDIR="./virome-pipeline-test"
THREADS=""
FORCE=0
ONLY_STEP=""
LIST_STEPS=0

GENOMAD_ENV="genomad"
CHECKV_ENV="checkv"
DEREP_ENV="derep"
MAPPING_ENV="mapping"

ZENODO_URL="https://zenodo.org/api/records/10650983/files/illumina_sample_pool_megahit.fa.gz/content"
EBI="ftp://ftp.sra.ebi.ac.uk/vol1/fastq"
ANICLUST_URL="https://bitbucket.org/berkeleylab/checkv/raw/51a5293f75da04c5d9a938c9af9e2b879fa47bd8/scripts/aniclust.py"
ANICALC_URL="https://bitbucket.org/berkeleylab/checkv/raw/51a5293f75da04c5d9a938c9af9e2b879fa47bd8/scripts/anicalc.py"

SAMPLES=(ERR6797443 ERR6797444 ERR6797445)

STEPS_ORDER=(
  download_assembly
  download_reads
  verify_inputs
  env_genomad
  db_genomad
  run_genomad
  rename_genomad
  env_checkv
  db_checkv
  run_checkv
  env_derep
  download_derep_scripts
  run_derep
  env_mapping
  mapping
  coverm
)

declare -a STEP_STATUS=()

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------

ts() { date +"%H:%M:%S"; }
c_reset=$'\033[0m'; c_green=$'\033[1;32m'; c_red=$'\033[1;31m'; c_yellow=$'\033[1;33m'; c_blue=$'\033[1;34m'

log()   { printf "%s\n" "$*"; }
info()  { printf "%s ${c_blue}[INFO]${c_reset}  %s\n" "$(ts)" "$*"; }
ok()    { printf "%s ${c_green}[OK]${c_reset}    %s\n" "$(ts)" "$*"; }
warn()  { printf "%s ${c_yellow}[WARN]${c_reset}  %s\n" "$(ts)" "$*" >&2; }
err()   { printf "%s ${c_red}[ERROR]${c_reset} %s\n" "$(ts)" "$*" >&2; }
die()   { err "$*"; exit 1; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [-o WORKDIR] [-t THREADS] [options]

Runs the whole EBAME viromics tutorial pipeline (dataset download, geNomad,
CheckV, dereplication, mapping, CoverM abundance table) end-to-end as a
smoke test, so you can verify every step actually works.

Options:
  -o, --outdir DIR      Directory where everything happens (default: ${WORKDIR})
  -t, --threads N        Threads to use for the heavy steps (default: autodetect)
      --only STEP        Run only this one step (implies its prerequisites'
                          outputs must already exist)
      --force             Ignore completion markers and redo every step
                          (existing conda environments are still reused)
      --list-steps        Print the ordered list of steps and exit
  -h, --help               Show this help

Environment variables it will use if already set (mirrors the tutorial):
  \$DB      Path containing pre-downloaded genomad_db/ and checkv-db-*/
           (skips downloading those databases if found)

The run is resumable: re-run the exact same command after a failure or an
interruption (Ctrl-C, killed VM, dropped connection) and completed steps
are skipped, while any step that was interrupted mid-way is redone from a
clean state rather than silently treated as finished.

Logs for each step are written to WORKDIR/logs/<step>.log
EOF
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--outdir) WORKDIR="$2"; shift 2 ;;
    --outdir=*) WORKDIR="${1#*=}"; shift ;;
    -t|--threads) THREADS="$2"; shift 2 ;;
    --threads=*) THREADS="${1#*=}"; shift ;;
    --only) ONLY_STEP="$2"; shift 2 ;;
    --only=*) ONLY_STEP="${1#*=}"; shift ;;
    --force) FORCE=1; shift ;;
    --list-steps) LIST_STEPS=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown argument: $1 (see --help)" ;;
  esac
done

if [[ $LIST_STEPS -eq 1 ]]; then
  printf "%s\n" "${STEPS_ORDER[@]}"
  exit 0
fi

if [[ -n "$ONLY_STEP" ]]; then
  found=0
  for s in "${STEPS_ORDER[@]}"; do [[ "$s" == "$ONLY_STEP" ]] && found=1; done
  [[ $found -eq 1 ]] || die "Unknown step '$ONLY_STEP'. Use --list-steps to see valid names."
fi

# ---------------------------------------------------------------------------
# Prerequisite checks
# ---------------------------------------------------------------------------

have_cmd() { command -v "$1" >/dev/null 2>&1; }

for c in curl gzip awk find date mkdir mv rm sort; do
  have_cmd "$c" || die "Required command '$c' not found in PATH"
done
have_cmd conda || die "conda not found in PATH (needed to create/reuse environments)"

if have_cmd mamba; then
  CONDA_CREATOR=mamba
elif have_cmd conda; then
  CONDA_CREATOR=conda
  warn "mamba not found, falling back to 'conda create' (will be slower)"
fi

if [[ -z "$THREADS" ]]; then
  if have_cmd nproc; then THREADS=$(nproc)
  elif have_cmd sysctl; then THREADS=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
  else THREADS=4
  fi
fi
[[ "$THREADS" =~ ^[0-9]+$ && "$THREADS" -ge 1 ]] || die "--threads must be a positive integer"

# ---------------------------------------------------------------------------
# Workdir layout
# ---------------------------------------------------------------------------

mkdir -p "$WORKDIR"
WORKDIR="$(cd "$WORKDIR" && pwd)"
DATA_DIR="$WORKDIR/data"
DB_DIR="$WORKDIR/db"
BIN_DIR="$WORKDIR/bin"
LOG_DIR="$WORKDIR/logs"
STATE_DIR="$WORKDIR/.state"
GENOMAD_OUT="$WORKDIR/genomad-out"
CHECKV_OUT="$WORKDIR/checkv-out"
DEREP_OUT="$WORKDIR/derep"
BAM_DIR="$WORKDIR/bams"
TABLE_DIR="$WORKDIR/tables"

mkdir -p "$DATA_DIR" "$DB_DIR" "$BIN_DIR" "$LOG_DIR" "$STATE_DIR"

info "Workdir:  $WORKDIR"
info "Threads:  $THREADS"
info "Creator:  $CONDA_CREATOR"

if [[ $FORCE -eq 1 ]]; then
  # Only clear step markers, never the conda-env-created markers: forcing a
  # rerun should not force expensive/destructive environment recreation.
  find "$STATE_DIR" -maxdepth 1 -name '*.done' -delete 2>/dev/null || true
  warn "--force: all step completion markers cleared, environments are still reused"
fi

env_exists() { conda env list 2>/dev/null | awk 'NF && $1 !~ /^#/ {print $1}' | grep -Fxq "$1"; }

# ---------------------------------------------------------------------------
# Generic helpers
# ---------------------------------------------------------------------------

# Run a command inside a conda env without needing to `conda activate`.
crun() {
  local env="$1"; shift
  conda run --no-capture-output -n "$env" "$@"
}

# Atomic, resumable download: only the fully-downloaded file ever gets its
# final name, so a killed/interrupted download can never be mistaken for a
# completed one on the next run.
download_file() {
  local url="$1" dest="$2" desc="${3:-$dest}"
  if [[ -s "$dest" ]]; then
    info "  already downloaded: $desc"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  local tmp="${dest}.part"
  rm -f "$tmp"
  info "  downloading: $desc"
  if ! curl -fL --retry 3 --retry-connrefused --retry-delay 3 -o "$tmp" "$url"; then
    rm -f "$tmp"
    err "  download failed: $desc"
    return 1
  fi
  if [[ "$dest" == *.gz ]]; then
    if ! gzip -t "$tmp" 2>/dev/null; then
      rm -f "$tmp"
      err "  downloaded file is not a valid gzip (truncated/corrupt): $desc"
      return 1
    fi
  fi
  mv "$tmp" "$dest"
  ok "  downloaded: $desc ($(du -h "$dest" | cut -f1))"
}

# Create a conda env, or reuse one that already carries the right name.
#
# Three persistent (STATE_DIR) markers per env name, checked in order:
#   .pre_existing  - the env was already there the very first time this
#                     workdir's pipeline looked for it. Trusted and reused
#                     forever, untouched, no matter its actual contents —
#                     this is what makes "an env with this name already
#                     exists, use it" work.
#   .created        - this script created the env itself, and the creation
#                     ran to completion. Reused on later resumes.
#   .attempting     - written *before* an actual `mamba/conda create` is
#                     invoked, and only removed once creation succeeds.
#                     If a run is found on the next invocation, it can only
#                     mean a previous creation was interrupted (killed VM,
#                     dropped connection): the env is treated as ours,
#                     removed and recreated cleanly, never silently reused.
#
# Writing .attempting before the create call (rather than inferring things
# after the fact from `env_exists`) is what lets us tell "genuinely
# pre-existing" apart from "we started making it and got interrupted" —
# both look identical to `env_exists` alone once the env is half-built.
ensure_env() {
  local name="$1"; shift
  local pkgs=("$@")
  local m_pre="$STATE_DIR/env_${name}.pre_existing"
  local m_attempting="$STATE_DIR/env_${name}.attempting"
  local m_created="$STATE_DIR/env_${name}.created"

  if [[ -f "$m_pre" ]]; then
    info "  conda env '$name' pre-existed on this system — reusing as-is (never modified by this script)"
    return 0
  fi
  if [[ -f "$m_created" ]]; then
    info "  conda env '$name' was created by an earlier run of this script — reusing"
    return 0
  fi

  if [[ ! -f "$m_attempting" ]]; then
    if env_exists "$name"; then
      info "  conda env '$name' already exists on this system — reusing it (this script will never modify it)"
      : > "$m_pre"
      return 0
    fi
    : > "$m_attempting"
  else
    warn "  conda env '$name' creation was interrupted by a previous run — recreating it cleanly"
    "$CONDA_CREATOR" env remove -y -n "$name" >/dev/null 2>&1 || true
  fi

  info "  creating conda env '$name': ${pkgs[*]}"
  "$CONDA_CREATOR" create -y -n "$name" -c conda-forge -c bioconda "${pkgs[@]}" || return 1
  env_exists "$name" || { err "  env '$name' still missing after creation attempt"; return 1; }
  rm -f "$m_attempting"
  : > "$m_created"
}

resolve_dbs() {
  GENOMAD_DB_DIR=""
  CHECKV_DB_DIR=""
  if [[ -n "${DB:-}" && -d "${DB}/genomad_db" ]]; then
    GENOMAD_DB_DIR="${DB}/genomad_db"
  fi
  if [[ -n "${DB:-}" ]]; then
    CHECKV_DB_DIR="$(find "$DB" -maxdepth 1 -type d -iname 'checkv-db-*' 2>/dev/null | sort | tail -n1)"
  fi
}

# ---------------------------------------------------------------------------
# Step functions — each one assumes it is starting from a clean slate for
# whatever it manages (its own output dirs are wiped before it (re)runs);
# run_step() only ever invokes a step when its completion marker is absent.
# ---------------------------------------------------------------------------

step_download_assembly() {
  download_file "$ZENODO_URL" "$DATA_DIR/human_gut_assembly.fa.gz" "co-assembly (Zenodo)" || return 1
}

step_download_reads() {
  download_file "$EBI/ERR679/005/ERR6797445/ERR6797445_1.fastq.gz" "$DATA_DIR/ERR6797445_R1.fastq.gz" "ERR6797445 R1" || return 1
  download_file "$EBI/ERR679/005/ERR6797445/ERR6797445_2.fastq.gz" "$DATA_DIR/ERR6797445_R2.fastq.gz" "ERR6797445 R2" || return 1
  download_file "$EBI/ERR679/004/ERR6797444/ERR6797444_1.fastq.gz" "$DATA_DIR/ERR6797444_R1.fastq.gz" "ERR6797444 R1" || return 1
  download_file "$EBI/ERR679/004/ERR6797444/ERR6797444_2.fastq.gz" "$DATA_DIR/ERR6797444_R2.fastq.gz" "ERR6797444 R2" || return 1
  download_file "$EBI/ERR679/003/ERR6797443/ERR6797443_1.fastq.gz" "$DATA_DIR/ERR6797443_R1.fastq.gz" "ERR6797443 R1" || return 1
  download_file "$EBI/ERR679/003/ERR6797443/ERR6797443_2.fastq.gz" "$DATA_DIR/ERR6797443_R2.fastq.gz" "ERR6797443 R2" || return 1
}

step_verify_inputs() {
  local n
  n=$(gzip -dc "$DATA_DIR/human_gut_assembly.fa.gz" | grep -c ">" || true)
  [[ "$n" -gt 0 ]] || { err "  assembly has no sequences"; return 1; }
  info "  co-assembly: $n contigs"

  local s r1 r2 lines
  for s in "${SAMPLES[@]}"; do
    for r in R1 R2; do
      local f="$DATA_DIR/${s}_${r}.fastq.gz"
      [[ -s "$f" ]] || { err "  missing $f"; return 1; }
      lines=$(gzip -dc "$f" | wc -l | tr -d ' ')
      [[ "$lines" -gt 0 && $(( lines % 4 )) -eq 0 ]] || { err "  $f does not look like a well-formed FASTQ ($lines lines)"; return 1; }
    done
  done
  info "  all 6 FASTQ files look well-formed"
}

step_env_genomad() { ensure_env "$GENOMAD_ENV" genomad=1.9 seqfu=1.22; }

# A directory existing is not proof a multi-GB database download actually
# completed (a truncated/interrupted download can still leave a directory
# with *some* files in it). Sanity-check size and file count before trusting
# it, whether it's one we just downloaded or one found lying around.
genomad_db_looks_complete() {
  local d="$1" n size_mb
  [[ -d "$d" ]] || return 1
  n=$(find "$d" -type f 2>/dev/null | wc -l | tr -d ' ')
  size_mb=$(du -sm "$d" 2>/dev/null | cut -f1)
  [[ "${n:-0}" -ge 5 && "${size_mb:-0}" -ge 500 ]]
}

step_db_genomad() {
  resolve_dbs
  if [[ -n "$GENOMAD_DB_DIR" ]]; then
    info "  using pre-existing geNomad DB: $GENOMAD_DB_DIR"
    return 0
  fi
  GENOMAD_DB_DIR="$DB_DIR/genomad_db"

  if genomad_db_looks_complete "$GENOMAD_DB_DIR"; then
    info "  existing geNomad DB at $GENOMAD_DB_DIR looks complete, reusing (no download needed)"
    return 0
  fi

  rm -rf "$GENOMAD_DB_DIR"
  crun "$GENOMAD_ENV" genomad download-database "$DB_DIR" || return 1
  if ! genomad_db_looks_complete "$GENOMAD_DB_DIR"; then
    err "  geNomad DB at $GENOMAD_DB_DIR still looks incomplete after download — removing so the next run redownloads cleanly"
    rm -rf "$GENOMAD_DB_DIR"
    return 1
  fi
}

step_run_genomad() {
  resolve_dbs
  [[ -n "$GENOMAD_DB_DIR" ]] || GENOMAD_DB_DIR="$DB_DIR/genomad_db"
  [[ -d "$GENOMAD_DB_DIR" ]] || { err "  geNomad DB not found at $GENOMAD_DB_DIR"; return 1; }

  rm -rf "$GENOMAD_OUT"
  crun "$GENOMAD_ENV" genomad end-to-end "$DATA_DIR/human_gut_assembly.fa.gz" "$GENOMAD_OUT" "$GENOMAD_DB_DIR" -t "$THREADS" || return 1

  local viral="$GENOMAD_OUT/human_gut_assembly_summary/human_gut_assembly_virus.fna"
  [[ -s "$viral" ]] || { err "  expected output missing: $viral"; return 1; }
  local n; n=$(grep -c ">" "$viral" || true)
  info "  geNomad predicted $n viral sequences"
}

step_rename_genomad() {
  local viral="$GENOMAD_OUT/human_gut_assembly_summary/human_gut_assembly_virus.fna"
  local out="$GENOMAD_OUT/genomad_votus.fna"
  rm -f "$out" "$out.tmp"
  crun "$GENOMAD_ENV" seqfu cat --anvio --report "$GENOMAD_OUT/rename_report.txt" "$viral" > "$out.tmp" || { rm -f "$out.tmp"; return 1; }
  [[ -s "$out.tmp" ]] || { err "  seqfu cat produced an empty file"; rm -f "$out.tmp"; return 1; }
  mv "$out.tmp" "$out"
}

step_env_checkv() { ensure_env "$CHECKV_ENV" checkv diamond; }

# Verify (and, where possible, locally repair) a CheckV database.
#
# Some checkv-db-v1.5 tarball builds only ship the BLAST-era protein FASTA
# (genome_db/checkv_reps.faa), while newer checkv releases require a DIAMOND
# index (genome_db/checkv_reps.dmnd) instead and fail with "database file
# not found" at the very end of `checkv end_to_end`, after most of the run
# already completed. Treating the download as "done" just because the
# directory exists (as an earlier version of this script did) means that
# failure gets hit on every single run without ever being fixed — exactly
# the kind of silently-accepted partial state this script is meant to avoid.
#
# If the fasta is present we build the missing index locally (fast, no
# network needed); if even the fasta is missing the DB is genuinely
# incomplete/corrupt and the caller should wipe it and redownload.
ensure_checkv_db_complete() {
  local db="$1"
  local dmnd="$db/genome_db/checkv_reps.dmnd"
  local faa="$db/genome_db/checkv_reps.faa"

  [[ -s "$dmnd" ]] && return 0

  if [[ -s "$faa" ]]; then
    warn "  $db is missing genome_db/checkv_reps.dmnd (known checkv/db version mismatch) — building it locally with 'diamond makedb'"
    crun "$CHECKV_ENV" diamond makedb --in "$faa" --db "$db/genome_db/checkv_reps" --threads "$THREADS" || {
      err "  'diamond makedb' failed to build checkv_reps.dmnd"
      return 1
    }
    [[ -s "$dmnd" ]] || { err "  checkv_reps.dmnd still missing after 'diamond makedb'"; return 1; }
    return 0
  fi

  err "  $db looks incomplete: neither genome_db/checkv_reps.dmnd nor genome_db/checkv_reps.faa found"
  return 1
}

step_db_checkv() {
  resolve_dbs
  if [[ -n "$CHECKV_DB_DIR" ]]; then
    info "  using pre-existing CheckV DB: $CHECKV_DB_DIR"
    ensure_checkv_db_complete "$CHECKV_DB_DIR" || return 1
    return 0
  fi

  CHECKV_DB_DIR="$(find "$DB_DIR" -maxdepth 1 -type d -iname 'checkv-db-*' 2>/dev/null | sort | tail -n1)"

  if [[ -z "$CHECKV_DB_DIR" ]]; then
    info "  downloading CheckV database"
    crun "$CHECKV_ENV" checkv download_database "$DB_DIR" || return 1
    CHECKV_DB_DIR="$(find "$DB_DIR" -maxdepth 1 -type d -iname 'checkv-db-*' 2>/dev/null | sort | tail -n1)"
    [[ -n "$CHECKV_DB_DIR" ]] || { err "  CheckV DB download did not produce a checkv-db-* directory"; return 1; }
  else
    info "  found existing download at $CHECKV_DB_DIR, verifying it before reusing"
  fi

  if ! ensure_checkv_db_complete "$CHECKV_DB_DIR"; then
    warn "  $CHECKV_DB_DIR cannot be repaired locally — removing it so the next run redownloads from scratch"
    rm -rf "$CHECKV_DB_DIR"
    return 1
  fi
}

step_run_checkv() {
  resolve_dbs
  [[ -n "$CHECKV_DB_DIR" ]] || CHECKV_DB_DIR="$(find "$DB_DIR" -maxdepth 1 -type d -iname 'checkv-db-*' 2>/dev/null | sort | tail -n1)"
  [[ -n "$CHECKV_DB_DIR" && -d "$CHECKV_DB_DIR" ]] || { err "  CheckV DB not found under $DB_DIR"; return 1; }
  ensure_checkv_db_complete "$CHECKV_DB_DIR" || return 1

  rm -rf "$CHECKV_OUT"
  crun "$CHECKV_ENV" checkv end_to_end "$GENOMAD_OUT/genomad_votus.fna" "$CHECKV_OUT" -d "$CHECKV_DB_DIR" -t "$THREADS" || return 1
  [[ -s "$CHECKV_OUT/quality_summary.tsv" ]] || { err "  expected output missing: $CHECKV_OUT/quality_summary.tsv"; return 1; }
}

step_env_derep() { ensure_env "$DEREP_ENV" blast seqfu numpy; }

step_download_derep_scripts() {
  download_file "$ANICLUST_URL" "$BIN_DIR/aniclust.py" "aniclust.py" || return 1
  download_file "$ANICALC_URL" "$BIN_DIR/anicalc.py" "anicalc.py" || return 1
  chmod +x "$BIN_DIR/aniclust.py" "$BIN_DIR/anicalc.py"
}

step_run_derep() {
  local votus="$GENOMAD_OUT/genomad_votus.fna"
  rm -rf "$DEREP_OUT"
  mkdir -p "$DEREP_OUT"

  crun "$DEREP_ENV" makeblastdb -in "$votus" -dbtype nucl -out "$DEREP_OUT/votus_db" || return 1
  crun "$DEREP_ENV" blastn -query "$votus" -db "$DEREP_OUT/votus_db" \
      -outfmt '6 std qlen slen' -max_target_seqs 10000 \
      -out "$DEREP_OUT/blast.tsv" -num_threads "$THREADS" || return 1
  [[ -s "$DEREP_OUT/blast.tsv" ]] || { err "  blastn produced no hits"; return 1; }

  crun "$DEREP_ENV" python "$BIN_DIR/anicalc.py" -i "$DEREP_OUT/blast.tsv" -o "$DEREP_OUT/ani.tsv" || return 1
  crun "$DEREP_ENV" python "$BIN_DIR/aniclust.py" --fna "$votus" --ani "$DEREP_OUT/ani.tsv" \
      --out "$DEREP_OUT/clusters.tsv" --min_ani 95 --min_tcov 85 --min_qcov 0 || return 1
  [[ -s "$DEREP_OUT/clusters.tsv" ]] || { err "  aniclust.py produced no clusters"; return 1; }

  awk '{print $1}' "$DEREP_OUT/clusters.tsv" > "$DEREP_OUT/votus_representatives.txt"
  crun "$DEREP_ENV" seqfu list "$DEREP_OUT/votus_representatives.txt" "$votus" > "$DEREP_OUT/derep_votus.fasta.tmp" || {
    rm -f "$DEREP_OUT/derep_votus.fasta.tmp"; return 1;
  }
  [[ -s "$DEREP_OUT/derep_votus.fasta.tmp" ]] || { err "  seqfu list produced an empty fasta"; return 1; }
  mv "$DEREP_OUT/derep_votus.fasta.tmp" "$DEREP_OUT/derep_votus.fasta"

  local n; n=$(grep -c ">" "$DEREP_OUT/derep_votus.fasta" || true)
  info "  dereplicated to $n representative vOTUs"
}

step_env_mapping() { ensure_env "$MAPPING_ENV" minimap2 samtools coverm; }

step_mapping() {
  local votus="$DEREP_OUT/derep_votus.fasta"
  [[ -s "$votus" ]] || { err "  vOTUs fasta not found: $votus"; return 1; }
  mkdir -p "$BAM_DIR"

  local s bam
  for s in "${SAMPLES[@]}"; do
    bam="$BAM_DIR/${s}.bam"
    if [[ -s "$bam" && -s "${bam}.bai" ]]; then
      info "  $s already mapped, skipping"
      continue
    fi
    rm -f "$bam" "${bam}.bai" "${bam}.tmp.bam"
    info "  mapping $s"
    crun "$MAPPING_ENV" bash -c "set -eo pipefail; minimap2 -x sr -a -t $THREADS '$votus' '$DATA_DIR/${s}_R1.fastq.gz' '$DATA_DIR/${s}_R2.fastq.gz' | samtools view -bS -F4 - | samtools sort -@ $THREADS -o '${bam}.tmp.bam' -" || {
      rm -f "${bam}.tmp.bam"; return 1;
    }
    [[ -s "${bam}.tmp.bam" ]] || { err "  mapping of $s produced no BAM"; return 1; }
    mv "${bam}.tmp.bam" "$bam"
    crun "$MAPPING_ENV" samtools index "$bam" || return 1
    [[ -s "${bam}.bai" ]] || { err "  indexing of $bam failed"; return 1; }
  done
}

step_coverm() {
  mkdir -p "$TABLE_DIR"
  local out="$TABLE_DIR/abundance_table.tsv"
  rm -f "$out" "$out.tmp"
  crun "$MAPPING_ENV" bash -c "coverm contig -b '$BAM_DIR'/*.bam -m count mean covered_fraction tpm -o '$out.tmp' --exclude-supplementary -t $THREADS" || {
    rm -f "$out.tmp"; return 1;
  }
  [[ -s "$out.tmp" ]] || { err "  coverm produced an empty table"; return 1; }
  mv "$out.tmp" "$out"
  info "  abundance table: $out"
}

# ---------------------------------------------------------------------------
# Step runner
# ---------------------------------------------------------------------------

run_step() {
  local step="$1"
  local marker="$STATE_DIR/${step}.done"
  local log="$LOG_DIR/${step}.log"

  if [[ -f "$marker" ]]; then
    printf "%s ${c_green}[SKIP]${c_reset}  %s (already completed)\n" "$(ts)" "$step"
    STEP_STATUS+=("$step:SKIP")
    return 0
  fi

  printf "%s ${c_blue}[START]${c_reset} %s\n" "$(ts)" "$step"
  : > "$log"
  local start_ts end_ts dur rc=0
  start_ts=$(date +%s)

  "step_${step}" >>"$log" 2>&1 || rc=$?

  end_ts=$(date +%s)
  dur=$(( end_ts - start_ts ))

  if [[ $rc -eq 0 ]]; then
    date -u +"%Y-%m-%dT%H:%M:%SZ" > "$marker"
    printf "%s ${c_green}[OK]${c_reset}    %s (%ss)\n" "$(ts)" "$step" "$dur"
    STEP_STATUS+=("$step:OK:${dur}s")
  else
    printf "%s ${c_red}[FAIL]${c_reset}  %s — see %s\n" "$(ts)" "$step" "$log"
    STEP_STATUS+=("$step:FAIL")
    echo "---- last 20 lines of $log ----" >&2
    tail -n 20 "$log" >&2 || true
    echo "--------------------------------" >&2
    print_summary
    die "Step '$step' failed. Fix the issue and re-run the same command: completed steps will be skipped, this one will be redone from a clean state."
  fi
}

print_summary() {
  echo
  echo "==================== Summary ===================="
  local entry step status extra
  for entry in "${STEP_STATUS[@]:-}"; do
    [[ -z "$entry" ]] && continue
    IFS=':' read -r step status extra <<<"$entry"
    case "$status" in
      OK)   printf "  %-28s ${c_green}OK${c_reset}   (%s)\n" "$step" "$extra" ;;
      SKIP) printf "  %-28s ${c_yellow}SKIP${c_reset}\n" "$step" ;;
      FAIL) printf "  %-28s ${c_red}FAIL${c_reset}\n" "$step" ;;
    esac
  done
  echo "==================================================="
  echo "Workdir: $WORKDIR"
  echo "Logs:    $LOG_DIR"
}

trap 'echo; warn "Interrupted. Re-run the same command to resume — completed steps will be skipped, the interrupted one will be redone cleanly."; exit 130' INT TERM

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if [[ -n "$ONLY_STEP" ]]; then
  run_step "$ONLY_STEP"
else
  for step in "${STEPS_ORDER[@]}"; do
    run_step "$step"
  done
fi

print_summary
ok "All requested steps completed successfully."
echo
echo "Key outputs:"
echo "  Assembly:         $DATA_DIR/human_gut_assembly.fa.gz"
echo "  geNomad vOTUs:     $GENOMAD_OUT/genomad_votus.fna"
echo "  CheckV summary:    $CHECKV_OUT/quality_summary.tsv"
echo "  Dereplicated vOTUs: $DEREP_OUT/derep_votus.fasta"
echo "  BAM files:          $BAM_DIR/"
echo "  Abundance table:    $TABLE_DIR/abundance_table.tsv"
