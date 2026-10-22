/******************************************************************************
* Program:    _template_adam.sas
* Purpose:    ADaM dataset creation template — replace with your company's
*             standard program header and structure
* Study:      <!-- CUSTOMIZE: Insert study ID -->
* Dataset:    <!-- CUSTOMIZE: Insert ADaM dataset name (e.g., ADSL, ADVS) -->
* Input:      <!-- CUSTOMIZE: Source SDTM/ADaM dataset(s) -->
* Output:     <!-- CUSTOMIZE: Target ADaM dataset -->
* Author:     <!-- CUSTOMIZE: Your name -->
* Date:       <!-- CUSTOMIZE: Date created -->
*
* Modification History:
* Date        Author      Description
* ---------   --------    ------------------------------------------------
*
******************************************************************************/

/* ── CUSTOMIZE: Set your libnames ───────────────────────────────────────── */
libname sdtm   "<!-- path to SDTM data -->";
libname adam   "<!-- path to ADaM output -->";

/* ── Step 1: Get ADSL for population flags and treatment info ───────────── */
data work.adsl;
    set adam.adsl;
    keep STUDYID USUBJID SUBJID SITEID TRT01P TRT01PN TRT01A TRT01AN
         TRTSDT TRTEDT AGE AGEGR1 AGEGR1N SEX RACE SAFFL ITTFL;
run;

/* ── Step 2: Read source SDTM data ──────────────────────────────────────── */
data work.source;
    set sdtm.<!-- source SDTM domain -->;
    /* CUSTOMIZE: Subset and initial processing */
run;

/* ── Step 3: Derive analysis variables ──────────────────────────────────── */
data work.ady;
    merge work.source (in=a)
          work.adsl   (in=b);
    by STUDYID USUBJID;
    if a and b;

    /* CUSTOMIZE: Analysis date — convert character SDTM date to numeric */
    /* ADT = input(substr(xxDTC, 1, 10), yymmdd10.); */
    /* format ADT date9.; */

    /* CUSTOMIZE: Analysis day */
    /* if nmiss(ADT, TRTSDT) = 0 then
         ADY = ADT - TRTSDT + (ADT >= TRTSDT); */
run;

/* ── Step 4: Derive baseline and change from baseline ───────────────────── */
/*
   CUSTOMIZE: Baseline definition per SAP
   Common approaches:
   - Last non-missing value on or before TRTSDT
   - Value at screening visit
   - Average of multiple pre-treatment values
*/

/* ── Step 5: Derive analysis visit (AVISIT/AVISITN) ────────────────────── */
/*
   CUSTOMIZE: Visit windowing per ADaM spec
   - Map ADY to analysis visit windows
   - Handle multiple records per window (closest to target day)
*/

/* ── Step 6: Apply population flags and subset ──────────────────────────── */
data work.final;
    set work.ady;
    /* CUSTOMIZE: Apply population flags from ADSL
       e.g., where SAFFL = "Y" for safety analysis datasets */
run;

/* ── Step 7: Sort and output ────────────────────────────────────────────── */
proc sort data=work.final out=adam.<!-- ADaM dataset name -->;
    by STUDYID USUBJID /* CUSTOMIZE: add sort keys per spec */;
run;

/* ── Step 8: Validate ───────────────────────────────────────────────────── */
proc contents data=adam.<!-- ADaM dataset name -->;
run;

proc compare base=adam.<!-- ADaM dataset name --> compare=<!-- QC dataset --> listall;
    id STUDYID USUBJID /* CUSTOMIZE: add key variables */;
run;
