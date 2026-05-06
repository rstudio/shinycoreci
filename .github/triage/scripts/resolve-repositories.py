import os
import pathlib
import re
import sys

import yaml


REPO_PATTERN = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")


def fail(message):
    sys.exit(message)


def append_output(values):
    output_path = os.environ.get("GITHUB_OUTPUT")
    if not output_path:
        return

    with pathlib.Path(output_path).open("a") as output:
        for name, value in values.items():
            output.write(f"{name}={value}\n")


def main():
    cfg_path = pathlib.Path(os.environ["TRIAGE_CONFIG"])
    cfg = yaml.safe_load(cfg_path.read_text())

    repos = cfg.get("repositories") or []
    if not repos:
        fail(f"{cfg_path}: 'repositories:' must list at least one entry.")

    owner_repos = []
    seen = set()
    for entry in repos:
        repo = str(entry).strip()
        if not REPO_PATTERN.match(repo):
            fail(f"Repository entry must be 'owner/repo': {entry!r}")
        if repo in seen:
            fail(f"Duplicate repository entry: {repo}")
        seen.add(repo)
        owner_repos.append(repo)

    report_repo = cfg.get("report_repo") or owner_repos[0]
    if report_repo not in owner_repos:
        fail(
            f"report_repo={report_repo!r} must be one of the allowlisted repositories "
            f"({owner_repos}). Add it to repositories: first."
        )

    owners = sorted({repo.split("/", 1)[0] for repo in owner_repos})
    values = {
        "owner_repos": ",".join(owner_repos),
        "owners": ",".join(owners),
        "repo_count": str(len(owner_repos)),
        "report_repo": report_repo,
    }
    append_output(values)

    print(f"owners={values['owners']}")
    print(f"owner_repos={values['owner_repos']}")
    print(f"report_repo={report_repo}")


if __name__ == "__main__":
    main()