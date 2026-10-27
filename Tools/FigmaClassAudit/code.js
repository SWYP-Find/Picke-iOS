// Read-only export of the exact approved Class/TTS frames in the open Figma file.
const targets = [
  { id: "13337:56744", label: "사전 투표" },
  { id: "13337:56966", label: "TTS 시나리오" },
  { id: "13337:57185", label: "최종 투표" },
  { id: "13384:57726", label: "의견" },
  { id: "13757:17445", label: "결과" },
];

figma.showUI(__html__, { width: 500, height: 760, themeColors: true });

function plain(value) {
  if (value == null || typeof value === "symbol") return null;
  try {
    return JSON.parse(JSON.stringify(value));
  } catch (_) {
    return null;
  }
}

function property(node, key) {
  try {
    return plain(node[key]);
  } catch (_) {
    return null;
  }
}

function describe(node) {
  const result = {
    id: node.id,
    name: node.name,
    type: node.type,
    visible: property(node, "visible"),
    opacity: property(node, "opacity"),
    x: property(node, "x"),
    y: property(node, "y"),
    width: property(node, "width"),
    height: property(node, "height"),
    absoluteBoundingBox: property(node, "absoluteBoundingBox"),
    fills: property(node, "fills"),
    strokes: property(node, "strokes"),
    strokeWeight: property(node, "strokeWeight"),
    cornerRadius: property(node, "cornerRadius"),
    layoutMode: property(node, "layoutMode"),
    itemSpacing: property(node, "itemSpacing"),
    padding: {
      top: property(node, "paddingTop"),
      right: property(node, "paddingRight"),
      bottom: property(node, "paddingBottom"),
      left: property(node, "paddingLeft"),
    },
  };

  if (node.type === "TEXT") {
    result.text = {
      characters: property(node, "characters"),
      fontName: property(node, "fontName"),
      fontSize: property(node, "fontSize"),
      lineHeight: property(node, "lineHeight"),
      letterSpacing: property(node, "letterSpacing"),
      textAlignHorizontal: property(node, "textAlignHorizontal"),
      textAlignVertical: property(node, "textAlignVertical"),
    };
  }
  if ("children" in node) {
    result.children = node.children.map(describe);
  }
  return result;
}

async function exportTarget(target) {
  const node = await figma.getNodeByIdAsync(target.id);
  if (!node) throw new Error(`${target.id} 노드를 현재 파일에서 찾지 못했습니다.`);
  if (typeof node.exportAsync !== "function") {
    throw new Error(`${target.id} 노드는 PNG 내보내기를 지원하지 않습니다.`);
  }
  const png = await node.exportAsync({ format: "PNG", constraint: { type: "SCALE", value: 1 } });
  return {
    id: target.id,
    label: target.label,
    name: node.name,
    png,
    structure: {
      sourceFile: figma.root.name,
      exportedAt: new Date().toISOString(),
      target: { id: target.id, label: target.label },
      node: describe(node),
    },
  };
}

figma.ui.onmessage = async (message) => {
  if (message && message.type === "init") {
    figma.ui.postMessage({ type: "ready", fileName: figma.root.name, targets });
    return;
  }
  if (!message || (message.type !== "export-one" && message.type !== "export-all")) return;
  const selected = message.type === "export-all"
    ? targets
    : targets.filter((target) => target.id === message.id);
  if (selected.length === 0) {
    figma.ui.postMessage({ type: "error", message: "지정되지 않은 노드입니다." });
    return;
  }

  figma.ui.postMessage({ type: "busy", count: selected.length });
  const results = [];
  const errors = [];
  for (const target of selected) {
    try {
      results.push(await exportTarget(target));
    } catch (error) {
      errors.push({ id: target.id, message: String(error && error.message ? error.message : error) });
    }
  }
  figma.ui.postMessage({ type: "exported", results, errors, bundle: message.type === "export-all" });
};
