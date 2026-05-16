#!/usr/bin/env node
/**
 * vii-brain — cross-project persistent memory store for vii-stack.
 *
 * Storage: PGLite (embedded Postgres) at ~/.vii/vii-brain.db/
 *
 * Commands:
 *   init                   create / migrate the database
 *   add <tag> <text...>    store a note (tag: retro, learn, ship, ref, design, …)
 *   search <query...>      full-text search across all entries
 *   list [--tag <tag>]     list recent entries, optionally filtered by tag
 *   remove <id>            delete an entry by id
 */

import { PGlite } from '@electric-sql/pglite';
import os from 'os';
import path from 'path';
import fs from 'fs';
import { execSync } from 'child_process';

const VII_HOME = path.join(os.homedir(), '.vii');
const DB_DIR   = path.join(VII_HOME, 'vii-brain.db');

const SCHEMA = `
CREATE TABLE IF NOT EXISTS entries (
    id         BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    project    TEXT NOT NULL DEFAULT '',
    tag        TEXT NOT NULL,
    body       TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS entries_project_tag ON entries (project, tag);
CREATE INDEX IF NOT EXISTS entries_created     ON entries (created_at DESC);
`;

async function openDb() {
    if (!fs.existsSync(VII_HOME)) fs.mkdirSync(VII_HOME, { recursive: true });
    const db = new PGlite(DB_DIR);
    await db.exec(SCHEMA);
    return db;
}

function currentProject() {
    try {
        const root = execSync('git rev-parse --show-toplevel', { encoding: 'utf8', stdio: ['pipe','pipe','pipe'] }).trim();
        return path.basename(root);
    } catch {
        return path.basename(process.cwd());
    }
}

function fmtRow(row) {
    const ts = new Date(row.created_at).toISOString().slice(0, 16).replace('T', ' ');
    return `[${row.id}] ${ts}  #${row.tag}  ${row.project ? `(${row.project}) ` : ''}${row.body}`;
}

const [cmd, ...args] = process.argv.slice(2);

if (!cmd || cmd === 'help') {
    console.log('Usage: vii-brain <init|add|search|list|remove> [args]');
    console.log('  init                  — create / migrate the database');
    console.log('  add <tag> <text...>   — store a note');
    console.log('  search <query...>     — search entries');
    console.log('  list [--tag <tag>]    — list recent entries');
    console.log('  remove <id>           — delete an entry');
    process.exit(0);
}

switch (cmd) {

    case 'init': {
        const db = await openDb();
        await db.close();
        console.log(`vii-brain: database ready at ${DB_DIR}`);
        break;
    }

    case 'add': {
        if (args.length < 2) {
            console.error('Usage: vii-brain add <tag> <text...>');
            process.exit(1);
        }
        const [tag, ...bodyParts] = args;
        const body = bodyParts.join(' ');
        const project = currentProject();
        const db = await openDb();
        const result = await db.query(
            'INSERT INTO entries (project, tag, body) VALUES ($1, $2, $3) RETURNING id',
            [project, tag, body]
        );
        await db.close();
        console.log(`vii-brain: stored [${result.rows[0].id}] #${tag}`);
        break;
    }

    case 'search': {
        if (args.length === 0) {
            console.error('Usage: vii-brain search <query...>');
            process.exit(1);
        }
        const query = args.join(' ');
        const pattern = `%${query}%`;
        const db = await openDb();
        const result = await db.query(
            `SELECT id, created_at, project, tag, body
             FROM entries
             WHERE body ILIKE $1 OR tag ILIKE $1
             ORDER BY created_at DESC
             LIMIT 20`,
            [pattern]
        );
        await db.close();
        if (result.rows.length === 0) {
            console.log('vii-brain: no results');
        } else {
            result.rows.forEach(r => console.log(fmtRow(r)));
        }
        break;
    }

    case 'list': {
        const tagIdx = args.indexOf('--tag');
        const tag    = tagIdx !== -1 ? args[tagIdx + 1] : null;
        const db     = await openDb();
        const result = tag
            ? await db.query(
                'SELECT id, created_at, project, tag, body FROM entries WHERE tag = $1 ORDER BY created_at DESC LIMIT 50',
                [tag])
            : await db.query(
                'SELECT id, created_at, project, tag, body FROM entries ORDER BY created_at DESC LIMIT 50');
        await db.close();
        if (result.rows.length === 0) {
            console.log('vii-brain: no entries');
        } else {
            result.rows.forEach(r => console.log(fmtRow(r)));
        }
        break;
    }

    case 'remove': {
        const id = parseInt(args[0], 10);
        if (!id) { console.error('Usage: vii-brain remove <id>'); process.exit(1); }
        const db = await openDb();
        const result = await db.query('DELETE FROM entries WHERE id = $1 RETURNING id', [id]);
        await db.close();
        if (result.rows.length === 0) {
            console.error(`vii-brain: no entry with id ${id}`);
            process.exit(1);
        }
        console.log(`vii-brain: removed [${id}]`);
        break;
    }

    default:
        console.error(`vii-brain: unknown command '${cmd}'`);
        process.exit(1);
}
