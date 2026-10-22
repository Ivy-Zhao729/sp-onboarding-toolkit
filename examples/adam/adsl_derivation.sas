/******************************************************************************
* Program:    adsl_derivation.sas
* Purpose:    Derive ADSL (Subject-Level Analysis Dataset) from SDTM
*             following CDISC ADaM IG 1.3
* Study:      CDISCPILOT01
* Dataset:    ADSL
* Input:      SDTM DM, DS, EX, SV domains (from CDISCPILOT01)
* Output:     ADSL dataset
*
* Notes:      This is a TEACHING EXAMPLE using CDISCPILOT01 public data.
*             It demonstrates key ADSL derivations that every new SP
*             needs to understand. Download CDISCPILOT01 SDTM data from:
*             https://github.com/cdisc-org/sdtm-adam-pilot-project
******************************************************************************/

/* ── Setup ──────────────────────────────────────────────────────────────── */
%let sdtm_path = /path/to/cdiscpilot01/sdtm;  /* CUSTOMIZE: path to SDTM .xpt files */

libname sdtm xport "&sdtm_path" access=readonly;
/* Or if using SAS datasets: libname sdtm "&sdtm_path"; */

/* ══════════════════════════════════════════════════════════════════════════
   SECTION 1: READ SOURCE SDTM DATA
   ══════════════════════════════════════════════════════════════════════════ */

/* ── DM: Demographics (one row per subject — the backbone of ADSL) ────── */
data work.dm;
    set sdtm.dm;
    keep STUDYID USUBJID SUBJID SITEID BRTHDTC AGE AGEU SEX RACE ETHNIC
         ARM ARMCD RFSTDTC RFENDTC COUNTRY;
run;

/* ── EX: Exposure (to derive first/last treatment date) ───────────────── */
data work.ex;
    set sdtm.ex;
    keep STUDYID USUBJID EXSTDTC EXENDTC EXTRT EXDOSE;
run;

/* ── DS: Disposition (to derive completion status and reason) ─────────── */
data work.ds;
    set sdtm.ds;
    keep STUDYID USUBJID DSDECOD DSTERM DSSTDTC DSCAT;
run;

/* ══════════════════════════════════════════════════════════════════════════
   SECTION 2: DERIVE TREATMENT DATES
   ──────────────────────────────────────────────────────────────────────────
   TRTSDT = Date of first exposure (first non-missing EXSTDTC)
   TRTEDT = Date of last exposure (last non-missing EXENDTC)

   WHY THIS MATTERS: Treatment dates anchor almost every time-based
   derivation in ADaM — study day, treatment duration, treatment-emergent
   flags, and on-treatment windows all depend on these dates.
   ══════════════════════════════════════════════════════════════════════════ */

proc sql;
    create table work.trt_dates as
    select STUDYID,
           USUBJID,
           min(input(substr(EXSTDTC, 1, 10), yymmdd10.)) as TRTSDT format=date9.
               label="Date of First Exposure to Treatment",
           max(input(substr(coalesce(EXENDTC, EXSTDTC), 1, 10), yymmdd10.)) as TRTEDT format=date9.
               label="Date of Last Exposure to Treatment"
    from work.ex
    where EXDOSE > 0  /* Only count actual dosing, not zero-dose records */
    group by STUDYID, USUBJID;
quit;

/* ══════════════════════════════════════════════════════════════════════════
   SECTION 3: DERIVE DISPOSITION VARIABLES
   ──────────────────────────────────────────────────────────────────────────
   DCSREAS = Reason for discontinuation from study
   COMP24FL = Completed Week 24 flag

   WHY THIS MATTERS: Regulatory reviewers look at disposition closely.
   Who completed? Who dropped out and why? These flags drive the
   population flow diagram (Figure 14.1 in most CSRs).
   ══════════════════════════════════════════════════════════════════════════ */

/* Get completion status: did the subject complete the study? */
data work.ds_comp;
    set work.ds;
    where DSCAT = "DISPOSITION EVENT" and DSDECOD ^= "";

    length DCSREAS $50;

    if DSDECOD = "COMPLETED" then do;
        COMP24FL = "Y";
        DCSREAS  = "";
    end;
    else do;
        COMP24FL = "N";
        DCSREAS  = DSDECOD;
    end;

    keep STUDYID USUBJID COMP24FL DCSREAS;
run;

/* ══════════════════════════════════════════════════════════════════════════
   SECTION 4: BUILD ADSL
   ──────────────────────────────────────────────────────────────────────────
   Merge everything together, derive remaining variables, and assign
   population flags.
   ══════════════════════════════════════════════════════════════════════════ */

proc sort data=work.dm;       by STUDYID USUBJID; run;
proc sort data=work.trt_dates; by STUDYID USUBJID; run;
proc sort data=work.ds_comp;   by STUDYID USUBJID; run;

data work.adsl;
    merge work.dm       (in=a)
          work.trt_dates (in=b)
          work.ds_comp   (in=c);
    by STUDYID USUBJID;
    if a;  /* Keep all DM subjects — some may not have EX or DS records */

    /* ── Planned and Actual Treatment ── */
    /*
       TRT01P  = Planned treatment (from DM.ARM)
       TRT01A  = Actual treatment (same as planned unless crossover/deviation)
       TRT01PN/TRT01AN = Numeric versions for programming
    */
    length TRT01P TRT01A $40;
    TRT01P = ARM;
    TRT01A = ARM;  /* In this study, actual = planned */

    if ARM = "Placebo"                then TRT01PN = 1;
    else if ARM = "Xanomeline Low Dose"  then TRT01PN = 2;
    else if ARM = "Xanomeline High Dose" then TRT01PN = 3;
    TRT01AN = TRT01PN;

    /* ── Age group (per SAP) ── */
    /*
       WHY WE DERIVE THIS: Summary tables often present results by age group.
       The cut points come from the SAP — never hardcode age groups without
       checking the SAP first.
    */
    length AGEGR1 $10;
    if      AGE < 65 then do; AGEGR1 = "<65";    AGEGR1N = 1; end;
    else if AGE <= 80 then do; AGEGR1 = "65-80";  AGEGR1N = 2; end;
    else                   do; AGEGR1 = ">80";    AGEGR1N = 3; end;

    /* ── Treatment duration (days) ── */
    if nmiss(TRTSDT, TRTEDT) = 0 then
        TRTDUR = TRTEDT - TRTSDT + 1;

    /* ── Population flags ── */
    /*
       WHY THESE MATTER: Every analysis table is run on a specific population.
       Getting these wrong means wrong denominators everywhere.

       ITTFL  = Intent-to-Treat: all randomized subjects
       SAFFL  = Safety: all subjects who received at least one dose
       EFFFL  = Efficacy: typically ITT with at least one post-baseline assessment
    */
    length ITTFL SAFFL $1;

    /* ITT: all randomized subjects (everyone in DM with an ARM) */
    if ARM ^= "" then ITTFL = "Y";
    else ITTFL = "N";

    /* Safety: must have received at least one dose (have a TRTSDT) */
    if TRTSDT ^= . then SAFFL = "Y";
    else SAFFL = "N";

    /* ── Labels ── */
    label TRT01P  = "Planned Treatment for Period 01"
          TRT01A  = "Actual Treatment for Period 01"
          TRT01PN = "Planned Treatment for Period 01 (N)"
          TRT01AN = "Actual Treatment for Period 01 (N)"
          AGEGR1  = "Pooled Age Group 1"
          AGEGR1N = "Pooled Age Group 1 (N)"
          TRTDUR  = "Treatment Duration (days)"
          ITTFL   = "Intent-To-Treat Population Flag"
          SAFFL   = "Safety Population Flag"
          COMP24FL = "Completed Week 24"
          DCSREAS  = "Reason for Discontinuation from Study";
run;

/* ── Final sort ─────────────────────────────────────────────────────────── */
proc sort data=work.adsl out=work.adsl_final;
    by STUDYID USUBJID;
run;

/* ══════════════════════════════════════════════════════════════════════════
   SECTION 5: VALIDATION CHECKS
   ══════════════════════════════════════════════════════════════════════════ */

/* Check 1: One row per subject */
proc sql;
    title "Check: Duplicate USUBJID in ADSL (should be 0 rows)";
    select USUBJID, count(*) as count
    from work.adsl_final
    group by USUBJID
    having count(*) > 1;
quit;

/* Check 2: Population flag counts */
proc freq data=work.adsl_final;
    tables ITTFL SAFFL COMP24FL / missing;
    title "Check: Population Flag Distributions";
run;

/* Check 3: Treatment group balance */
proc freq data=work.adsl_final;
    tables TRT01P * TRT01A / missing;
    title "Check: Planned vs Actual Treatment (should match in this study)";
run;

/* Check 4: Treatment date logic */
proc sql;
    title "Check: TRTEDT before TRTSDT (should be 0 rows)";
    select USUBJID, TRTSDT, TRTEDT
    from work.adsl_final
    where TRTEDT < TRTSDT;
quit;

/* Check 5: Key variable distributions */
proc means data=work.adsl_final n nmiss mean std min max;
    var AGE TRTDUR;
    title "Check: Age and Treatment Duration Summary";
run;

/*
   ═══════════════════════════════════════════════════════════════
   NEXT STEPS (in a real study):
   1. Compare against QC programmer's independent ADSL
      proc compare base=work.adsl_final compare=qc.adsl listall;
          id STUDYID USUBJID;
      run;
   2. Verify population counts match the randomization list
   3. Check all derivations against the ADaM spec
   4. Run Pinnacle 21 ADaM validation
   ═══════════════════════════════════════════════════════════════
*/
