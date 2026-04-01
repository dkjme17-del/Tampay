import re
from collections import Counter
p = 'analyze_plain.txt'
try:
    with open(p, 'r', encoding='utf-8') as f:
        lines = f.readlines()
except Exception as e:
    print('ERROR reading', p, e)
    raise SystemExit(2)
# Pattern to capture file path like lib\foo\bar.dart:123:4
pattern = re.compile(r"([\w\\/\.\- ]+\.(dart|yaml|kt|gradle|kts)):(\d+):(\d+)")
file_counts = Counter()
for ln in lines:
    m = pattern.search(ln)
    if m:
        fp = m.group(1).replace('\\','/')
        file_counts[fp] += 1
print('TOTAL_LINES', len(lines))
print('TOTAL_FILES_WITH_ISSUES', len(file_counts))
print('TOP_FILES:')
for f,c in file_counts.most_common(40):
    print(f, c)
