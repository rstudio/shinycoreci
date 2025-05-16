# Execute with `python inst/gha/validate-test-files.py`

import os
import re
import glob
import sys
from pathlib import Path

# Set the working directory to the repo root
here = Path(__file__).resolve().parent.parent.parent
os.chdir(here)


def get_app_folders():
    app_folders = [
        f for f in glob.glob("inst/apps/*", root_dir=here) if os.path.isdir(f)
    ]
    app_folders.sort()
    app_folder_nums = [
        re.sub(r"^(\d\d\d)-.*$", r"\1", os.path.basename(folder))
        for folder in app_folders
    ]
    # Filter out "000" folders
    app_folder_nums = [num for num in app_folder_nums if num != "000"]
    # Check for duplicates
    duplicates = set([x for x in app_folder_nums if app_folder_nums.count(x) > 1])
    if duplicates:
        raise Exception(f"Duplicate app numbers found: {', '.join(duplicates)}")
    return app_folders


def validate_app(app_path):
    print(f"Validating app: {app_path}")
    app_files = glob.glob(os.path.join(app_path, "*.R")) + glob.glob(
        os.path.join(app_path, "*.Rmd")
    )
    tests_path = os.path.join(app_path, "tests")

    if os.path.isdir(tests_path):
        runners = [f for f in os.listdir(tests_path) if f.endswith("R")]
        if len(runners) > 1:
            raise Exception(
                f"More than 1 test runner found in {app_path}. Found: {', '.join(runners)}"
            )

        # Verify simple testthat.R
        testthat_path = os.path.join(tests_path, "testthat.R")
        if not os.path.exists(testthat_path):
            raise Exception(f"Missing `testthat.R` for app: {app_path}")

        with open(testthat_path, "r") as f:
            testthat_lines = f.readlines()
            testthat_lines = [line.strip() for line in testthat_lines if line.strip()]

        if len(testthat_lines) > 1:
            raise Exception(
                f"Non-basic testthat script found for {testthat_path}. Found:\n{''.join(testthat_lines)}"
            )

        if testthat_lines[0] != "shinytest2::test_app()":
            raise Exception(
                f"Non-shinytest2 testthat script found for {testthat_path}. Found:\n{''.join(testthat_lines)}"
            )

        # Verify shinyjster content
        shinyjster_file = os.path.join(tests_path, "testthat", "test-shinyjster.R")
        if os.path.exists(shinyjster_file):
            for jster_txt in ["shinyjster_server(", "shinyjster_js("]:
                found = False
                for app_file in app_files:
                    with open(app_file, "r") as f:
                        if any(jster_txt in line for line in f):
                            found = True
                            break
                if not found:
                    raise Exception(
                        f"{app_path} did not contain {jster_txt} but contains a `./tests/testthat/test-shinyjster.R"
                    )
    else:
        # Test for manual app
        found = False
        for app_file in app_files:
            with open(app_file, "r") as f:
                if any("shinycoreci::::is_manual_app" in line for line in f):
                    found = True
                    break
        if not found:
            raise Exception(
                f"No `./{app_path}/tests` folder found for non-manual app.\n"
                f"Either add tests with `shinytest2::use_shinytest2('{app_path}')`\n"
                f"Or set to manual by calling `shinycoreci::use_manual_app('{app_path}')`"
            )

    # The commented-out code for checking shinycoreci usage would go here
    # Uncomment if needed and adapt the R code accordingly


def main():
    app_folders = get_app_folders()
    # print(f"Found {len(app_folders)} app folders: {', '.join(app_folders)}")

    errors_found = []
    for app_folder in app_folders:
        try:
            validate_app(app_folder)
        except Exception as e:
            errors_found.append(e)

    if errors_found:
        for e in errors_found:
            print(f"\n{e}")
        sys.exit("Errors found when validating apps")
    else:
        print("No errors found when validating apps")


if __name__ == "__main__":
    main()
