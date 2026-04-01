import sqlite3
import os
import re

proj_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
init_path = os.path.join(proj_root, 'backend', 'init.sql')
db_path = os.path.join(proj_root, 'backend', 'local.db')

if not os.path.exists(init_path):
    print('ERROR: init.sql not found at', init_path)
    raise SystemExit(2)

with open(init_path, 'r', encoding='utf-8') as f:
    data = f.read()

# Remove markdown fences if present (``` or ```sql)
data = re.sub(r"^```(?:sql)?\s*", '', data, flags=re.MULTILINE)
data = re.sub(r"\n```\s*$", '\n', data, flags=re.MULTILINE)

# Ensure the directory exists
os.makedirs(os.path.dirname(db_path), exist_ok=True)

# Write to sqlite DB
if os.path.exists(db_path):
    print('Overwriting existing DB at', db_path)
    os.remove(db_path)

conn = sqlite3.connect(db_path)
try:
    conn.executescript(data)
    conn.commit()
    print('Database created at', db_path)
    # List tables
    cur = conn.cursor()
    cur.execute("SELECT name, type FROM sqlite_master WHERE type IN ('table','view') ORDER BY name;")
    rows = cur.fetchall()
    print('\nTables/Views:')
    for name, typ in rows:
        print('-', name, '(', typ, ')')
    # Show counts for important tables
    important = ['users','taxes','payments']
    print('\nRow counts:')
    for t in important:
        try:
            cur.execute(f'SELECT COUNT(*) FROM {t}')
            c = cur.fetchone()[0]
            print(f' - {t}:', c)
        except Exception as e:
            print(f' - {t}: error ({e})')
finally:
    conn.close()
