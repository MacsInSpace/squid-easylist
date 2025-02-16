#!/bin/bash

# Array of URLs (comment out any you don't want to use)
urls=(
  "https://easylist.to/easylist/easylist.txt"
  "https://secure.fanboy.co.nz/fanboy-cookiemonster.txt"
  "https://easylist.to/easylist/easyprivacy.txt"
  "https://secure.fanboy.co.nz/fanboy-annoyance.txt"
  "https://easylist.to/easylist/fanboy-social.txt"
)

# Temporary directory for downloads
tmp_dir=$(mktemp -d)
list="/etc/squid/ad_block.txt"

# Function to clean up temporary files
rm_temp() {
  rm -rf "${tmp_dir}"
  rm -f /tmp/adblock.sed
}

# Create sed filter file
cat > /tmp/adblock.sed <<'EOF'
/.*\$.*/d;
/\n/d;
/.*\#.*/d;
/@@.*/d;
/^!.*/d;
s/\[\]/\[.\]/g;
s#http://#||#g;
s/\/\//||/g
s/^\[.*\]$//g;
s,[+.?&/|],\\&,g;
s#*#.*#g;
s,\$.*$,,g;
s/\\|\\|\(.*\)\^\(.*\)/\.\1\\\/\2/g;
s/\\|\\|\(.*\)/\.\1/g;
/^\.\*$/d;
/^$/d;
EOF

# Backup old list
if [[ -f "$list" ]]; then
  mv "$list" "$list".old
fi

# Download and process each URL
for url in "${urls[@]}"; do
  echo "Downloading $url..."
  wget -q "$url" -P "$tmp_dir" || {
    echo "Failed to download $url"
    continue
  }
done

# Combine, filter, and remove duplicates
cat "$tmp_dir"/* | sed -f /tmp/adblock.sed | sort -u > "$list"

# Clean up temporary files
rm_temp

# Reload Squid and show status
systemctl reload squid && echo "Squid reloaded successfully"
systemctl status squid --no-pager

echo "Adblock list updated at $list"
