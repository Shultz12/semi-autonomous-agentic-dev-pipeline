// VERSION: 1.0.0
//
// inventory-utils.ts — enumerate exported declarations (functions, classes, const
// symbols) at the paths declared by `## Shared utility locations` in
// .project/knowledge/architecture.md.
//
// Bootstrapped from .claude/skills/use-pipeline-scripts/templates/inventory-utils.ts
// Project copy: .project/pipeline/scripts/inventory-utils.ts
// Consumers: pattern-analyst (divergence-scout canonical; primitives-scout falls back)
//
// Usage:
//   npx ts-node .project/pipeline/scripts/inventory-utils.ts --tsconfig <path>
//
// Output: stable, sorted JSON on stdout.
// Errors: structured codes on stderr + non-zero exit (see SKILL.md).
//
// Runtime deps: ts-morph, svelte2tsx. Glob resolution for .ts/.tsx paths uses
// ts-morph's native path matching; .svelte enumeration uses a dep-free fs walk.

import * as fs from "node:fs";
import * as path from "node:path";

type Kind = "function" | "class" | "constant";

interface Utility {
  name: string;
  path: string;
  kind: Kind;
  signature: string;
}

interface Args {
  tsconfig: string;
}

const IGNORE_DIRS = new Set([
  "node_modules",
  ".svelte-kit",
  "build",
  "dist",
  ".git",
]);

function fail(code: string, detail = ""): never {
  process.stderr.write(detail ? `${code}: ${detail}\n` : `${code}\n`);
  process.exit(1);
}

function parseArgs(argv: string[]): Args {
  const out: Partial<Args> = {};
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--tsconfig") out.tsconfig = argv[++i];
  }
  if (!out.tsconfig) fail("USAGE", "--tsconfig <path>");
  return out as Args;
}

function loadModule<T>(id: string): T {
  try {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    return require(id) as T;
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (/Cannot find module/i.test(msg)) fail("MODULE_NOT_FOUND", id);
    throw e;
  }
}

function readArchitectureMarkers(architecturePath: string): string[] {
  if (!fs.existsSync(architecturePath))
    fail("ARCHITECTURE_FILE_NOT_FOUND", architecturePath);
  const content = fs.readFileSync(architecturePath, "utf8");
  const lines = content.split(/\r?\n/);

  let inSection = false;
  const globs: string[] = [];

  for (const raw of lines) {
    const line = raw.replace(/\r$/, "");
    if (/^##\s+Shared utility locations\s*$/i.test(line)) {
      inSection = true;
      continue;
    }
    if (inSection) {
      if (/^##\s+/.test(line)) break; // next H2 section ends the list
      const stripped = line.replace(/^\s*-\s*/, "").trim();
      if (stripped === "") continue; // blank lines allowed inside the section
      globs.push(stripped);
    }
  }

  if (!inSection)
    fail("ARCHITECTURE_MARKER_MISSING", "## Shared utility locations");
  if (globs.length === 0)
    fail("ARCHITECTURE_MARKER_EMPTY", "## Shared utility locations");

  for (const g of globs) {
    if (/[<>"|]/.test(g)) fail("INVALID_PATH_GLOB", g);
  }

  return globs;
}

/** Minimal glob → RegExp. Supports `**`, `*`, `?`; matches POSIX-style paths. */
function globToRegExp(glob: string): RegExp {
  const g = glob.replace(/\\/g, "/");
  let re = "";
  for (let i = 0; i < g.length; i++) {
    const c = g[i];
    if (c === "*") {
      if (g[i + 1] === "*") {
        re += "(?:.*)";
        i++;
        if (g[i + 1] === "/") i++; // consume the slash after **
      } else {
        re += "[^/]*";
      }
    } else if (c === "?") {
      re += "[^/]";
    } else if (".+^${}()|[]\\".includes(c)) {
      re += "\\" + c;
    } else {
      re += c;
    }
  }
  return new RegExp("^" + re + "$");
}

/** Recursive directory walk; returns absolute paths of files passing `match`. */
function walkFiles(rootDir: string, match: (absPath: string) => boolean): string[] {
  const results: string[] = [];
  const stack: string[] = [rootDir];
  while (stack.length > 0) {
    const dir = stack.pop()!;
    let entries: fs.Dirent[];
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch {
      continue;
    }
    for (const ent of entries) {
      const full = path.join(dir, ent.name);
      if (ent.isDirectory()) {
        if (IGNORE_DIRS.has(ent.name)) continue;
        stack.push(full);
      } else if (ent.isFile() && match(full)) {
        results.push(full);
      }
    }
  }
  return results;
}

function main(): void {
  const args = parseArgs(process.argv.slice(2));

  if (!fs.existsSync(args.tsconfig)) fail("TSCONFIG_INVALID", args.tsconfig);

  const repoRoot = process.cwd();
  const architecturePath = path.join(
    repoRoot,
    ".project",
    "knowledge",
    "architecture.md",
  );
  const scannedPaths = readArchitectureMarkers(architecturePath);

  type TsMorph = typeof import("ts-morph");
  const tsMorph = loadModule<TsMorph>("ts-morph");
  const { Project, Node } = tsMorph;

  let project: InstanceType<TsMorph["Project"]>;
  try {
    project = new Project({ tsConfigFilePath: args.tsconfig });
  } catch (e: unknown) {
    fail("TSCONFIG_INVALID", e instanceof Error ? e.message : String(e));
  }

  // Resolve .ts/.tsx files matching the architecture globs natively via ts-morph.
  let tsMatched: ReturnType<typeof project.addSourceFilesAtPaths>;
  try {
    tsMatched = project.addSourceFilesAtPaths(scannedPaths);
  } catch (e: unknown) {
    fail("INVALID_PATH_GLOB", e instanceof Error ? e.message : String(e));
  }

  // Resolve .svelte files: walk repo, match each against the .svelte-variant of
  // every scanned glob (replace the trailing extension with `.svelte`).
  const svelteGlobRes = scannedPaths
    .map((g) => g.replace(/\.[A-Za-z0-9]+$/, ".svelte"))
    .filter((g) => g.endsWith(".svelte"))
    .map(globToRegExp);

  const svelteFiles =
    svelteGlobRes.length === 0
      ? []
      : walkFiles(repoRoot, (abs) => {
          if (!abs.endsWith(".svelte")) return false;
          const rel = path.relative(repoRoot, abs).replace(/\\/g, "/");
          return svelteGlobRes.some((re) => re.test(rel));
        });

  if (svelteFiles.length > 0) {
    type SvelteToTsx = typeof import("svelte2tsx");
    const s2tx = loadModule<SvelteToTsx>("svelte2tsx");
    for (const sveltePath of svelteFiles) {
      const content = fs.readFileSync(sveltePath, "utf8");
      try {
        const out = s2tx.svelte2tsx(content, {
          filename: sveltePath,
          mode: "ts",
        });
        project.createSourceFile(sveltePath + ".tsx", out.code, {
          overwrite: true,
        });
      } catch {
        // skip unparseable
      }
    }
  }

  const scannedSet = new Set<string>([
    ...tsMatched.map((sf) => sf.getFilePath().replace(/\\/g, "/")),
    ...svelteFiles.map((p) => (p + ".tsx").replace(/\\/g, "/")),
  ]);

  const utilities: Utility[] = [];

  for (const sf of project.getSourceFiles()) {
    const fp = sf.getFilePath().replace(/\\/g, "/");
    if (!scannedSet.has(fp)) continue;

    const displayPath = fp.endsWith(".svelte.tsx")
      ? fp.replace(/\.tsx$/, "")
      : fp;
    const relPath = path.relative(repoRoot, displayPath).replace(/\\/g, "/");

    for (const [name, decls] of sf.getExportedDeclarations()) {
      for (const d of decls) {
        let kind: Kind | null = null;
        let signature = "";

        if (
          Node.isFunctionDeclaration(d) ||
          Node.isFunctionExpression(d) ||
          Node.isArrowFunction(d)
        ) {
          kind = "function";
          signature = (d as { getText: () => string })
            .getText()
            .split("{")[0]
            .trim();
        } else if (Node.isClassDeclaration(d)) {
          kind = "class";
          signature = `class ${name}`;
        } else if (Node.isVariableDeclaration(d)) {
          const init = d.getInitializer();
          if (
            init &&
            (Node.isArrowFunction(init) || Node.isFunctionExpression(init))
          ) {
            kind = "function";
            signature = init.getText().split("{")[0].trim();
          } else {
            kind = "constant";
            const typeText = d.getType().getText();
            signature = `${name}: ${typeText}`;
          }
        }

        if (kind) {
          utilities.push({ name, path: relPath, kind, signature });
        }
      }
    }
  }

  utilities.sort((a, b) => {
    if (a.name !== b.name) return a.name < b.name ? -1 : 1;
    if (a.path !== b.path) return a.path < b.path ? -1 : 1;
    return 0;
  });

  const totals = {
    functions: utilities.filter((u) => u.kind === "function").length,
    classes: utilities.filter((u) => u.kind === "class").length,
    constants: utilities.filter((u) => u.kind === "constant").length,
    total: utilities.length,
  };

  const result = { scannedPaths, utilities, totals };
  process.stdout.write(JSON.stringify(result, null, 2) + "\n");
}

try {
  main();
} catch (e: unknown) {
  process.stderr.write(
    `UNEXPECTED: ${e instanceof Error ? e.message : String(e)}\n`,
  );
  process.exit(1);
}
