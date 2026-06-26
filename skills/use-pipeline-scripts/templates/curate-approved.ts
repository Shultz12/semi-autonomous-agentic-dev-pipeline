// VERSION: 1.0.0
//
// curate-approved.ts — filter pattern-analyst findings by audit verdict; emit
// approved.md containing only ACCEPT findings, or a NO_PROPOSALS_APPROVED
// marker when every finding was REJECT.
//
// Bootstrapped from .claude/skills/use-pipeline-scripts/templates/curate-approved.ts
// Project copy: .project/pipeline/scripts/curate-approved.ts
// Consumer: pattern-analyst (curate mode)
//
// Usage:
//   npx ts-node .project/pipeline/scripts/curate-approved.ts \
//     --findings <path1,path2,...> --audit <audit.md> --out <approved.md>
//
// Inputs:
//   --findings  Comma-separated list of findings file paths (no spaces).
//   --audit     Path to the combined audit file.
//   --out       Path where approved.md should be written.
//
// Strict input contract:
//   - The audit file MUST contain ONLY ACCEPT and REJECT verdicts at script
//     invocation. MODIFY-AS is the curate-mode agent's responsibility to
//     resolve before running this script.
//
// Errors (stderr + non-zero exit): UNRESOLVED_MODIFY_AS, FINDINGS_AUDIT_MISMATCH,
//   FINDINGS_NOT_FOUND, AUDIT_NOT_FOUND, FINDING_ID_COLLISION.

import * as fs from "node:fs";

interface Args {
  findings: string[];
  audit: string;
  out: string;
}

interface FindingBlock {
  id: string;
  origin: string;
  text: string;
}

interface VerdictEntry {
  id: string;
  verdict: "ACCEPT" | "REJECT" | "MODIFY-AS";
  raw: string;
}

function fail(code: string, detail = ""): never {
  process.stderr.write(detail ? `${code}: ${detail}\n` : `${code}\n`);
  process.exit(1);
}

function parseArgs(argv: string[]): Args {
  const out: Partial<Args> = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--findings")
      out.findings = argv[++i]
        .split(",")
        .map((s) => s.trim())
        .filter(Boolean);
    else if (a === "--audit") out.audit = argv[++i];
    else if (a === "--out") out.out = argv[++i];
  }
  if (
    !out.findings ||
    out.findings.length === 0 ||
    !out.audit ||
    !out.out
  ) {
    fail(
      "USAGE",
      "--findings <comma-separated paths> --audit <path> --out <path>",
    );
  }
  return out as Args;
}

/**
 * Parse a findings file into blocks. A finding block is delimited by an H3
 * (`### `) heading and must declare its `id:` on a line within the block.
 * Blocks without an `id:` line are ignored (not treated as findings).
 */
function parseFindings(filePath: string): FindingBlock[] {
  if (!fs.existsSync(filePath)) fail("FINDINGS_NOT_FOUND", filePath);
  const content = fs.readFileSync(filePath, "utf8");
  const lines = content.split(/\r?\n/);

  const blocks: FindingBlock[] = [];
  let current: string[] | null = null;
  let currentId: string | null = null;

  const flush = () => {
    if (current === null) return;
    if (currentId !== null) {
      blocks.push({
        id: currentId,
        origin: filePath,
        text: current.join("\n"),
      });
    }
    current = null;
    currentId = null;
  };

  for (const raw of lines) {
    const line = raw.replace(/\r$/, "");
    if (/^###\s+/.test(line)) {
      flush();
      current = [line];
      currentId = null;
      continue;
    }
    if (current !== null) {
      current.push(line);
      if (currentId === null) {
        const m = line.match(/^\s*-?\s*id:\s*(\S+)\s*$/);
        if (m) currentId = m[1];
      }
    }
  }
  flush();

  return blocks;
}

/**
 * Parse the audit file. Each verdict is a `## Verdict: <id>` block containing
 * a `Verdict: ACCEPT | REJECT | MODIFY-AS:<...>` line.
 */
function parseAudit(filePath: string): VerdictEntry[] {
  if (!fs.existsSync(filePath)) fail("AUDIT_NOT_FOUND", filePath);
  const content = fs.readFileSync(filePath, "utf8");
  const lines = content.split(/\r?\n/);

  const verdicts: VerdictEntry[] = [];
  let currentId: string | null = null;

  for (const raw of lines) {
    const line = raw.replace(/\r$/, "");
    const header = line.match(/^##\s+Verdict:\s*(\S+)\s*$/);
    if (header) {
      currentId = header[1];
      continue;
    }
    if (currentId !== null) {
      const v = line.match(/^Verdict:\s*(ACCEPT|REJECT|MODIFY-AS)(?::.*)?$/);
      if (v) {
        verdicts.push({
          id: currentId,
          verdict: v[1] as VerdictEntry["verdict"],
          raw: line,
        });
        currentId = null;
      }
    }
  }

  return verdicts;
}

function main(): void {
  const args = parseArgs(process.argv.slice(2));

  // 1. Read findings; index by id; detect collisions across files.
  const index = new Map<string, FindingBlock>();
  for (const fp of args.findings) {
    const blocks = parseFindings(fp);
    for (const b of blocks) {
      const existing = index.get(b.id);
      if (existing) {
        fail(
          "FINDING_ID_COLLISION",
          `${b.id} in ${existing.origin}, ${b.origin}`,
        );
      }
      index.set(b.id, b);
    }
  }

  // 2. Validate audit: no MODIFY-AS remains.
  const verdicts = parseAudit(args.audit);
  const unresolved = verdicts
    .filter((v) => v.verdict === "MODIFY-AS")
    .map((v) => v.id);
  if (unresolved.length > 0) fail("UNRESOLVED_MODIFY_AS", unresolved.join(", "));

  // 3. Pair findings ↔ verdicts. Mismatch in either direction is an error.
  const verdictById = new Map(verdicts.map((v) => [v.id, v] as const));

  for (const v of verdicts) {
    if (!index.has(v.id)) fail("FINDINGS_AUDIT_MISMATCH", v.id);
  }
  for (const id of index.keys()) {
    if (!verdictById.has(id)) fail("FINDINGS_AUDIT_MISMATCH", id);
  }

  // 4. Filter: keep ACCEPT, drop REJECT.
  const accepted: FindingBlock[] = [];
  let rejectedCount = 0;
  for (const [id, block] of index) {
    const v = verdictById.get(id)!;
    if (v.verdict === "ACCEPT") accepted.push(block);
    else if (v.verdict === "REJECT") rejectedCount++;
  }

  // Stable ordering: by finding ID ascending so output is deterministic.
  accepted.sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));

  // 5. Emit approved.md.
  if (accepted.length === 0) {
    const breakdown = `${rejectedCount} REJECT`;
    const marker =
      `# Pattern Findings — Approved\n` +
      `**Status:** NO_PROPOSALS_APPROVED\n` +
      `**Audit summary:** ${rejectedCount} findings rejected (${breakdown})\n` +
      `**Implementer action:** Orchestrator should commit findings + audit + this approved.md to the refactor or primitives worktree; ship via accept-feature.\n`;
    fs.writeFileSync(args.out, marker, "utf8");
    return;
  }

  const parts: string[] = ["# Pattern Findings — Approved", ""];
  for (const b of accepted) {
    parts.push(`<!-- origin: ${b.origin} -->`);
    parts.push(b.text);
    parts.push("");
  }
  fs.writeFileSync(args.out, parts.join("\n"), "utf8");
}

try {
  main();
} catch (e: unknown) {
  process.stderr.write(
    `UNEXPECTED: ${e instanceof Error ? e.message : String(e)}\n`,
  );
  process.exit(1);
}
