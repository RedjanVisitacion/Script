import os
import time
import subprocess

# --- CONFIG ---
DB_NAME = "studentdb"
DB_USER = "root"
DB_PASSWORD = ""  # empty if none
BACKUP_DIR = r"F:\flutter_django_crud_backup_script\database_backups"
MYSQLDUMP_PATH = r"F:\xp\mysql\bin\mysqldump.exe"  # full path to mysqldump.exe

# --- Ensure backup folder exists ---
os.makedirs(BACKUP_DIR, exist_ok=True)

# --- Create backup filename ---
timestamp = time.strftime("%Y%m%d-%H%M%S")
backup_file = os.path.join(BACKUP_DIR, f"{DB_NAME}_{timestamp}.sql")

# --- Build command ---
if DB_PASSWORD == "":
    cmd = [MYSQLDUMP_PATH, '-u', DB_USER, DB_NAME]
else:
    cmd = [MYSQLDUMP_PATH, '-u', DB_USER, f'-p{DB_PASSWORD}', DB_NAME]

# --- Run backup ---
with open(backup_file, 'w', encoding='utf-8') as f:
    result = subprocess.run(cmd, stdout=f, stderr=subprocess.PIPE, text=True)

if result.returncode == 0:
    print(f"✅ Database backup completed: {backup_file}")
else:
    print("❌ Backup failed!")
    print(result.stderr)