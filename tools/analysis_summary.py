import json
import collections
import sys
import os
path='analyze_report.json'
if not os.path.exists(path):
    print('ERROR: analyze_report.json not found')
    sys.exit(2)
items=[]
with open(path,'r',encoding='utf-8') as f:
    for line in f:
        line=line.strip()
        if not line:
            continue
        try:
            items.append(json.loads(line))
        except Exception:
            continue
issues=[]
for obj in items:
    if obj.get('type')=='analysis.issues':
        for issue in obj.get('issues',[]):
            issues.append(issue)
# fallback: some entries might be single 'issue' messages
for obj in items:
    if obj.get('type')=='analysis.issue':
        issues.append(obj.get('issue'))
severity_counts=collections.Counter()
file_counts=collections.Counter()
for i in issues:
    sev=i.get('severity') or i.get('kind') or 'unknown'
    severity_counts[sev]+=1
    loc=i.get('location') or {}
    file=loc.get('file') or i.get('file') or '<unknown>'
    file_counts[file]+=1
summary={
    'total_issues': len(issues),
    'severity_counts': dict(severity_counts),
    'top_files': file_counts.most_common(30)
}
print(json.dumps(summary, ensure_ascii=False, indent=2))
print('\nTOTAL_ISSUES', summary['total_issues'])
print('SEVERITY_COUNTS', summary['severity_counts'])
print('TOP_FILES:')
for f,c in summary['top_files']:
    print(f, c)
