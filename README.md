# Port Traffic Monitor 🔍

A lightweight tool to monitor per-port traffic usage on your Ubuntu server via a live web interface.

## Preview

![Web UI Screenshot](screenshot.png)

## Features
- Real-time traffic monitoring per port
- Simple web UI with auto-refresh
- Reset button to clear stats anytime
- Runs automatically in the background (systemd service)

## Installation

Clone the repository and run the installer:

```bash
git clone https://github.com/YOUR_USERNAME/port-traffic-monitor.git
cd port-traffic-monitor
chmod +x install.sh
./install.sh

The monitor will start automatically as a background service after installation.


---

Access the Web Interface

After installation, open your browser and visit:

http://<your-server-ip>:5000

You'll see a live dashboard showing per-port traffic usage (in MB).
