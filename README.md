# Port Traffic Monitor 🔍

A lightweight and simple tool to monitor **per-port traffic usage** on your Ubuntu server through a live web interface.

## 🔥 Features

- 📊 Real-time traffic monitoring per port  
- 💻 Clean web UI with auto-refresh  
- 🔄 One-click reset to clear stats  
- 🛠️ Runs automatically in the background as a **systemd service**

---

## 🚀 Quick Install 

اگر فقط می‌خوای سریع نصبش کنی و راه بندازی، این دستور رو در ترمینال بزن:

```bash
git clone https://github.com/isajad7/port-traffic-monitor.git && cd port-traffic-monitor && chmod +x install.sh && ./install.sh
```

<h2>
در حین نصب، از شما خواسته می‌شود پورت‌هایی را که مایل به مانیتور کردن آن‌ها هستید وارد کنید. لطفاً شماره پورت‌ها را با فاصله از یکدیگر جدا نمایید.
</h2>




🌐 Access the Web Interface
پس از نصب، مرورگر را باز کنید و به آدرس زیر بروید:


```
http://<your-server-ip>:5000
```
در آنجا یک داشبورد زنده مشاهده خواهید کرد که میزان ترافیک هر پورت را به‌صورت لحظه‌ای (MB) نمایش می‌دهد.
