# =============================================================================
# Program:    adsl_derivation.R
# Purpose:    Derive ADSL (Subject-Level Analysis Dataset) from SDTM
#             following CDISC ADaM IG 1.3
# Study:      CDISCPILOT01
# Dataset:    ADSL
# Input:      SDTM DM, DS, EX domains (from CDISCPILOT01)
# Output:     ADSL dataset
#
# Notes:      This is a TEACHING EXAMPLE using CDISCPILOT01 public data.
#             Download CDISCPILOT01 SDTM data from:
#             https://github.com/cdisc-org/sdtm-adam-pilot-project
#
#             This example uses admiral (pharmaverse) where possible to
#             show the modern R approach to ADaM derivation.
# =============================================================================

library(dplyr)
library(lubridate)
library(haven)       # For reading .xpt files
library(admiral)     # pharmaverse: ADaM derivation functions
library(stringr)

# ── Step 1: Read source SDTM data ───────────────────────────────────────────

sdtm_path <- "path/to/cdiscpilot01/sdtm"  # CUSTOMIZE this path

dm <- read_xpt(file.path(sdtm_path, "dm.xpt"))
ex <- read_xpt(file.path(sdtm_path, "ex.xpt"))
ds <- read_xpt(file.path(sdtm_path, "ds.xpt"))

# Quick look at what we're working with
glimpse(dm)

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 2: DERIVE TREATMENT DATES
# ──────────────────────────────────────────────────────────────────────────────
# TRTSDT = Date of first exposure
# TRTEDT = Date of last exposure
#
# WHY THIS MATTERS: Treatment dates anchor almost every time-based
# derivation in ADaM — study day, treatment duration, treatment-emergent
# flags, and on-treatment windows all depend on these dates.
# ══════════════════════════════════════════════════════════════════════════════

ex_dates <- ex |>
  filter(EXDOSE > 0) |>
  mutate(
    EXSTDT = as.Date(str_sub(EXSTDTC, 1, 10)),
    EXENDT = as.Date(str_sub(coalesce(EXENDTC, EXSTDTC), 1, 10))
  ) |>
  group_by(STUDYID, USUBJID) |>
  summarise(
    TRTSDT = min(EXSTDT, na.rm = TRUE),
    TRTEDT = max(EXENDT, na.rm = TRUE),
    .groups = "drop"
  )

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 3: DERIVE DISPOSITION VARIABLES
# ──────────────────────────────────────────────────────────────────────────────
# DCSREAS  = Reason for discontinuation
# COMP24FL = Completed Week 24 flag
#
# WHY THIS MATTERS: Regulatory reviewers look at disposition closely.
# These flags drive the population flow diagram.
# ══════════════════════════════════════════════════════════════════════════════

ds_comp <- ds |>
  filter(DSCAT == "DISPOSITION EVENT", DSDECOD != "") |>
  mutate(
    COMP24FL = if_else(DSDECOD == "COMPLETED", "Y", "N"),
    DCSREAS  = if_else(DSDECOD == "COMPLETED", NA_character_, DSDECOD)
  ) |>
  select(STUDYID, USUBJID, COMP24FL, DCSREAS)

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 4: BUILD ADSL
# ══════════════════════════════════════════════════════════════════════════════

adsl <- dm |>
  select(STUDYID, USUBJID, SUBJID, SITEID, BRTHDTC,
         AGE, AGEU, SEX, RACE, ETHNIC, ARM, ARMCD,
         RFSTDTC, RFENDTC, COUNTRY) |>

  # ── Merge treatment dates ──
  left_join(ex_dates, by = c("STUDYID", "USUBJID")) |>

  # ── Merge disposition ──
  left_join(ds_comp, by = c("STUDYID", "USUBJID")) |>

  mutate(
    # ── Planned and Actual Treatment ──
    TRT01P  = ARM,
    TRT01A  = ARM,
    TRT01PN = case_when(
      ARM == "Placebo"                ~ 1,
      ARM == "Xanomeline Low Dose"    ~ 2,
      ARM == "Xanomeline High Dose"   ~ 3
    ),
    TRT01AN = TRT01PN,

    # ── Age group (per SAP) ──
    # The cut points come from the SAP — never hardcode without checking
    AGEGR1 = case_when(
      AGE < 65  ~ "<65",
      AGE <= 80 ~ "65-80",
      AGE > 80  ~ ">80"
    ),
    AGEGR1N = case_when(
      AGE < 65  ~ 1,
      AGE <= 80 ~ 2,
      AGE > 80  ~ 3
    ),

    # ── Treatment duration (days) ──
    TRTDUR = as.numeric(TRTEDT - TRTSDT) + 1,

    # ── Population flags ──
    # ITTFL: all randomized subjects (everyone in DM with an ARM)
    ITTFL = if_else(!is.na(ARM) & ARM != "", "Y", "N"),

    # SAFFL: received at least one dose (have a TRTSDT)
    SAFFL = if_else(!is.na(TRTSDT), "Y", "N")
  )

# ── Add variable labels ─────────────────────────────────────────────────────

adsl_final <- adsl |>
  arrange(STUDYID, USUBJID)

attr(adsl_final$TRT01P,   "label") <- "Planned Treatment for Period 01"
attr(adsl_final$TRT01A,   "label") <- "Actual Treatment for Period 01"
attr(adsl_final$TRT01PN,  "label") <- "Planned Treatment for Period 01 (N)"
attr(adsl_final$TRT01AN,  "label") <- "Actual Treatment for Period 01 (N)"
attr(adsl_final$AGEGR1,   "label") <- "Pooled Age Group 1"
attr(adsl_final$AGEGR1N,  "label") <- "Pooled Age Group 1 (N)"
attr(adsl_final$TRTDUR,   "label") <- "Treatment Duration (days)"
attr(adsl_final$ITTFL,    "label") <- "Intent-To-Treat Population Flag"
attr(adsl_final$SAFFL,    "label") <- "Safety Population Flag"
attr(adsl_final$COMP24FL, "label") <- "Completed Week 24"
attr(adsl_final$DCSREAS,  "label") <- "Reason for Discontinuation from Study"
attr(adsl_final$TRTSDT,   "label") <- "Date of First Exposure to Treatment"
attr(adsl_final$TRTEDT,   "label") <- "Date of Last Exposure to Treatment"

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 5: VALIDATION CHECKS
# ══════════════════════════════════════════════════════════════════════════════

# Check 1: One row per subject
dup_check <- adsl_final |> count(USUBJID) |> filter(n > 1)
cat("Duplicate USUBJIDs (should be 0):", nrow(dup_check), "\n")

# Check 2: Population flag counts
cat("\nPopulation flags:\n")
adsl_final |> count(ITTFL) |> print()
adsl_final |> count(SAFFL) |> print()
adsl_final |> count(COMP24FL) |> print()

# Check 3: Treatment group balance
cat("\nPlanned vs Actual Treatment:\n")
adsl_final |> count(TRT01P, TRT01A) |> print()

# Check 4: Treatment date logic
date_issues <- adsl_final |> filter(TRTEDT < TRTSDT)
cat("\nTRTEDT before TRTSDT (should be 0):", nrow(date_issues), "\n")

# Check 5: Key variable distributions
cat("\nAge summary:\n")
summary(adsl_final$AGE)
cat("\nTreatment duration summary:\n")
summary(adsl_final$TRTDUR)

# ── Optional: Export as .xpt ─────────────────────────────────────────────────
# write_xpt(adsl_final, path = "output/adsl.xpt", version = 5)

# ══════════════════════════════════════════════════════════════════════════════
# NEXT STEPS (in a real study):
# 1. Compare against QC programmer's independent ADSL:
#    diffdf::diffdf(adsl_final, qc_adsl, keys = c("STUDYID", "USUBJID"))
# 2. Verify population counts match the randomization list
# 3. Check all derivations against the ADaM spec
# 4. Run Pinnacle 21 ADaM validation
# ══════════════════════════════════════════════════════════════════════════════
