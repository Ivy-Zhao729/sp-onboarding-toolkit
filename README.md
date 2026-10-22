# SP Onboarding Toolkit: A "Just-in-Time" Utility Belt for New Statistical Programmers

## What Is This?

This is a **forkable template repository** designed to help new Statistical Programmers (SPs) get productive faster in clinical trial programming. Instead of replacing traditional training, it works alongside your daily work as a live reference — like having a senior SP available whenever you need a quick answer.

It pairs with **Claude** (the AI assistant in VS Code / Posit) to give you guided, context-aware help for SDTM mapping, ADaM derivations, TFL formatting, PK/PD programming, and Git workflows.

## Who Is This For?

- **New SPs** (0–2 years experience) who are working on clinical studies and want to solve problems independently without always waiting for a senior mentor
- **Senior SPs and leads** who want to reduce repetitive onboarding questions and give their new hires a structured self-service resource
- **Any organization** that wants to accelerate the ramp-up time for junior clinical programmers

## What's Inside?

```
sp-onboarding-toolkit/
│
├── CLAUDE.md                  → AI behavior rules — makes Claude act as a senior SP mentor
├── prompt_playbook.md         → 8 ready-to-use prompt templates for daily tasks
├── git_cheatsheet.md          → Plain-English guide for common Git scenarios
├── README.md                  → You are here
│
├── examples/                  → Working code using public CDISCPILOT01 data
│   ├── raw/                   → Synthetic source data for SDTM mapping demos
│   ├── sdtm/                  → SDTM mapping examples (SAS + R)
│   ├── adam/                  → ADaM derivation examples (SAS + R)
│   └── tfl/                   → Table/Figure/Listing examples (SAS + R)
│
├── templates/                 → Skeleton programs with CUSTOMIZE markers
│   ├── sdtm/                  → SDTM program template
│   ├── adam/                  → ADaM program template
│   ├── tfl/                   → TFL program template
│   └── macros/                → Macro template
│
└── standards/                 → Reference specifications and standards templates
```

## How to Use This

### If you're a new SP
1. Clone this repo into your VS Code / Posit workspace
2. Make sure you have the Claude extension installed
3. The `CLAUDE.md` file automatically configures Claude to act as your senior SP mentor
4. Open `prompt_playbook.md` when you need help — copy a prompt, fill in your details, paste into Claude
5. Open `git_cheatsheet.md` when Git gets confusing
6. Explore the `examples/` folder to see working clinical programs you can learn from

### If you're a lead setting this up for your team
1. **Fork** this repository to your company's GitHub/GitLab
2. Customize `CLAUDE.md` — fill in the company-specific sections (your SOPs, macro library, folder structure, branching strategy)
3. Replace the template programs in `templates/` with your company's actual skeletons
4. Add your company's specifications to `standards/`
5. Share the internal fork with new hires on their first day

## About the Example Data

All working examples use the **CDISCPILOT01** study — a publicly available, de-identified Alzheimer's disease trial provided by CDISC. This includes SDTM datasets, ADaM datasets, a study protocol, SAP, and define.xml files.

- Download from: [CDISC GitHub](https://github.com/cdisc-org/sdtm-adam-pilot-project)
- No proprietary or patient data is used anywhere in this repository

Synthetic source data in `examples/raw/` was created specifically for this toolkit to demonstrate SDTM mapping workflows.

## What This Is NOT

- **Not a replacement for formal training.** You still need to learn CDISC standards, your company's SOPs, and clinical programming fundamentals.
- **Not a substitute for QC.** All code — whether written by you or suggested by AI — must go through your organization's standard quality control process.
- **Not a source of truth for CDISC standards.** Always verify against the official Implementation Guides and your study specifications.

## Customization Guide

Every file with `<!-- CUSTOMIZE -->` markers is designed to be replaced with your organization's specifics. Key areas to customize:

| File | What to customize |
|---|---|
| `CLAUDE.md` | Company standards, macro library, folder structure, branching strategy |
| `templates/` | Replace with your program skeletons and headers |
| `standards/` | Add your specification templates |
| `git_cheatsheet.md` | Branch naming conventions, if yours differ |

## Contributing

This toolkit was created as part of a PharmaSUG presentation. Contributions, suggestions, and improvements are welcome — open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

- CDISC for the publicly available CDISCPILOT01 pilot study data
- The pharmaverse community for open-source clinical programming tools
