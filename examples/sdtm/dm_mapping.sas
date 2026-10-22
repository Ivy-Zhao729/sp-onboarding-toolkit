/******************************************************************************
* Program:    dm_mapping.sas
* Purpose:    Map synthetic raw demographics data to SDTM DM domain
*             following CDISC SDTM IG 3.4
* Study:      CDISCPILOT01 (synthetic source data)
* Domain:     DM (Demographics)
* Input:      raw/dummy_raw_dm.csv
* Output:     DM dataset
*
* Notes:      This is a TEACHING EXAMPLE using synthetic data.
*             It demonstrates how raw CRF data maps to SDTM DM.
*             The CDISCPILOT01 study is an Alzheimer's disease trial
*             with 3 arms: Placebo, Xanomeline Low Dose, Xanomeline High Dose.
******************************************************************************/

/* ── Setup ──────────────────────────────────────────────────────────────── */
%let path = /path/to/sp-onboarding-toolkit/examples;  /* CUSTOMIZE this path */

/* ── Step 1: Read the synthetic raw CSV data ────────────────────────────── */
proc import datafile="&path./raw/dummy_raw_dm.csv"
    out=work.raw_dm
    dbms=csv
    replace;
    getnames=yes;
    guessingrows=max;
run;

/* Quick check: what did we read in? */
proc contents data=work.raw_dm varnum;
run;

proc print data=work.raw_dm (obs=5);
    title "Raw Demographics Data (first 5 rows)";
run;

/* ── Step 2: Map raw variables to SDTM DM structure ────────────────────── */
/*
   Key SDTM DM variables and their source:
   ─────────────────────────────────────────
   STUDYID   → Hardcoded from protocol (CDISCPILOT01)
   DOMAIN    → "DM"
   USUBJID   → Concatenation of STUDYID-SITEID-SUBJID
   SUBJID    → From raw SUBJID
   SITEID    → From raw SITEID
   BRTHDTC   → From raw BIRTHDT (already ISO 8601 format)
   AGE       → Derived: difference between RFSTDTC and BRTHDTC in years
   AGEU      → "YEARS" (controlled terminology)
   SEX       → From raw SEX (must match CT: M, F, U)
   RACE      → From raw RACE (must match CDISC CT)
   ETHNIC    → From raw ETHNIC (must match CDISC CT)
   ARMCD     → From raw ARMCD
   ARM       → From raw ARM
   RFSTDTC   → Reference start date = randomization date (RANDDT)
   RFENDTC   → Not available in this synthetic data
   COUNTRY   → From raw COUNTRY
*/

data work.dm;
    set work.raw_dm;

    length STUDYID $20 DOMAIN $2 USUBJID $30
           BRTHDTC $10 RFSTDTC $10
           AGEU $6 ;

    /* ── Identifiers ── */
    STUDYID = "CDISCPILOT01";
    DOMAIN  = "DM";
    USUBJID = catx("-", STUDYID, strip(put(SITEID, best.)), strip(put(SUBJID, best.)));

    /* ── Reference dates (ISO 8601 character format per SDTM) ── */
    BRTHDTC = put(input(BIRTHDT, yymmdd10.), is8601da.);
    RFSTDTC = put(input(RANDDT, yymmdd10.), is8601da.);

    /* ── Age derivation ── */
    /* Age = floor of years between birth date and reference start date */
    _birthdt_n = input(BIRTHDT, yymmdd10.);
    _rfstdt_n  = input(RANDDT, yymmdd10.);
    AGE  = floor(yrdif(_birthdt_n, _rfstdt_n, 'age'));
    AGEU = "YEARS";

    /* ── Sex: verify values match CDISC CT (M, F, U, UNDIFFERENTIATED) ── */
    /* Raw data already uses M/F — no mapping needed here */
    /* In real studies, you may need to recode, e.g., "Male" → "M" */

    /* ── Race and Ethnicity: verify against CDISC CT ── */
    /* Raw values already match CDISC CT for this synthetic data */
    /* In real studies, check for non-standard values and map accordingly */

    /* ── Keep only SDTM DM variables ── */
    keep STUDYID DOMAIN USUBJID SUBJID SITEID
         BRTHDTC AGE AGEU SEX RACE ETHNIC
         ARMCD ARM RFSTDTC COUNTRY;

    drop _birthdt_n _rfstdt_n;

    /* ── Labels (required for SDTM datasets) ── */
    label STUDYID = "Study Identifier"
          DOMAIN  = "Domain Abbreviation"
          USUBJID = "Unique Subject Identifier"
          SUBJID  = "Subject Identifier for the Study"
          SITEID  = "Study Site Identifier"
          BRTHDTC = "Date/Time of Birth"
          AGE     = "Age"
          AGEU    = "Age Units"
          SEX     = "Sex"
          RACE    = "Race"
          ETHNIC  = "Ethnicity"
          ARMCD   = "Planned Arm Code"
          ARM     = "Description of Planned Arm"
          RFSTDTC = "Subject Reference Start Date/Time"
          COUNTRY = "Country";
run;

/* ── Step 3: Sort per SDTM IG sort order for DM ────────────────────────── */
proc sort data=work.dm out=work.dm_final;
    by STUDYID USUBJID;
run;

/* ── Step 4: Review the output ──────────────────────────────────────────── */
proc contents data=work.dm_final varnum;
    title "SDTM DM Domain - Variable Listing";
run;

proc print data=work.dm_final;
    title "SDTM DM Domain - All Records";
run;

/* ── Step 5: Basic validation checks ────────────────────────────────────── */

/* Check 1: No duplicate USUBJID (DM should have 1 row per subject) */
proc sql;
    title "Check: Duplicate USUBJIDs (should be 0 rows)";
    select USUBJID, count(*) as count
    from work.dm_final
    group by USUBJID
    having count(*) > 1;
quit;

/* Check 2: No missing required variables */
proc sql;
    title "Check: Missing Required Variables (should be 0 rows)";
    select USUBJID, STUDYID, DOMAIN, SEX, RACE
    from work.dm_final
    where missing(USUBJID) or missing(STUDYID) or missing(DOMAIN)
          or missing(SEX) or missing(RACE);
quit;

/* Check 3: Age reasonableness */
proc means data=work.dm_final n mean std min max;
    var AGE;
    title "Check: Age Distribution (Alzheimer's study — expect older adults)";
run;

/*
   ═══════════════════════════════════════════════════════════════
   NEXT STEPS (in a real study):
   1. Run Pinnacle 21 (P21) to validate CDISC compliance
   2. Compare against the annotated CRF to verify all mappings
   3. Check controlled terminology against the latest CT package
   4. Export as .xpt (SAS transport) for submission:
      libname xpt xport "/path/to/output/dm.xpt";
      data xpt.dm; set work.dm_final; run;
   ═══════════════════════════════════════════════════════════════
*/
