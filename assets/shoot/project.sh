#!/usr/bin/env bash
# Builds the small TypeScript project the screenshots show: one commit, then uncommitted edits, a staged edit and a new
# file, so the file tree has git marks and the diff has every kind of line. The commit comes from a fast-import stream,
# which states its own authorship.
set -euo pipefail
dir=$1
rm -rf "$dir"
mkdir -p "$dir/src" "$dir/test"
cd "$dir"
git init -q -b main

cat >package.json <<'EOF'
{
  "name": "forecast",
  "version": "0.3.0",
  "type": "module",
  "scripts": { "test": "vitest run" }
}
EOF

cat >README.md <<'EOF'
# forecast

The weather for a city, in the units you read.
EOF

cat >tsconfig.json <<'EOF'
{ "compilerOptions": { "strict": true, "target": "es2022", "module": "nodenext" } }
EOF

cat >src/units.ts <<'EOF'
export type Unit = "celsius" | "fahrenheit" | "kelvin";

export function convert(celsius: number, unit: Unit): number {
  switch (unit) {
    case "celsius":
      return celsius;
    case "fahrenheit":
      return (celsius * 9) / 5 + 32;
    case "kelvin":
      return celsius + 273.15;
  }
}
EOF

cat >src/cache.ts <<'EOF'
export class Cache<T> {
  private entries = new Map<string, { value: T; at: number }>();

  constructor(private readonly maxAge: number) {}

  get(key: string): T | undefined {
    const entry = this.entries.get(key);
    if (entry && Date.now() - entry.at < this.maxAge) return entry.value;
  }

  set(key: string, value: T): void {
    this.entries.set(key, { value, at: Date.now() });
  }
}
EOF

cat >src/index.ts <<'EOF'
export { today } from "./forecast";
export type { Unit } from "./units";
EOF

cat >test/forecast.test.ts <<'EOF'
import { expect, test } from "vitest";
import { convert } from "../src/units";

test("converts freezing to fahrenheit", () => {
  expect(convert(0, "fahrenheit")).toBe(32);
});
EOF

cat >src/retry.ts <<'EOF'
export async function retry<T>(attempt: () => Promise<T>, times: number): Promise<T> {
  for (let left = times; ; left--) {
    try {
      return await attempt();
    } catch (error) {
      if (left <= 1) throw error;
    }
  }
}
EOF

cat >src/forecast.ts <<'EOF'
import { Cache } from "./cache";
import { convert, type Unit } from "./units";

export interface Reading {
  city: string;
  temperature: number;
  summary: string;
}

const cache = new Cache<Reading>(5 * 60 * 1000);

export async function today(city: string, unit: Unit = "celsius") {
  const reading = cache.get(city) ?? (await fetchReading(city));
  console.log("reading", reading);
  cache.set(city, reading);

  const degrees = convert(reading.temperature, unit);
  return `${city}: ${degrees}° and ${reading.summary}`;
}

async function fetchReading(city: string): Promise<Reading> {
  const response = await fetch(`https://wttr.in/${city}?format=j1`);
  const body = await response.json();
  const current = body.current_condition[0];

  return {
    city,
    temperature: Number(current.temp_C),
    summary: current.weatherDesc[0].value,
  };
}
EOF

committed=(package.json README.md tsconfig.json src/units.ts src/cache.ts src/retry.ts src/index.ts src/forecast.ts
  test/forecast.test.ts)
{
  printf 'commit refs/heads/main\n'
  printf 'author Ada Example <ada@example.com> 1730000000 +0000\n'
  printf 'committer Ada Example <ada@example.com> 1730000000 +0000\n'
  printf 'data 22\nfetch the day forecast\n'
  for path in "${committed[@]}"; do
    printf 'M 100644 inline %s\ndata %d\n' "$path" "$(wc -c <"$path")"
    cat "$path"
    printf '\n'
  done
} | git fast-import --quiet
git reset -q

cat >src/forecast.ts <<'EOF'
import { Cache } from "./cache";
import { retry } from "./retry";
import { convert, type Unit } from "./units";

export interface Reading {
  city: string;
  temperature: number;
  summary: string;
}

const cache = new Cache<Reading>(10 * 60 * 1000);

/** The weather in a city now, served from the cache while fresh. */
export async function today(city: string, unit: Unit = "celsius") {
  const reading = cache.get(city) ?? (await fetchReading(city));
  cache.set(city, reading);

  const degrees = Math.round(convert(reading.temperature, unit));
  return `${city}: ${degrees}° and ${reading.summary.toLowerCase()}`;
}

async function fetchReading(city: string): Promise<Reading> {
  const url = `https://wttr.in/${encodeURIComponent(city)}?format=j1`;
  const response = await retry(() => fetch(url), 3);
  if (!response.ok) {
    throw new Error(`no forecast for ${city}: ${response.status}`);
  }

  const body = await response.json();
  const current = body.current_condition[0];

  return {
    city,
    temperature: Number(current.temp_C),
    summary: current.weatherDesc[0].value,
  };
}
EOF

# A new file in src/, beside its edit, would color src/ differently from run to run: nvim-tree colors a folder holding
# two kinds of change by whichever its unordered status table yields first.
cat >test/retry.test.ts <<'EOF'
import { expect, test } from "vitest";
import { retry } from "../src/retry";

test("gives up after the last attempt", async () => {
  await expect(retry(() => Promise.reject(new Error("down")), 2)).rejects.toThrow("down");
});
EOF

printf '\nInstall it with `npm install forecast`.\n' >>README.md
git add README.md
