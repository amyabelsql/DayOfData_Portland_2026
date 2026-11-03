
The repo follows the talk. Every demo is a numbered folder. Every folder has a README that explains the idea and one command that shows it off. The slides use the same numbers, so "DEMO 05" on screen means the `05_Containers` folder.

---

## The flow

| Step folder | Slide | The big idea | Run this | What the room sees |
|---|---|---|---|---|
| `00_Prerequisites` | Set up your repo | Get set up once | `./00_Prerequisites/run.ps1` | Nothing. This is your setup |
| `01_FirstWorkflow` | Your first GitHub workflow | A workflow is just a file | `./01_FirstWorkflow/run.ps1` | A workflow starts, runs, and reports back |
| `02_SSMS` | Use GitHub from SSMS | Your scripts are code | `./02_SSMS/run.ps1` | A change made in SSMS turns into a pull request |
| `03_DocsWikiMermaid` | Docs and diagrams in a wiki | Docs and diagrams are text | `./03_DocsWikiMermaid/run.ps1` | A full DBA team wiki with a diagram on every page, published in seconds |
| `04_TemplatesIssuesBoard` | Issue forms and a project board | Busy work runs itself | `./04_TemplatesIssuesBoard/run.ps1` | Issues and a project board that fill in on their own |
| `05_Containers` | Test every change in a SQL Server container | Every change gets tested | `./05_Containers/run.ps1` | SQL Server starts, the tests run, then it's gone |
| `06_CopilotAndPRs` | Copilot and pull requests that run themselves | The pull request does the chores | `./06_CopilotAndPRs/run.ps1` | A pull request that labels, reviews, and merges itself |
| `07_Guardrails` | Guardrails for safe workflows | Automation needs a safety net | `./07_Guardrails/run.ps1` | A checker that grades workflows, and a job that files its own bug |
| `99_Cleanup` | After the talk | Reset for next time | `./99_Cleanup/run.ps1` | Nothing. The repo goes back to clean |

Run every command with `pwsh` from the repo root.

---

## Part 1. Instructions for Claude

### Ask me first

1. My GitHub username.
2. The repo name. Default is `github-automation-chaos`.
3. Public or private. Default is public, so the audience can fork it.

### Ground rules

1. **Small and readable.** Someone who knows SQL Server should be able to read any one step folder in five minutes.
2. **One command per step.** Each `run.ps1` does the whole show for that step from the repo root.
    - It is safe to run twice.
    - It never needs me to edit a file first.
3. **The scripts explain themselves.** Before each action, `run.ps1` prints one plain sentence about what it's about to do and why.
    - Tag each action `[R]` for read only or `[W]` for anything that changes something.
    - Use color: green for success, yellow for "watch this", red for failure.
    - Add a `-Pause` switch that waits for Enter between actions, so I can talk while it runs.
4. **The READMEs read like a good talk, not a manual.** Lead with the idea, keep it short, then show how. Use the README template below for every step folder.
5. **Tools.** Use PowerShell 7, GitHub CLI (`gh`), Docker, and go-sqlcmd.
    - Check Microsoft Learn and GitHub Docs for current install steps and command syntax. Don't guess.
    - Where a feature can't be scripted, `run.ps1` prints the exact clicks and opens the right page with `gh browse` or `Start-Process`.
6. **No passwords in any committed file.**
    - Locally, read the password from a gitignored `.env` file.
    - In GitHub Actions, generate a random password at run time and mask it with `::add-mask::`.
    - That way a fork works with zero secrets.
7. **Every workflow follows the guardrails from the talk.**
    - Pin actions to a full commit SHA, with the version in a comment. Look up the current SHAs.
    - Add a `permissions:` block with the least access the job needs.
    - Set `timeout-minutes` on every job.
    - Add a `concurrency` group.
8. **Name workflow files with their step number**, like `05-database-tests.yml`, so they line up with the folders.

### Repo layout

```
github-automation-chaos/
├── README.md                     Front door for the audience, with the flow diagram
├── LICENSE                       MIT
├── .gitignore                    Ignores .env
├── .env.example                  MSSQL_SA_PASSWORD=ChangeMe_Str0ng!
├── compose.yaml                  Local SQL Server 2022
│
├── 00_Prerequisites/
│   ├── README.md
│   ├── run.ps1                   Checks tools, creates and configures the repo
│   └── ruleset.json              Branch ruleset for main
├── 01_FirstWorkflow/
│   ├── README.md
│   └── run.ps1
├── 02_SSMS/
│   ├── README.md
│   └── run.ps1
├── 03_DocsWikiMermaid/
│   ├── README.md
│   ├── run.ps1
│   └── wiki/                     Every wiki page lives here as Markdown
├── 04_TemplatesIssuesBoard/
│   ├── README.md
│   ├── run.ps1
│   └── sample-issues.json        Realistic sample issues for the board
├── 05_Containers/
│   ├── README.md
│   ├── run.ps1                   Local run: container, deploy, tests
│   ├── break-it.ps1              Pushes a broken change and opens a PR
│   └── fix-it.ps1                Pushes the fix to the same PR
├── 06_CopilotAndPRs/
│   ├── README.md
│   ├── run.ps1                   Opens a PR that labels, reviews, and merges itself
│   ├── copilot-task.ps1          Files an issue for the Copilot coding agent
│   └── copilot-issue.md
├── 07_Guardrails/
│   ├── README.md
│   ├── run.ps1
│   ├── Test-Guardrails.ps1       Grades workflow files against the guardrails
│   └── examples/
│       └── risky-workflow.yml    A workflow that breaks every rule, on purpose
├── 99_Cleanup/
│   ├── README.md
│   └── run.ps1
│
├── database/                     Shared by steps 02, 05, and 06
│   ├── 00-create-database.sql
│   ├── schema/  01-customers.sql, 02-orders.sql
│   ├── procs/   usp_GetActiveOrders.sql
│   ├── seed/    01-sample-data.sql
│   ├── rollback/ usp_GetActiveOrders.sql
│   └── tests/   test-active-orders-only.sql, test-every-order-has-a-customer.sql
├── scripts/                      Shared helpers
│   ├── Common.ps1                Banner, Write-Step, [R]/[W] tags, colors, -Pause
│   ├── Wait-SqlServer.ps1
│   ├── Deploy-Database.ps1
│   └── Invoke-DatabaseTests.ps1
│
└── .github/
    ├── CODEOWNERS
    ├── copilot-instructions.md
    ├── pull_request_template.md
    ├── release.yml
    ├── labeler.yml
    ├── dependabot.yml
    ├── ISSUE_TEMPLATE/
    │   ├── config.yml
    │   └── database-change.yml
    └── workflows/
        ├── 01-hello-workflow.yml
        ├── 05-database-tests.yml
        ├── 06-labeler.yml
        ├── 06-dependabot-auto-merge.yml
        ├── 07-guardrails-check.yml
        └── 07-nightly-check.yml
```

### README template for every step folder

```markdown
# 05 · Test every change in a SQL Server container

**The big idea:** every change gets tested on a clean server, and nobody has to remember to do it.

## Why it matters
Two or three short lines a DBA will nod at.

## Run it
    pwsh ./05_Containers/run.ps1

## What you'll see
A numbered list of what happens on screen, in order.

## How it works
One Mermaid diagram, then a short list of the files involved, with links.

## Play with it
Two or three things to change and see what happens.

## Learn more
Links to the official GitHub Docs or Microsoft Learn pages.
```

### The steps

#### `00_Prerequisites`

The big idea: get set up once, then everything else is one command.

`run.ps1` does this, in order:

1. **Check the tools.** Look for `pwsh` 7, `docker`, `sqlcmd`, `gh`, and `git`. Print a table with the version of each, or how to install it if it's missing.
2. **Check GitHub access.** Run `gh auth status`. If the `project` scope is missing, tell me to run `gh auth refresh -s project`.
3. **Create the local password file.** Make `.env` from `.env.example` if it doesn't exist, with a random strong password.
4. **Create the repo.** If it doesn't exist yet, create it with `gh repo create --source . --push`.
5. **Turn on repo settings** with `gh repo edit`: auto-merge, delete branch on merge, and wiki.
6. **Create the labels** with `gh label create --force`:
    - `database-change`
    - `database`
    - `docs`
    - `automation`
    - `needs-dba`
    - `dependencies`
    - `good-first-try`
7. **Seed some history** so release notes and the board have something real to show.
    - Open and merge three small labeled pull requests: one docs change, one database change, one automation change.
    - Do this before the ruleset exists.
8. **Create the ruleset** from `ruleset.json` with `gh api` (repository rulesets REST API). It covers `main`:
    - Require a pull request.
    - Require the `database-tests` check.
    - Set required approvals to 0, with a comment saying real teams should use 1 or more. This lets a solo presenter's demo pull requests merge.
    - Automatically request Copilot code review, if the API supports it. If it doesn't, print the clicks.
9. **Print a short "you're ready" summary** and the manual clicks that are left, if any.

#### `01_FirstWorkflow`

The big idea: a workflow is just a file. Something happens, a fresh machine starts, steps run, and you get a result.

- **The workflow:** `01-hello-workflow.yml`, triggered by `workflow_dispatch`.
- **What it does:**
    1. Prints what triggered it, who triggered it, and the runner OS.
    2. Runs three tiny steps.
    3. Writes a friendly job summary with a table of what just happened.
- **`run.ps1`:**
    1. Shows the YAML file with line numbers, so I can point at the trigger, the job, and the steps.
    2. Starts it with `gh workflow run`.
    3. Follows it live with `gh run watch`.
    4. Opens the run in the browser.

#### `02_SSMS`

The big idea: you don't have to leave SSMS to work with GitHub. Your scripts become code with history, a reviewer, and a way back.

`run.ps1` does this:

1. Makes and pushes a fresh branch, `demo/ssms-change`.
2. Prints the clicks for SSMS 22:
    - Clone or open the repo.
    - Switch to the branch.
    - Open `database/procs/usp_GetActiveOrders.sql`.
    - Ask Copilot in SSMS to explain it.
    - Make a small safe edit.
    - Commit and push.
3. Waits for Enter.
4. Opens the pull request with `gh pr create --fill` and shows it in the browser.

The README covers how to add the Git integration and GitHub Copilot components to SSMS 22 through the Visual Studio Installer, and links to Microsoft Learn.

#### `03_DocsWikiMermaid`

The big idea: when docs and diagrams are text, they get reviewed and versioned like everything else. No more stale Visio file on a share.

`wiki/` holds a fully built example wiki. Every page has at least one Mermaid diagram that GitHub renders.

| Page | What it shows | Mermaid type |
|---|---|---|
| `Home.md` | Quick links, the team, and how work reaches the DBAs | flowchart |
| `Request-A-Database-Change.md` | Filling out the issue form and the request lifecycle | stateDiagram |
| `Project-Board.md` | Board columns, Server and Risk fields, weekly triage | flowchart |
| `Reviewing-Pull-Requests.md` | What needs a DBA, the review checklist, how to approve | sequenceDiagram |
| `Labels.md` | Every label and how it gets added | flowchart |
| `On-Call-Rotation.md` | Schedule, escalation, handoff checklist | gantt |
| `Incident-Response-SOP.md` | Severity levels, first 15 minutes, starter queries | flowchart |
| `Naming-Conventions.md` | Objects, files, and branches | mindmap |
| `Branching.md` | main, a change branch, a hotfix, the merges | gitGraph |
| `Deployment-Runbook.md` | Pre-deploy checklist, deploy, rollback | flowchart |
| `How-We-Decide-What-To-Automate.md` | The 3 F's and 4 R's as a decision tree | flowchart |
| `DemoShop-Data-Model.md` | Customers, Orders, keys, and procs | erDiagram |
| `Maintenance-And-Backups.md` | Maintenance window, nightly jobs, restore tests | gantt |

Also include `_Sidebar.md` for navigation and `_Footer.md` for the note at the bottom of every page.

`run.ps1` does this:

1. Clones `https://github.com/<owner>/<repo>.wiki.git` into a temp folder.
    - If the wiki isn't set up yet, the clone fails. In that case, open the wiki page in the browser, say "click Create the first page and save, then press Enter", and retry.
2. Copies in every page, commits, and pushes.
3. Opens the wiki in the browser.

The root `README.md` also has the step map diagram, so the audience sees Mermaid on the front page.

#### `04_TemplatesIssuesBoard`

The big idea: the busy work of tracking requests can run itself. Requests show up complete, and the board keeps itself current.

Repo files this step shows off:

- **`.github/ISSUE_TEMPLATE/database-change.yml`:** an issue form titled "Database change request", labeled `database-change` and `needs-dba`. Fields:
    - Server, required.
    - Database, required.
    - Type of change, a required dropdown: Schema, Data fix, Permissions, Index, Other.
    - What and why, required.
    - Rollback plan, required.
    - When can this run, optional.
- **`.github/ISSUE_TEMPLATE/config.yml`:** turns off blank issues.
- **`.github/release.yml`:** release note categories by label.

`run.ps1` does this:

1. **Creates the project board** "Database Work" with `gh project create`, if it doesn't exist, and links it to the repo.
2. **Adds two custom fields:** Server (text) and Risk (single select: Low, Medium, High).
3. **Creates the sample issues** from `sample-issues.json`. Use about six realistic DBA requests, like:
    - Add index on Orders.CustomerId
    - Grant read access to the reporting team
    - Fix duplicate customer emails
    - Archive cancelled orders older than a year

   Then adds them to the board and sets Status, Server, and Risk so the board looks lived in, spread across Todo, In Progress, and Done.
4. **Creates a release** `v1.0.0` with `gh release create --generate-notes`, using the history seeded in step 00.
5. **Opens the issue form, the board, and the release** in the browser.
6. **Prints the one-time clicks** that the API can't do:
    - Switch the project to Board layout.
    - Turn on the project workflows: Auto-add with `label:database-change`, Item closed to Done, and Pull request merged to Done.

#### `05_Containers`

The big idea: every pull request gets a brand new SQL Server, a fresh deploy, and a full test run. Then the server is gone.

`run.ps1` runs it locally:

1. Starts SQL Server 2022 with `docker compose up -d`.
2. Waits until it's ready.
3. Deploys the database.
4. Runs the tests, printing PASS or FAIL for each one.
5. Prints "This exact flow runs in GitHub Actions on every pull request".

`break-it.ps1`:

1. Makes branch `demo/break-the-build`.
2. Removes the `WHERE Status = 'Active'` line from the proc.
3. Pushes and opens a pull request.
4. Runs `gh pr checks --watch` so the room watches it go red.

`fix-it.ps1` puts the line back, pushes, and watches it go green.

**The workflow:** `05-database-tests.yml`, triggered by `pull_request`, `workflow_dispatch`, and `workflow_call`. The job is named `database-tests`.

1. Check out the code.
2. Install go-sqlcmd.
3. Generate and mask a password.
4. Start SQL Server with `docker run`.
5. Wait, deploy, and test using the same scripts as local.
6. Write the results to the job summary.
7. Always remove the container at the end.

#### `06_CopilotAndPRs`

The big idea: the pull request can do its own chores, and Copilot can take the first pass.

Repo files this step shows off:

- **`.github/CODEOWNERS`:** `/database/` and `/.github/` belong to me.
- **`.github/pull_request_template.md`:** a checklist.
    - What changed and why.
    - Tests pass.
    - Rollback script included.
    - Safe to run twice.
- **`.github/labeler.yml` and `06-labeler.yml`:** `actions/labeler` v5 format on `pull_request_target`.
    - `database/**` gets `database`.
    - `0*_*/**` and `.github/**` get `automation`.
    - `03_DocsWikiMermaid/**` and `*.md` get `docs`.
- **`.github/dependabot.yml`:** the GitHub Actions ecosystem, weekly, labeled `dependencies`.
- **`06-dependabot-auto-merge.yml`:** follow the GitHub Docs example. Dependabot patch updates get `gh pr merge --auto --squash`.
- **`.github/copilot-instructions.md`:** house rules for Copilot.
    - Use `CREATE OR ALTER` and `SET NOCOUNT ON`.
    - Schema-qualify every object.
    - Scripts must be safe to run twice.
    - Every change includes a rollback script and a test.

`run.ps1` does this:

1. Makes branch `demo/new-proc`.
2. Adds a small new proc, `dbo.usp_GetCustomerOrderCount`, with a test and a rollback script.
3. Pushes and opens a pull request with `gh pr create`, using the template.
4. Points out each thing as it happens, refreshing with `gh pr view`:
    - The labels that appeared.
    - CODEOWNERS added as reviewer.
    - Copilot review requested.
    - Checks running.
5. Turns on auto-merge with `gh pr merge --auto --squash`.
6. Watches until it merges on its own.

`copilot-task.ps1` creates an issue from `copilot-issue.md` and assigns it to the Copilot coding agent. Check GitHub Docs for whether `gh` can assign Copilot today. If it can't, open the issue and print the clicks.

The issue asks Copilot to:

- Add a nullable `ShippedAt` column to Orders.
- Add a `usp_GetShippedOrders` proc.
- Add a test and a rollback script.

I run this before the talk, because it takes a few minutes.

#### `07_Guardrails`

The big idea: a little chaos is fun on stage. In production, you want a safety net.

**`Test-Guardrails.ps1`** reads workflow YAML files and grades each one, then prints a scorecard table. Rules:

1. Every action is pinned to a full commit SHA.
2. There is a `permissions:` block.
3. Every job has `timeout-minutes`.
4. There is a `concurrency` group.
5. There are no plain-text passwords or keys.

It takes `-Path`. The default is `.github/workflows`.

**`examples/risky-workflow.yml`** breaks every rule on purpose. It is NOT in `.github/workflows`, so it never runs.

**The workflows:**

- **`07-guardrails-check.yml`** runs `Test-Guardrails.ps1` on every pull request that touches `.github/workflows/`.
- **`07-nightly-check.yml`:**
    - Triggers: a nightly `schedule` and `workflow_dispatch`, with a `simulate_failure` boolean input.
    - It calls `05-database-tests.yml`.
    - If that fails, it opens an issue labeled `automation` and `needs-dba` with a link to the run.
    - Add a comment explaining that GitHub turns off scheduled workflows in public repos after 60 days with no activity.

`run.ps1` does this:

1. Grades `risky-workflow.yml`, which comes back all red.
2. Grades the real workflows, which come back all green.
3. Starts `07-nightly-check.yml` with `simulate_failure=true` and watches it.
4. Shows the issue it opened on its own.

#### `99_Cleanup`

The big idea: leave it ready for the next run.

`run.ps1` asks "Type RESET to continue" before changing anything, then:

1. Closes the demo pull requests and issues. It never touches the seeded history.
2. Deletes the `demo/*` branches.
3. Reverts any demo changes on `main` with a normal pull request.
4. Runs `docker compose down`.

### Shared pieces

#### `database/`

- **Database:** `DemoShop`.
- **`dbo.Customers`:** CustomerId, Name, Email, CreatedAt.
- **`dbo.Orders`:** OrderId, CustomerId (foreign key), OrderDate, Status (Active, Shipped, or Cancelled), Total.
- **`dbo.usp_GetActiveOrders`:** returns orders where `Status = 'Active'`, with the customer name.
- **Seed data:** about 5 customers and 15 orders. Safe to rerun.
- **Tests:** plain T-SQL that uses `THROW` with a clear message when a check fails. Capture proc output with `INSERT ... EXEC`.

#### `scripts/`

- **`Common.ps1`:** shared output helpers so every step looks the same.
    - A banner with the step number and big idea.
    - `Write-Step` with `[R]` and `[W]` tags.
    - Colors.
    - `-Pause` support.
- **`Wait-SqlServer.ps1`:** retries `SELECT 1` for up to 90 seconds.
- **`Deploy-Database.ps1`:** runs the scripts with `sqlcmd -b`, stopping on the first error, in this order:
    1. `00-create-database.sql`
    2. `schema`
    3. `procs`
    4. `seed`
- **`Invoke-DatabaseTests.ps1`:** runs every test, prints PASS or FAIL, and exits nonzero on any failure.

The connection defaults are `localhost,1433` and `sa`. The password comes from `SQLCMDPASSWORD`, loaded from `.env` when running locally.

#### Root `README.md`

Written for the audience.

1. Two lines on what this is and the session it came from.
2. The step map as a Mermaid flowchart, 00 through 07.
3. The flow table from the top of this file.
4. Quick start:
    - Fork it.
    - Install the tools listed in `00_Prerequisites`.
    - Run step 05 locally.
5. Troubleshooting:
    - On Apple Silicon, turn on Rosetta in Docker Desktop.
    - SQL Server has password complexity rules.

### Definition of done

1. Every `run.ps1` works from the repo root and is safe to run twice.
2. Step 05 passes locally on a clean machine with Docker running.
3. `break-it.ps1` turns the check red with a clear message, and `fix-it.ps1` turns it green.
4. `Test-Guardrails.ps1` fails `risky-workflow.yml` on every rule and passes every real workflow.
5. Every wiki page renders its Mermaid diagram on GitHub.
6. No password is in any committed file.
7. Every step folder has a README that follows the template.

---

## Part 2. My runbook

**Command tags**
- `[R]` is read only.
- `[W]` changes something.

### Once

1. Build the repo with Claude using this file.
2. `[R] pwsh ./00_Prerequisites/run.ps1`. The first time through it also creates the repo and changes settings, so treat that run as `[W]`. It prints every change before it makes it.
3. `[W] pwsh ./03_DocsWikiMermaid/run.ps1` to publish the wiki.
4. `[W] pwsh ./04_TemplatesIssuesBoard/run.ps1` to build the board, then do the two printed clicks.
5. Rehearse steps 01 through 07 once, then `[W] pwsh ./99_Cleanup/run.ps1`.

### Right before the talk

1. `[W] pwsh ./06_CopilotAndPRs/copilot-task.ps1`, so Copilot's pull request is ready by step 06.
2. `[W] pwsh ./05_Containers/run.ps1`, so the container image is already pulled.
3. Open browser tabs for the repo, the wiki, the board, and Actions. Zoom everything to 150 percent.
4. Have backup recordings ready.

### During the talk

| Slide | Run |
|---|---|
| Your first GitHub workflow | `pwsh ./01_FirstWorkflow/run.ps1` |
| Use GitHub from SSMS | `pwsh ./02_SSMS/run.ps1 -Pause` |
| Docs and diagrams in a wiki | `pwsh ./03_DocsWikiMermaid/run.ps1`, then click through the wiki |
| Issue forms and a project board | `pwsh ./04_TemplatesIssuesBoard/run.ps1`, then file one live issue from the form |
| Test every change in a SQL Server container | `pwsh ./05_Containers/run.ps1`, then `break-it.ps1` and `fix-it.ps1` |
| Copilot and pull requests that run themselves | Show Copilot's pull request, then `pwsh ./06_CopilotAndPRs/run.ps1` |
| Guardrails for safe workflows | `pwsh ./07_Guardrails/run.ps1` |

### After

`[W] pwsh ./99_Cleanup/run.ps1`, then share the repo link.
