// VERSION: 1.0.0
//
// find-call-sites.ts — enumerate call sites of an exported function across
// .ts/.tsx/.js (via ts-morph) and .svelte (via svelte2tsx) sources.
//
// Bootstrapped from .claude/skills/use-pipeline-scripts/templates/codemods/find-call-sites.ts
// Project copy: .project/pipeline/scripts/codemods/find-call-sites.ts
// Consumers: pattern-analyst (convergence-scout, primitives-scout)
//
// Usage:
//   npx ts-node .project/pipeline/scripts/codemods/find-call-sites.ts \
//     --function <name> --source <module-path> --tsconfig <path>
//
// Output: stable, sorted JSON on stdout.
// Errors: structured codes on stderr + non-zero exit (see SKILL.md).
//
// Runtime deps: ts-morph, svelte2tsx. Directory enumeration is dep-free
// (recursive fs walk) — no glob library required.

import * as fs from "node:fs";
import * as path from "node:path";

type CallSite = { file: string; line: number; column: number };
type UncertainSite = { file: string; reason: string };

interface Args {
  functionName: string;
  source: string;
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
    const a = argv[i];
    if (a === "--function") out.functionName = argv[++i];
    else if (a === "--source") out.source = argv[++i];
    else if (a === "--tsconfig") out.tsconfig = argv[++i];
  }
  if (!out.functionName || !out.source || !out.tsconfig) {
    fail("USAGE", "--function <name> --source <module-path> --tsconfig <path>");
  }
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

function compareSites(a: CallSite, b: CallSite): number {
  if (a.file !== b.file) return a.file < b.file ? -1 : 1;
  if (a.line !== b.line) return a.line - b.line;
  return a.column - b.column;
}

function compareUncertain(a: UncertainSite, b: UncertainSite): number {
  if (a.file !== b.file) return a.file < b.file ? -1 : 1;
  return a.reason < b.reason ? -1 : a.reason > b.reason ? 1 : 0;
}

interface RawMapping {
  generatedLine: number;
  generatedColumn: number;
  originalLine?: number;
  originalColumn?: number;
}

function translatePosition(
  map: unknown,
  generatedLine: number,
  generatedColumn: number,
): { line: number; column: number } {
  // svelte2tsx returns a raw source-map-like object. Best-effort lookup by
  // parsing mappings if a structured array is present; otherwise return the
  // generated position unchanged (still useful for the consumer; column may
  // be approximate).
  if (!map || typeof map !== "object") {
    return { line: generatedLine, column: generatedColumn };
  }
  const m = map as { mappings?: string | RawMapping[] };
  if (Array.isArray(m.mappings)) {
    const exact = m.mappings.find(
      (x) => x.generatedLine === generatedLine && x.generatedColumn === generatedColumn,
    );
    if (exact && exact.originalLine != null && exact.originalColumn != null) {
      return { line: exact.originalLine, column: exact.originalColumn };
    }
  }
  return { line: generatedLine, column: generatedColumn };
}

function main(): void {
  const args = parseArgs(process.argv.slice(2));

  if (!fs.existsSync(args.tsconfig)) fail("TSCONFIG_INVALID", args.tsconfig);

  type TsMorph = typeof import("ts-morph");
  const tsMorph = loadModule<TsMorph>("ts-morph");
  const { Project, Node } = tsMorph;

  let project: InstanceType<TsMorph["Project"]>;
  try {
    project = new Project({ tsConfigFilePath: args.tsconfig });
  } catch (e: unknown) {
    fail("TSCONFIG_INVALID", e instanceof Error ? e.message : String(e));
  }

  // Resolve source file. --source may be relative to repo root or a module
  // specifier. Try literal paths first; fall back to basename lookup across
  // project sources (handles tsconfig path aliases pragmatically).
  const sourceCandidates = [
    path.resolve(args.source),
    path.resolve(args.source + ".ts"),
    path.resolve(args.source + ".tsx"),
  ];
  let sourceFile = sourceCandidates
    .map((p) => project.getSourceFile(p))
    .find((sf) => !!sf);

  if (!sourceFile) {
    const all = project.getSourceFiles();
    const targetBase = path.basename(args.source).replace(/\.[tj]sx?$/, "");
    const matches = all.filter((sf) => {
      const base = path.basename(sf.getFilePath()).replace(/\.[tj]sx?$/, "");
      return base === targetBase;
    });
    if (matches.length === 0) fail("SOURCE_NOT_FOUND", args.source);
    if (matches.length > 1)
      fail(
        "AMBIGUOUS_EXPORT",
        `${args.source} matches: ${matches.map((m) => m.getFilePath()).join(", ")}`,
      );
    sourceFile = matches[0];
  }

  const exportedDecls = sourceFile.getExportedDeclarations();
  const decl = exportedDecls.get(args.functionName);
  if (!decl || decl.length === 0) fail("FUNCTION_NOT_FOUND", args.functionName);
  if (decl.length > 1) fail("AMBIGUOUS_EXPORT", args.functionName);
  const target = decl[0];

  type SvelteToTsx = typeof import("svelte2tsx");
  const s2tx = loadModule<SvelteToTsx>("svelte2tsx");

  const repoRoot = process.cwd();
  const sveltePaths = walkFiles(repoRoot, (p) => p.endsWith(".svelte"));

  const virtualToOrigin = new Map<
    string,
    { svelteFile: string; map: unknown }
  >();

  for (const sveltePath of sveltePaths) {
    const content = fs.readFileSync(sveltePath, "utf8");
    let out: { code: string; map?: unknown };
    try {
      out = s2tx.svelte2tsx(content, { filename: sveltePath, mode: "ts" });
    } catch {
      // Skip files svelte2tsx cannot parse; they cannot contain typed references.
      continue;
    }
    const virtualPath = sveltePath + ".tsx";
    project.createSourceFile(virtualPath, out.code, { overwrite: true });
    virtualToOrigin.set(virtualPath, { svelteFile: sveltePath, map: out.map });
  }

  // Find references uniformly across real .ts and virtual .tsx.
  const tsSites: CallSite[] = [];
  const svelteSites: CallSite[] = [];
  const uncertainSites: UncertainSite[] = [];

  const refs = target.findReferences();
  for (const refSym of refs) {
    for (const ref of refSym.getReferences()) {
      if (ref.isDefinition()) continue;
      const node = ref.getNode();
      const refFile = node.getSourceFile().getFilePath();
      const { line, column } = node
        .getSourceFile()
        .getLineAndColumnAtPos(node.getStart());

      if (refFile.endsWith(".svelte.tsx") && virtualToOrigin.has(refFile)) {
        const origin = virtualToOrigin.get(refFile)!;
        const mapped = translatePosition(origin.map, line, column);
        svelteSites.push({
          file: path.relative(repoRoot, origin.svelteFile).replace(/\\/g, "/"),
          line: mapped.line,
          column: mapped.column,
        });
      } else {
        tsSites.push({
          file: path.relative(repoRoot, refFile).replace(/\\/g, "/"),
          line,
          column,
        });
      }
    }
  }

  // Flag dynamic imports / require() of the source module as uncertain.
  const sourceRel = path
    .relative(repoRoot, sourceFile.getFilePath())
    .replace(/\\/g, "/")
    .replace(/\.tsx?$/, "");

  for (const sf of project.getSourceFiles()) {
    const fp = sf.getFilePath();
    if (fp.endsWith(".svelte.tsx") && !virtualToOrigin.has(fp)) continue;

    sf.forEachDescendant((node) => {
      if (Node.isCallExpression(node)) {
        const exprText = node.getExpression().getText();
        if (exprText === "import" || exprText === "require") {
          const argText = node.getArguments()[0]?.getText() ?? "";
          if (argText.includes(sourceRel) || argText.includes(args.source)) {
            const display =
              fp.endsWith(".svelte.tsx") && virtualToOrigin.has(fp)
                ? virtualToOrigin.get(fp)!.svelteFile
                : fp;
            uncertainSites.push({
              file: path.relative(repoRoot, display).replace(/\\/g, "/"),
              reason: exprText === "import" ? "dynamic import" : "require()",
            });
          }
        }
      }
    });
  }

  tsSites.sort(compareSites);
  svelteSites.sort(compareSites);
  uncertainSites.sort(compareUncertain);

  const result = {
    function: args.functionName,
    source: path.relative(repoRoot, sourceFile.getFilePath()).replace(/\\/g, "/"),
    callSites: {
      ts: tsSites,
      svelte: svelteSites,
      uncertain: uncertainSites,
    },
    totals: {
      ts: tsSites.length,
      svelte: svelteSites.length,
      uncertain: uncertainSites.length,
      total: tsSites.length + svelteSites.length + uncertainSites.length,
    },
  };

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
