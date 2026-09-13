#!/usr/bin/env python3
"""Render repository target dependencies as GitHub-compatible SVG diagrams."""

import argparse
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs/diagrams/modules"
LAYERS = ("App", "Feature", "Domain", "Service", "Core", "UI")
COLORS = dict(zip(LAYERS, ("#ede9fe", "#cffafe", "#d1fae5", "#fef3c7", "#e2e8f0", "#fce7f3")))
START = "<!-- MODULE-DIAGRAMS:START -->"
END = "<!-- MODULE-DIAGRAMS:END -->"


def array(source, name):
    match = re.search(r"\b" + name + r"\s*:\s*\[", source)
    if not match:
        return ""
    end = source.index("]", match.end())
    return source[match.end():end]


def inventory():
    catalog = (ROOT / "Plugins/DependencyPlugin/ProjectDescriptionHelpers/TargetDependency+Module/Modules.swift").read_text()
    names = {}
    for layer in LAYERS[1:]:
        body = re.search(r"enum " + layer + r"Module\b[^\{]*\{(.*?)\n\}", catalog, re.S)[1]
        names[layer.lower()] = dict(re.findall(r'case\s+(\w+)\s*=\s*"([^"]+)"', body))

    modules = []
    for path in sorted((ROOT / "Projects").glob("**/Project.swift")):
        relative = path.relative_to(ROOT)
        layer = relative.parts[1]
        if layer not in LAYERS:
            raise ValueError(f"Unknown project layer: {relative}")
        name = "Picke" if layer == "App" else path.parent.name
        source = re.sub(r"//[^\n]*", "", path.read_text())
        has_interface = bool(re.search(r"hasInterface:\s*true", source))
        edges = set()
        external = set()
        for field, origin in (("dependencies", name), ("interfaceDependencies", name + "Interface")):
            entries = array(source, field)
            for entry in filter(str.strip, entries.splitlines()):
                entry = entry.strip().rstrip(",")
                if entry.startswith(".SPM."):
                    external.add(entry.removeprefix(".SPM."))
                    continue
                alias = re.fullmatch(r"\.(feature|domain|service|core)Assembly", entry)
                if alias:
                    edges.add((origin, alias[1].capitalize() + "Assembly"))
                    continue
                match = re.fullmatch(r"\.(feature|domain|service|core|ui)\(\.(\w+)(?:,\s*\.(\w+))?\)", entry)
                if not match:
                    raise ValueError(f"Unsupported dependency in {relative}: {entry!r}")
                dependency_layer, key, target = match.groups()
                target = target or ("interface" if dependency_layer in ("feature", "domain") else "implementation")
                suffix = {"interface": "Interface", "implementation": "", "testing": "Testing"}[target]
                edges.add((origin, names[dependency_layer][key] + suffix))
        if has_interface:
            edges.add((name, name + "Interface"))
        modules.append(dict(name=name, layer=layer, path=str(relative), hasInterface=has_interface,
                            edges=sorted(edges), external=sorted(external)))
    targets = {m["name"] for m in modules} | {m["name"] + "Interface" for m in modules if m["hasInterface"]}
    for module in modules:
        for origin, target in module["edges"]:
            if origin not in targets or target not in targets:
                raise ValueError(f"Undeclared target: {origin} -> {target}")
    return modules


def diagram(module, modules):
    owners = {target: item for item in modules for target in
              ([item["name"], item["name"] + "Interface"] if item["hasInterface"] else [item["name"]])}
    nodes = {module["name"]} | {node for edge in module["edges"] for node in edge}
    quote = json.dumps
    lines = ["digraph G {", 'graph [rankdir=LR, bgcolor="#ffffff", pad="0.3", nodesep="0.24", ranksep="0.8"];',
             'node [shape=box, style="rounded,filled", fontname="Helvetica", fontsize=13, margin="0.18,0.12", color="#64748b", fontcolor="#0f172a"];',
             'edge [color="#64748b", arrowsize=0.7];']
    for node in sorted(nodes):
        owner = owners[node]
        interface = node.endswith("Interface")
        style = "rounded,filled,dashed" if interface else "rounded,filled"
        width = "2" if node == module["name"] else "1"
        lines.append(f'{quote(node)} [fillcolor="{COLORS[owner["layer"]]}", style="{style}", penwidth={width}];')
    for origin, target in module["edges"]:
        lines.append(f"{quote(origin)} -> {quote(target)};")
    lines.append("}")
    return subprocess.run(["dot", "-Tsvg"], input="\n".join(lines), text=True,
                          capture_output=True, check=True).stdout


def readme_block(modules):
    lines = [START, "## 모듈 그래프", "",
             f"현재 {len(modules)}개 모듈의 구현·Interface 타깃 의존성을 표시합니다. 각 항목을 펼치면 GitHub에서 SVG 그림을 바로 볼 수 있습니다.", "",
             "화살표는 **참조하는 타깃 → 참조되는 타깃**, 점선 테두리는 **Interface**입니다. `Project.swift`의 `dependencies`·`interfaceDependencies`와 템플릿이 연결하는 자기 Interface를 반영합니다. 외부 SPM 패키지는 이름으로 별도 표기하고, Tests·Testing·Demo와 전이 의존성은 생략합니다.", "",
             "`APIEndpoint → AuthDomainInterface`처럼 현재 코드에 존재하는 계층 간 참조도 그대로 표시합니다. 실행 순서나 이상적인 아키텍처를 나타내는 그림은 아닙니다.", "",
             "[광고 HTML](docs/diagrams/picke-ads.html) · [전체 도메인 HTML](docs/diagrams/picke-domains.html) — 파일을 내려받아 브라우저에서 열면 확대·검색할 수 있습니다.", ""]
    for layer in LAYERS:
        members = [m for m in modules if m["layer"] == layer]
        lines += [f"### {layer} · {len(members)}개", ""]
        for module in members:
            name = module["name"]
            lines += ["<details>", f"<summary>{name}</summary>", "", f"[모듈 선언]({module['path']})", "",
                      f"![{name} 직접 의존 관계](docs/diagrams/modules/{name}.svg)", ""]
            if module["external"]:
                lines += ["외부 패키지 선언: " + ", ".join(f"`{p}`" for p in module["external"]) + ".", ""]
            if not module["edges"]:
                lines += ["다른 내부 모듈에 대한 직접 의존성이 없습니다.", ""]
            lines += ["</details>", ""]
    lines += ["갱신·검증:", "", "```bash", "python3 scripts/generate_module_diagrams.py",
              "python3 scripts/generate_module_diagrams.py --check", "```", "",
              "SVG 생성에는 Graphviz의 `dot`이 필요합니다. 앱 빌드나 Tuist 캐시 생성은 실행하지 않습니다.", "", END]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Fail if generated diagrams or README are stale")
    args = parser.parse_args()
    modules = inventory()
    generated = {OUTPUT / (m["name"] + ".svg"): diagram(m, modules) for m in modules}
    generated[OUTPUT / "manifest.json"] = json.dumps(modules, ensure_ascii=False, indent=2) + "\n"
    readme = ROOT / "README.md"
    text = readme.read_text()
    start = text.index(START) if START in text else text.index("## 모듈 그래프")
    end = text.index(END) + len(END) if END in text else text.index("## 기술 스택")
    generated[readme] = text[:start] + readme_block(modules) + "\n\n" + text[end:].lstrip("\n")
    stale = [str(path.relative_to(ROOT)) for path, content in generated.items()
             if not path.exists() or path.read_text() != content]
    if args.check:
        if stale:
            raise SystemExit("Stale diagram outputs:\n" + "\n".join(stale))
    else:
        OUTPUT.mkdir(parents=True, exist_ok=True)
        for path, content in generated.items():
            path.write_text(content)
    print(f"{'Verified' if args.check else 'Generated'} {len(modules)} module diagrams and README references")


if __name__ == "__main__":
    main()
