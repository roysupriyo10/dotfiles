from pathlib import Path


def load_tests(loader, tests, pattern):
    directory = Path(__file__).resolve().parents[1] / "rpaste/tests"
    return loader.discover(str(directory), top_level_dir=str(directory))
