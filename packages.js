(function () {
  const treeEl = document.getElementById("tree");
  const input = document.getElementById("search");
  const status = document.getElementById("status");

  // Build a nested structure from the flat PACKAGES list
  const root = { folders: new Map(), pkgs: [] };
  for (const p of PACKAGES) {
    const parts = p.path.split("/");
    let node = root;
    for (const part of parts.slice(0, -1)) {
      if (!node.folders.has(part)) node.folders.set(part, { folders: new Map(), pkgs: [] });
      node = node.folders.get(part);
    }
    node.pkgs.push({ name: parts[parts.length - 1], version: p.version, desc: p.desc, path: p.path });
  }

  const count = n => n.pkgs.length + [...n.folders.values()].reduce((s, f) => s + count(f), 0);
  const el = (tag, cls, text) => {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  };

  function render(node, depth) {
    const ul = el("ul");
    for (const [name, folder] of [...node.folders].sort((a, b) => a[0].localeCompare(b[0]))) {
      const li = el("li");
      const d = el("details");
      d.dataset.top = depth === 0 ? "1" : "";
      d.open = depth === 0;
      const s = el("summary");
      s.append(el("span", "folder", name + "/"), el("span", "count", count(folder)));
      d.append(s, render(folder, depth + 1));
      li.append(d);
      ul.append(li);
    }
    for (const p of node.pkgs.sort((a, b) => a.name.localeCompare(b.name))) {
      const li = el("li", "pkg");
      li.dataset.q = (p.path + " " + (p.desc || "")).toLowerCase();
      li.append(el("span", "name", p.name), el("span", "ver", p.version || ""), el("span", "desc", p.desc || ""));
      ul.append(li);
    }
    return ul;
  }

  treeEl.append(render(root, 0));
  const total = PACKAGES.length;
  status.textContent = total + " packages";

  function filter() {
    const q = input.value.trim().toLowerCase();
    let shown = 0;
    treeEl.querySelectorAll(".pkg").forEach(li => {
      const hit = !q || li.dataset.q.includes(q);
      li.hidden = !hit;
      if (hit) shown++;
    });
    treeEl.querySelectorAll("details").forEach(d => {
      const any = d.querySelector(".pkg:not([hidden])");
      d.parentElement.hidden = !any;
      d.open = q ? Boolean(any) : d.dataset.top === "1";
    });
    status.textContent = !q ? total + " packages"
      : shown === 0 ? "No packages match “" + input.value.trim() + "”"
      : shown + " of " + total + " packages";
  }

  input.addEventListener("input", filter);
  document.addEventListener("keydown", e => {
    if (e.key === "/" && document.activeElement !== input) { e.preventDefault(); input.focus(); }
    if (e.key === "Escape" && document.activeElement === input) { input.value = ""; filter(); }
  });
})();
