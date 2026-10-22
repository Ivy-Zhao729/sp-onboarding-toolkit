# =============================================================================
# Program:    dm_mapping.R
# Purpose:    Map synthetic raw demographics data to SDTM DM domain
#             following CDISC SDTM IG 3.4
# Study:      CDISCPILOT01 (synthetic source data)
# Domain:     DM (Demographics)
# Input:      raw/dummy_raw_dm.csv
# Output:     DM dataset
#
# Notes:      This is a TEACHING EXAMPLE using synthetic data.
#             It demonstrates how raw CRF data maps to SDTM DM.
# =============================================================================

library(dplyr)
library(readr)
library(lubridate)
library(haven)       # For writing .xpt transport files

# ── Step 1: Read the synthetic raw CSV data ──────────────────────────────────

raw_dm <- read_csv("examples/raw/dummy_raw_dm.csv",
                    show_col_types = FALSE)

# Quick check: what did we read in?
glimpse(raw_dm)

# ── Step 2: Map raw variables to SDTM DM structure ──────────────────────────
#
#   Key SDTM DM variables and their source:
#   ─────────────────────────────────────────
#   STUDYID   → Hardcoded from protocol (CDISCPILOT01)
#   DOMAIN    → "DM"
#   USUBJID   → Concatenation of STUDYID-SITEID-SUBJID
#   BRTHDTC   → From raw BIRTHDT (ISO 8601 character)
#   AGE       → Derived: years between BRTHDTC and RFSTDTC
#   AGEU      → "YEARS"
#   SEX       → From raw SEX (must match CDISC CT: M, F)
#   RACE      → From raw RACE (must match CDISC CT)
#   ETHNIC    → From raw ETHNIC (must match CDISC CT)
#   ARMCD     → From raw ARMCD
#   ARM       → From raw ARM
#   RFSTDTC   → Reference start date = randomization date
#   COUNTRY   → From raw COUNTRY

dm <- raw_dm |>
  mutate(
    # ── Identifiers ──
    STUDYID = "CDISCPILOT01",
    DOMAIN  = "DM",
    USUBJID = paste(STUDYID, SITEID, SUBJID, sep = "-"),

    # ── Reference dates (ISO 8601 character format per SDTM) ──
    BRTHDTC = as.character(as.Date(BIRTHDT)),
    RFSTDTC = as.character(as.Date(RANDDT)),

    # ── Age derivation ──
    # Age = floor of years between birth date and reference start date
    AGE  = floor(as.numeric(difftime(as.Date(RANDDT), as.Date(BIRTHDT),
                                      units = "days")) / 365.25),
    AGEU = "YEARS",

    # ── Sex: raw data already uses M/F matching CDISC CT ──
    SEX = SEX,

    # ── Race and Ethnicity: raw values already match CDISC CT ──
    RACE   = RACE,
    ETHNIC = ETHNIC,

    # ── Treatment arm ──
    ARMCD   = ARMCD,
    ARM     = ARM,

    # ── Country ──
    COUNTRY = COUNTRY
  ) |>

  # ── Keep only SDTM DM variables ──
  select(STUDYID, DOMAIN, USUBJID, SUBJID, SITEID,
         BRTHDTC, AGE, AGEU, SEX, RACE, ETHNIC,
         ARMCD, ARM, RFSTDTC, COUNTRY)

# ── Step 3: Sort per SDTM IG sort order for DM ──────────────────────────────

dm_final <- dm |>
  arrange(STUDYID, USUBJID)

# ── Step 4: Add variable labels (required for SDTM) ─────────────────────────

attr(dm_final$STUDYID, "label") <- "Study Identifier"
attr(dm_final$DOMAIN,  "label") <- "Domain Abbreviation"
attr(dm_final$USUBJID, "label") <- "Unique Subject Identifier"
attr(dm_final$SUBJID,  "label") <- "Subject Identifier for the Study"
attr(dm_final$SITEID,  "label") <- "Study Site Identifier"
attr(dm_final$BRTHDTC, "label") <- "Date/Time of Birth"
attr(dm_final$AGE,     "label") <- "Age"
attr(dm_final$AGEU,    "label") <- "Age Units"
attr(dm_final$SEX,     "label") <- "Sex"
attr(dm_final$RACE,    "label") <- "Race"
attr(dm_final$ETHNIC,  "label") <- "Ethnicity"
attr(dm_final$ARMCD,   "label") <- "Planned Arm Code"
attr(dm_final$ARM,     "label") <- "Description of Planned Arm"
attr(dm_final$RFSTDTC, "label") <- "Subject Reference Start Date/Time"
attr(dm_final$COUNTRY, "label") <- "Country"

# ── Step 5: Review the output ────────────────────────────────────────────────

print(dm_final)
str(dm_final)

# ── Step 6: Basic validation checks ─────────────────────────────────────────

# Check 1: No duplicate USUBJID (DM should have 1 row per subject)
dup_check <- dm_final |>
  count(USUBJID) |>
  filter(n > 1)
cat("Duplicate USUBJIDs (should be 0):", nrow(dup_check), "\n")

# Check 2: No missing required variables
missing_check <- dm_final |>
  filter(is.na(USUBJID) | is.na(STUDYID) | is.na(DOMAIN) |
         is.na(SEX) | is.na(RACE))
cat("Records with missing required vars (should be 0):", nrow(missing_check), "\n")

# Check 3: Age reasonableness (Alzheimer's study — expect older adults)
cat("\nAge distribution:\n")
summary(dm_final$AGE)

# ── Step 7 (optional): Export as .xpt for submission ─────────────────────────
#
# write_xpt(dm_final, path = "output/dm.xpt", version = 5)
#
# ═══════════════════════════════════════════════════════════════
# NEXT STEPS (in a real study):
# 1. Run Pinnacle 21 (P21) to validate CDISC compliance
# 2. Compare against the annotated CRF to verify all mappings
# 3. Check controlled terminology against the latest CT package
# 4. Use diffdf::diffdf() to compare against QC dataset
# ═══════════════════════════════════════════════════════════════
