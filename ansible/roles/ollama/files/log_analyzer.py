#!/usr/bin/env python3
import re
from collections import Counter, deque
from pathlib import Path

LOG_FILES = ["/var/log/auth.log", "/var/log/syslog", "/var/log/messages"]
ALERT_FILE = Path("/var/log/ollama/alerts.log")
ANALYSIS_FILE = Path("/var/log/ollama/analysis.log")

PATTERNS = [
    {
        "name": "failed_password",
        "regex": re.compile(r"Failed password for (?P<user>\S+) from (?P<ip>\S+)", re.I),
    },
    {
        "name": "invalid_user",
        "regex": re.compile(r"Invalid user (?P<user>\S+) from (?P<ip>\S+)", re.I),
    },
    {
        "name": "auth_failure",
        "regex": re.compile(r"authentication failure;.*rhost=(?P<ip>\S+)", re.I),
    },
]

THRESHOLD = 5
TAIL_LINES = 1000


def tail_lines(path, n=TAIL_LINES):
    if not path.exists():
        return []
    with path.open("r", errors="ignore") as f:
        return list(deque(f, maxlen=n))


def analyze_logs():
    counts = Counter()
    alerts = []

    for log_path in LOG_FILES:
        for line in tail_lines(Path(log_path)):
            for pattern in PATTERNS:
                match = pattern["regex"].search(line)
                if match:
                    ip = match.groupdict().get("ip", "unknown")
                    user = match.groupdict().get("user", "unknown")
                    key = (pattern["name"], ip)
                    counts[key] += 1

    for (reason, ip), count in counts.items():
        if count >= THRESHOLD:
            alerts.append(
                f"[ALERT] {reason} detected {count} times from IP={ip} in recent logs"
            )

    if alerts:
        ALERT_FILE.parent.mkdir(parents=True, exist_ok=True)
        with ALERT_FILE.open("a") as f:
            f.write("\n".join(alerts) + "\n")
        with ANALYSIS_FILE.open("a") as f:
            f.write("\n".join(alerts) + "\n")
        print("Alerts generated:\n" + "\n".join(alerts))
    else:
        with ANALYSIS_FILE.open("a") as f:
            f.write("No suspicious patterns detected.\n")
        print("No suspicious patterns detected.")


if __name__ == "__main__":
    analyze_logs()
