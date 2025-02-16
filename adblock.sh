#!/bin/bash

# Temporary directory
tmp_dir=$(mktemp -d)

# Clean up function
rm_temp() {
    rm -rf "${tmp_dir}"
    rm /tmp/adblock.sed
}

# Output list path
list="/etc/squid/ad_block.txt"

# Sed script for filtering
cat > /tmp/adblock.sed <<'EOF'
/.*\$.*/d;
/\n/d;
/.*\#.*/d;
/@@.*/d;
/^!.*/d;
s/\[\]/\[.\]/g;
s#http://#||#g;
s/\/\//||/g;
s/^\[.*\]$//g;
s,[+.?&/|],\\&,g;
s#*#.*#g;
s,\$.*$,,g;
s/\\|\\|\(.*\)\^\(.*\)/\.\1\\\/\2/g;
s/\\|\\|\(.*\)/\.\1/g;
/^\.\*$/d;
/^$/d;
EOF

# URLs for ad-blocking lists
declare -A lists=(
    ["EasyList"]="https://easylist.to/easylist/easylist.txt"
    ["EasyPrivacy"]="https://easylist.to/easylist/easyprivacy.txt"
    ["FanboyCookies"]="https://secure.fanboy.co.nz/fanboy-cookiemonster.txt"
    ["FanboyAnnoyance"]="https://secure.fanboy.co.nz/fanboy-annoyance.txt"
    ["FanboySocial"]="https://easylist.to/easylist/fanboy-social.txt"
)

# Backup current list
mv "$list" "$list.old"

# Fetch and combine lists
for key in "${!lists[@]}"; do
    echo "Downloading ${key}..."
    wget -q -O - "${lists[$key]}" | sed -f /tmp/adblock.sed >> "${tmp_dir}/combined.txt"
done

# Remove duplicates and save
sort -u "${tmp_dir}/combined.txt" > "$list"

# Clean up
rm_temp

# Reload Squid
systemctl reload squid && echo "Squid reloaded with updated ad-block list"
systemctl status squid --no-pager
