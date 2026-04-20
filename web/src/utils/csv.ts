/**
 * Render an array of rows to a CSV string. Rows may be heterogeneous (keys are
 * taken from the first row unless explicit `columns` are provided).
 */
export function toCsv<T extends Record<string, unknown>>(
  rows: T[],
  columns?: { key: keyof T; label: string }[],
): string {
  if (rows.length === 0 && !columns) return '';
  const cols =
    columns ??
    (Object.keys(rows[0] ?? {}) as (keyof T)[]).map((k) => ({
      key: k,
      label: String(k),
    }));

  const esc = (v: unknown): string => {
    if (v == null) return '';
    const s = v instanceof Date ? v.toISOString() : String(v);
    if (/[",\n\r]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
    return s;
  };

  const header = cols.map((c) => esc(c.label)).join(',');
  const body = rows.map((r) => cols.map((c) => esc(r[c.key])).join(',')).join('\n');
  return `${header}\n${body}`;
}

export function downloadCsv(filename: string, csv: string) {
  // Prepend BOM so Excel recognizes UTF-8 reliably.
  const blob = new Blob([`\uFEFF${csv}`], { type: 'text/csv;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}
