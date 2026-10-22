/******************************************************************************
* Program:    _template_sdtm.sas
* Purpose:    SDTM domain creation template — replace with your company's
*             standard program header and structure
* Study:      <!-- CUSTOMIZE: Insert study ID -->
* Domain:     <!-- CUSTOMIZE: Insert domain name (e.g., DM, AE, VS) -->
* Input:      <!-- CUSTOMIZE: Source dataset(s) -->
* Output:     <!-- CUSTOMIZE: Target SDTM dataset -->
* Author:     <!-- CUSTOMIZE: Your name -->
* Date:       <!-- CUSTOMIZE: Date created -->
*
* Modification History:
* Date        Author      Description
* ---------   --------    ------------------------------------------------
*
******************************************************************************/

/* ── CUSTOMIZE: Set your libnames ───────────────────────────────────────── */
libname raw    "<!-- path to raw/source data -->";
libname sdtm   "<!-- path to SDTM output -->";

/* ── Step 1: Read source data ───────────────────────────────────────────── */
data work.source;
    set raw.<!-- source dataset name -->;
    /* CUSTOMIZE: Add any initial subsetting or renaming here */
run;

/* ── Step 2: Map to SDTM structure ──────────────────────────────────────── */
data work.domain;
    set work.source;

    /* Required identifiers */
    STUDYID  = "<!-- CUSTOMIZE: Study ID -->";
    DOMAIN   = "<!-- CUSTOMIZE: Domain code -->";
    USUBJID  = catx("-", STUDYID, SITEID, SUBJID);

    /* CUSTOMIZE: Map your source variables to SDTM target variables below */
    /* Example:
       VSTEST   = "Systolic Blood Pressure";
       VSTESTCD = "SYSBP";
       VSORRES  = put(raw_sbp, best.);
       VSORRESU = "mmHg";
    */

    /* CUSTOMIZE: Apply controlled terminology as needed */

    keep STUDYID DOMAIN USUBJID /* CUSTOMIZE: add all required and expected variables */;
run;

/* ── Step 3: Sort and output ────────────────────────────────────────────── */
proc sort data=work.domain out=sdtm.<!-- domain name -->;
    by STUDYID USUBJID /* CUSTOMIZE: add sort keys per IG */;
run;

/* ── Step 4: Validate ───────────────────────────────────────────────────── */
/* Run Pinnacle 21 and review any issues before QC */
proc contents data=sdtm.<!-- domain name -->;
run;
