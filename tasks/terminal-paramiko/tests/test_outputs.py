import ast
import hashlib
import json
import py_compile
from pathlib import Path

ROOT = Path("/app/vendor/paramiko")
MODULES = ["paramiko/agent.py", "paramiko/channel.py", "paramiko/client.py", "paramiko/transport.py"]


def _handlers(relative):
    tree = ast.parse((ROOT / relative).read_text())
    return [node for node in ast.walk(tree) if isinstance(node, ast.ExceptHandler)]


def _report():
    return json.loads(Path("/app/output.json").read_text())


def test_gate_artifact_schema():
    report = _report()
    expected = json.loads(Path("/tests/fixtures/expected_schema.json").read_text())
    assert report["schema_version"] == expected["schema_version"]
    assert report["status"] == "repaired"
    assert report["compiled"] is True
    assert list(report["modules"]) == expected["required_modules"]
    assert report["control_flow_policy"]["base_exception"] == "propagates"


def test_core_all_modules_compile_and_hash():
    report = _report()
    for relative in MODULES:
        path = ROOT / relative
        py_compile.compile(str(path), doraise=True)
        assert report["modules"][relative]["sha256"] == hashlib.sha256(path.read_bytes()).hexdigest()


def test_core_no_bare_handlers_and_expected_taxonomy():
    assert not any(handler.type is None for relative in MODULES for handler in _handlers(relative))
    agent_types = [ast.unparse(handler.type) for handler in _handlers("paramiko/agent.py")]
    assert "OSError" in agent_types
    assert agent_types.count("Exception") >= 2


def test_edge_cleanup_boundaries_catch_exception_only():
    for relative in ("paramiko/channel.py", "paramiko/client.py", "paramiko/transport.py"):
        types = [ast.unparse(handler.type) for handler in _handlers(relative)]
        assert "Exception" in types
        assert "BaseException" not in types


def test_edge_agent_discovery_does_not_swallow_control_flow():
    handlers = _handlers("paramiko/agent.py")
    assert any(ast.unparse(handler.type) == "OSError" for handler in handlers)
    assert all(handler.type is not None for handler in handlers)
