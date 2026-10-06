from __future__ import annotations

from pathlib import Path

WORKFLOW = Path(__file__).resolve().parents[3] / ".github" / "workflows" / "ci.yml"


def test_ci_workflow_runs_the_full_verification_gate() -> None:
    text = WORKFLOW.read_text(encoding="utf-8")
    assert "pull_request:" in text
    assert "workflow_dispatch:" in text
    assert "ruff check src tests" in text
    assert "ruff format --check src tests" in text
    assert "run: mypy" in text
    assert 'pytest -o addopts=""' in text
    assert "image: postgres:" in text
    assert "STACKS_TEST_DATABASE_URL" in text
    assert "contents: read" in text


def test_ci_workflow_uses_no_secrets_or_live_sources() -> None:
    text = WORKFLOW.read_text(encoding="utf-8")
    assert "secrets." not in text
    assert "--source live" not in text
    assert "STACKS_DATABASE_URL" not in text
    assert "upload-artifact" not in text


def test_ci_workflow_has_no_automatic_institutional_scrape() -> None:
    text = WORKFLOW.read_text(encoding="utf-8").lower()
    assert "schedule:" not in text
    assert "refresh_stacks" not in text
    assert "penn" not in text
