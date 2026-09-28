// Runs every supabase/tests/*.test.sql on a fresh in-memory Postgres (PGlite):
// Supabase stub -> migrations (in order) -> seed.sql if present -> helpers -> test.
// A test fails if any statement raises. Usage: npm run test:db [filter]

import { readdir, readFile } from 'node:fs/promises'
import { existsSync } from 'node:fs'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { PGlite } from '@electric-sql/pglite'

const root = fileURLToPath(new URL('../supabase/', import.meta.url))
const read = (...p) => readFile(join(root, ...p), 'utf8')

const migrations = (await readdir(join(root, 'migrations'))).filter((f) => f.endsWith('.sql')).sort()
const filter = process.argv[2] ?? ''
const tests = (await readdir(join(root, 'tests')))
  .filter((f) => f.endsWith('.test.sql') && f.includes(filter))
  .sort()

const stub = await read('tests', '_supabase_stub.sql')
const helpers = await read('tests', '_helpers.sql')
const seed = existsSync(join(root, 'seed.sql')) ? await read('seed.sql') : null
const migrationSql = await Promise.all(migrations.map((f) => read('migrations', f)))

let failed = 0
for (const test of tests) {
  const db = new PGlite()
  try {
    await db.exec(stub)
    for (const [i, sql] of migrationSql.entries()) {
      try {
        await db.exec(sql)
      } catch (e) {
        throw new Error(`migration ${migrations[i]}: ${e.message}`)
      }
    }
    if (seed) await db.exec(seed)
    await db.exec(helpers)
    await db.exec(await read('tests', test))
    console.log(`  ok    ${test}`)
  } catch (e) {
    failed++
    console.log(`  FAIL  ${test}\n        ${e.message}`)
  } finally {
    await db.close()
  }
}

console.log(`\n${tests.length - failed}/${tests.length} test files passed`)
process.exitCode = failed ? 1 : 0
