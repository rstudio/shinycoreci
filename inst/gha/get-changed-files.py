import json
import os
import sys
import urllib.error
import urllib.request


def get_pull_request_number(event_path):
    with open(event_path, encoding="utf-8") as event_file:
        event = json.load(event_file)
    return event.get("number") or event.get("pull_request", {}).get("number")


def get_changed_files(api_url, repository, pull_request_number, token):
    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {token}",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    changed_files = []
    page = 1
    while True:
        url = (
            f"{api_url}/repos/{repository}/pulls/{pull_request_number}/files"
            f"?per_page=100&page={page}"
        )
        request = urllib.request.Request(url, headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                payload = json.load(response)
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace")
            sys.exit(f"GitHub API HTTP {exc.code} for {url}: {body}")
        except urllib.error.URLError as exc:
            sys.exit(f"Failed to connect to {url}: {exc.reason}")

        if not payload:
            break
        changed_files.extend(item["filename"] for item in payload)
        if len(payload) < 100:
            break
        page += 1
    return changed_files


def write_output(output_path, changed_files):
    with open(output_path, "a", encoding="utf-8") as output_file:
        output_file.write(
            f"all={json.dumps(changed_files, separators=(',', ':'))}\n"
        )


def main():
    token = os.getenv("GITHUB_TOKEN")
    if not token:
        sys.exit("Missing GITHUB_TOKEN")

    output_path = os.getenv("GITHUB_OUTPUT")
    if not output_path:
        sys.exit("Missing GITHUB_OUTPUT")

    event_path = os.getenv("GITHUB_EVENT_PATH")
    if not event_path:
        sys.exit("Missing GITHUB_EVENT_PATH")

    pull_request_number = get_pull_request_number(event_path)
    if not pull_request_number:
        sys.exit("This helper only supports pull request events")

    api_url = os.getenv("GITHUB_API_URL", "https://api.github.com").rstrip("/")
    repository = os.getenv("GITHUB_REPOSITORY")
    if not repository:
        sys.exit("Missing GITHUB_REPOSITORY")

    changed_files = get_changed_files(
        api_url, repository, pull_request_number, token
    )

    print(f"Found {len(changed_files)} changed file(s)")
    for filename in changed_files:
        print(filename)

    write_output(output_path, changed_files)


if __name__ == "__main__":
    main()
