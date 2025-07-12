#!/bin/bash

# ------------------------------
# Port Traffic Monitor Installer
# ------------------------------

echo ""
echo "📡 Installing Port Traffic Monitor..."
echo ""

# Install dependencies
sudo apt update && sudo apt install -y python3 python3-pip iptables curl
pip3 install flask

# Create working directory
INSTALL_DIR="/opt/port-traffic-monitor"
sudo mkdir -p "$INSTALL_DIR"
sudo chown "$USER" "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit 1

# Prompt for ports
echo ""
echo "Enter the ports you want to monitor (space-separated, e.g., 80 443 8080):"
read -r PORTS

# Save port list to a file
echo "$PORTS" > ports.txt

# Create monitor.py
cat <<EOF > monitor.py
import os
import sys
import json
import threading
import time
import subprocess
from flask import Flask, jsonify, render_template

app = Flask(__name__)

# Load ports
with open("ports.txt") as f:
    ports_to_monitor = [int(p) for p in f.read().strip().split()]

TRAFFIC_FILE = "traffic.json"

def get_traffic_stats():
    stats = {}
    try:
        result = subprocess.check_output("iptables -L -v -n", shell=True).decode()
        for line in result.splitlines():
            for port in ports_to_monitor:
                if f"dpt:{port}" in line or f"spt:{port}" in line:
                    parts = line.split()
                    bytes_count = parts[1]
                    try:
                        bytes_int = int(bytes_count)
                    except ValueError:
                        if bytes_count[-1] == 'M':
                            bytes_int = int(float(bytes_count[:-1]) * 1_000_000)
                        elif bytes_count[-1] == 'K':
                            bytes_int = int(float(bytes_count[:-1]) * 1_000)
                        else:
                            bytes_int = 0
                    if f"dpt:{port}" in line:
                        stats.setdefault(str(port), {"received_bytes": 0, "sent_bytes": 0})
                        stats[str(port)]["received_bytes"] += bytes_int
                    if f"spt:{port}" in line:
                        stats.setdefault(str(port), {"received_bytes": 0, "sent_bytes": 0})
                        stats[str(port)]["sent_bytes"] += bytes_int
    except Exception as e:
        print(f"Error reading iptables: {e}")
    return stats

def save_stats():
    stats = get_traffic_stats()
    with open(TRAFFIC_FILE, "w") as f:
        json.dump(stats, f)

def loop():
    while True:
        save_stats()
        time.sleep(10)

@app.route("/")
def home():
    if not os.path.exists(TRAFFIC_FILE):
        return "Traffic data is not yet available.", 503
    try:
        with open(TRAFFIC_FILE, "r") as f:
            data = json.load(f)
        return render_template("index.html", stats=data)
    except Exception as e:
        return f"Error loading data: {e}", 500

@app.route("/api")
def api():
    try:
        with open(TRAFFIC_FILE, "r") as f:
            return jsonify(json.load(f))
    except:
        return jsonify({})

@app.route("/reset", methods=["POST"])
def reset():
    subprocess.run("iptables -Z", shell=True)
    with open(TRAFFIC_FILE, "w") as f:
        json.dump({}, f)
    return jsonify({"status": "reset_done"})

if __name__ == "__main__":
    threading.Thread(target=loop, daemon=True).start()
    app.run(host="0.0.0.0", port=5000)
EOF

# Create HTML UI
echo "Creating web interface..."
mkdir -p templates
cat <<EOF > templates/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Port Traffic Monitor</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-dark text-light">
<div class="container mt-5">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h2>📊 Port Traffic Monitor</h2>
        <button onclick="resetTraffic()" class="btn btn-danger">🔁 Reset</button>
    </div>
    <table class="table table-striped table-dark table-bordered">
        <thead>
        <tr>
            <th>Port</th>
            <th>Received (MB)</th>
            <th>Sent (MB)</th>
        </tr>
        </thead>
        <tbody id="traffic-table"></tbody>
    </table>
</div>
<script>
    async function fetchData() {
        const res = await fetch('/api');
        const data = await res.json();
        const table = document.getElementById("traffic-table");
        table.innerHTML = "";
        Object.entries(data).forEach(([port, val]) => {
            const rx = (val.received_bytes / 1000000).toFixed(2);
            const tx = (val.sent_bytes / 1000000).toFixed(2);
            table.innerHTML += \`<tr><td>\${port}</td><td>\${rx}</td><td>\${tx}</td></tr>\`;
        });
    }
    async function resetTraffic() {
        if (confirm("Are you sure to reset traffic stats?")) {
            await fetch("/reset", {method: "POST"});
            fetchData();
        }
    }
    fetchData();
    setInterval(fetchData, 5000);
</script>
</body>
</html>
EOF

# Create systemd service
echo "Creating systemd service..."
SERVICE_FILE="/etc/systemd/system/port-traffic-monitor.service"
sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Port Traffic Monitor Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 $INSTALL_DIR/monitor.py
WorkingDirectory=$INSTALL_DIR
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable port-traffic-monitor.service
sudo systemctl start port-traffic-monitor.service

echo ""
echo "✅ Port Traffic Monitor installed and running!"
echo "🌐 Visit: http://<your-server-ip>:5000"
