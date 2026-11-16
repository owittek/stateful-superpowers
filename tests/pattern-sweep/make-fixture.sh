#!/usr/bin/env bash
# Builds a throwaway TypeScript-shaped repo with two planted inconsistencies
# for evaluating the pattern sweep prompt. The code is never compiled or run;
# it only has to read like a real app to the sweep.
#
# Planted (head commit):
#   - src/routes/orders.ts hand-rolls service-failure mapping (and leaks the
#     internal error text) while src/lib/service-problem.ts exists and three
#     sibling routes use it            -> helper-exists
#   - src/tables/customer-columns.tsx truncates a long name with CSS only,
#     while TruncatedCell (tooltip when truncated) is used by two sibling
#     column files                     -> drift
#
# Usage: make-fixture.sh DIR   -> prints BASE=<sha> and HEAD=<sha>
set -euo pipefail

[ $# -eq 1 ] || { echo "usage: make-fixture.sh DIR" >&2; exit 2; }
dir=$1
[ ! -e "$dir" ] || { echo "make-fixture.sh: $dir already exists" >&2; exit 1; }
mkdir -p "$dir/src/lib" "$dir/src/routes" "$dir/src/components" "$dir/src/tables"
cd "$dir"
g() { git -c user.name=fixture -c user.email=fixture@example.invalid -c commit.gpgsign=false "$@"; }
g init -q -b main

cat >src/lib/service-problem.ts <<'EOF'
// Maps a failed service result to an HTTP problem response. Known error
// codes get their catalogue status and a safe detail; anything else becomes a
// 500 without the internal error text, which must never reach the client.
import { problem, ERRORS } from "./problem";

export type ServiceResult<T> = { ok: true; value: T } | { ok: false; code: string; error: string };

export function serviceProblem(result: { code: string; error: string }, opts: { operation: string }) {
  const known = ERRORS[result.code];
  if (known) return problem(known.status, { title: known.title, operation: opts.operation });
  return problem(500, { title: "Internal error", operation: opts.operation });
}
EOF
cat >src/lib/problem.ts <<'EOF'
export const ERRORS: Record<string, { status: number; title: string }> = {
  NOT_FOUND: { status: 404, title: "Not found" },
  CONFLICT: { status: 409, title: "Conflict" },
};
export function problem(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: { "content-type": "application/problem+json" } });
}
EOF
for pair in users:Users invoices:Invoices products:Products; do
  r=${pair%%:*} R=${pair#*:}
  cat >"src/routes/$r.ts" <<EOF
import { serviceProblem } from "../lib/service-problem";
import { create$R } from "../services/$r";

export async function POST(req: Request) {
  const result = await create$R(await req.json());
  if (!result.ok) return serviceProblem(result, { operation: "create$R" });
  return Response.json(result.value, { status: 201 });
}
EOF
done
cat >src/components/truncated-cell.tsx <<'EOF'
// A table cell that truncates with an ellipsis and shows the full text in a
// tooltip only when the text is actually cut off. Empty values render the
// shared null glyph.
import { Tooltip } from "./tooltip";

export function TruncatedCell({ text, maxWidth = 240 }: { text?: string | null; maxWidth?: number }) {
  if (!text) return <span className="text-muted">–</span>;
  return (
    <Tooltip content={text} onlyWhenTruncated delay={300}>
      <span className="block truncate" style={{ maxWidth }}>{text}</span>
    </Tooltip>
  );
}
EOF
for t in user invoice; do
  cat >"src/tables/$t-columns.tsx" <<EOF
import { TruncatedCell } from "../components/truncated-cell";

export const ${t}Columns = [
  { key: "name", header: "Name", cell: (row: { name?: string }) => <TruncatedCell text={row.name} /> },
  { key: "email", header: "Email", cell: (row: { email?: string }) => <TruncatedCell text={row.email} /> },
];
EOF
done
g add -A
g commit -q -m "base app"
base=$(git rev-parse HEAD)

cat >src/routes/orders.ts <<'EOF'
import { problem, ERRORS } from "../lib/problem";
import { createOrder } from "../services/orders";

export async function POST(req: Request) {
  const result = await createOrder(await req.json());
  if (!result.ok) {
    if (result.code === "NOT_FOUND") return problem(404, { title: ERRORS.NOT_FOUND.title });
    return problem(500, { title: "Internal error", detail: result.error });
  }
  return Response.json(result.value, { status: 201 });
}
EOF
cat >src/tables/customer-columns.tsx <<'EOF'
export const customerColumns = [
  {
    key: "company",
    header: "Company",
    cell: (row: { company?: string }) => (
      <div className="max-w-60 truncate">{row.company ?? "-"}</div>
    ),
  },
];
EOF
g add -A
g commit -q -m "add orders route and customer table"
echo "BASE=$base"
echo "HEAD=$(git rev-parse HEAD)"
