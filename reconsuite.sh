#!/bin/bash

# ---------------- COLORS ----------------
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# ---------------- BANNER FUNCTION ----------------
banner() {
clear

printf "${GREEN}"
cat << "EOF"

██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗███████╗██╗   ██╗██╗████████╗███████╗
██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║██╔════╝██║   ██║██║╚══██╔══╝██╔════╝
██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║███████╗██║   ██║██║   ██║   █████╗  
██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╗██║╚════██║██║   ██║██║   ██║   ██╔══╝  
██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║███████║╚██████╔╝██║   ██║   ███████╗
╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝   ╚═╝   ╚══════╝
EOF
printf "${RESET}\n"

printf "${GREEN}        ReconSuite - Recon Automation Engine${RESET}\n\n"

printf "${YELLOW}   [1] Subdomain Enumeration${RESET}  (subfinder, amass)\n"
printf "${YELLOW}   [2] Live Host Detection${RESET}    (httpx)\n"
printf "${YELLOW}   [3] Endpoint Collection${RESET}    (gau, wayback, katana)\n"
printf "${YELLOW}   [4] JS Analysis${RESET}            (secrets + API extraction)\n"
printf "${YELLOW}   [5] Parameter Mining${RESET}       (idor, ssrf, redirect)\n"
printf "${YELLOW}   [6] API Discovery${RESET}          (v1, v2, v3, graphql)\n"
printf "${YELLOW}   [7] API Response Capture${RESET}   (parallel curl)\n"
printf "${YELLOW}   [8] Wordlist Generation${RESET}    (params + API)\n"
printf "${YELLOW}   [9] Fuzzing${RESET}                (ffuf)\n"
printf "${YELLOW}   [10] Vulnerability Scan${RESET}    (nuclei)\n"

printf "\n${CYAN}        Fast | Smart | Automated${RESET}\n"
printf "${GREEN}                 By - Soham${RESET}\n\n"
}

# ---------------- START ----------------
banner

# Disable gau warning
export GAU_CONFIG=/dev/null

# ---------------- TOOL CHECK ----------------
required_tools=("subfinder" "amass" "httpx" "gau" "waybackurls" "katana" "ffuf" "nuclei" "curl")

for tool in "${required_tools[@]}"; do
  if ! command -v $tool &> /dev/null; then
    echo "[ERROR] $tool is not installed"
    exit 1
  fi
done

# ---------------- INPUT ----------------
domain=$1
threads=100

if [ -z "$domain" ]; then
  echo -e "${YELLOW}[INFO] Usage: $0 domain.com${RESET}"
  exit 1
fi

mkdir -p recon/$domain
cd recon/$domain

# --------------------------------------------------

echo "[INFO] Step 1: Subdomain Enumeration"
subfinder -d $domain -silent -all -recursive -t $threads > subs.txt
amass enum -passive -d $domain >> subs.txt
sort -u subs.txt > final_subs.txt
echo "[SUCCESS] Subdomains: $(wc -l < final_subs.txt)"

# --------------------------------------------------

echo "[INFO] Step 2: Live Host Detection"
httpx -l final_subs.txt -silent -threads $threads \
  -ports 80,443,8000,8080,8443 -o live.txt
echo "[SUCCESS] Live Hosts: $(wc -l < live.txt)"

# --------------------------------------------------

echo "[INFO] Step 3: Endpoint Collection"
gau --threads $threads $domain 2>/dev/null > gau.txt
waybackurls $domain > wayback.txt
katana -list live.txt -silent -c $threads -p $threads -o katana.txt

cat gau.txt wayback.txt katana.txt | sort -u > urls.txt
echo "[SUCCESS] URLs collected: $(wc -l < urls.txt)"

# --------------------------------------------------

echo "[INFO] Step 4: JavaScript Analysis"

grep "\.js$" urls.txt > js.txt || true

> secrets.txt
> js_endpoints.txt

if [ -s js.txt ]; then
  cat js.txt | xargs -P $threads -I {} sh -c '
    content=$(curl -s --max-time 10 {});
    echo "$content" | grep -E "api_key|apikey|token|secret|auth";
  ' >> secrets.txt

  cat js.txt | xargs -P $threads -I {} sh -c '
    content=$(curl -s --max-time 10 {});
    echo "$content" | grep -E "/api/|/v1/|/v2/|graphql";
  ' >> js_endpoints.txt
else
  echo "[WARNING] No JavaScript files found"
fi

echo "[SUCCESS] JS analyzed: $(wc -l < js.txt)"

# --------------------------------------------------

echo "[INFO] Step 5: Parameter Mining"

grep "=" urls.txt | sort -u > params.txt || true

grep "id=" params.txt > idor.txt || true
grep "redirect=" params.txt > redirect.txt || true
grep "url=" params.txt > ssrf.txt || true

echo "[SUCCESS] Parameters: $(wc -l < params.txt)"

# --------------------------------------------------

echo "[INFO] Step 6: API Endpoint Extraction"

grep -E "/api/|/v1/|/v2/|graphql|rest" urls.txt js_endpoints.txt \
  | sort -u > api_endpoints.txt || true

echo "[SUCCESS] API endpoints: $(wc -l < api_endpoints.txt)"

# --------------------------------------------------

echo "[INFO] Step 7: API Response Collection"

> api_responses.txt

if [ -s api_endpoints.txt ]; then
  cat api_endpoints.txt | xargs -P $threads -I {} sh -c '
    curl -s --max-time 10 "{}" | head -n 20
  ' >> api_responses.txt
else
  echo "[WARNING] No API endpoints found"
fi

echo "[SUCCESS] API responses collected"

# --------------------------------------------------

echo "[INFO] Step 8: Wordlist Generation"

cat params.txt | sed 's/=.*/=/' | sort -u > param_wordlist.txt || true
cat api_endpoints.txt | awk -F/ '{print $NF}' | sort -u > api_wordlist.txt || true

echo "[SUCCESS] Wordlists generated"

# --------------------------------------------------

echo "[INFO] Step 9: Fuzzing"

ffuf -u http://$domain/FUZZ \
  -w /usr/share/wordlists/dirb/common.txt \
  -t $threads -mc 200,403 \
  -o web_fuzz.json

ffuf -u http://$domain/api/FUZZ \
  -w api_wordlist.txt \
  -t $threads -mc 200,403 \
  -o api_fuzz.json

echo "[SUCCESS] Fuzzing completed"

# --------------------------------------------------

echo "[INFO] Step 10: Vulnerability Scanning"

nuclei -l live.txt \
  -t ~/nuclei-templates/ \
  -severity low,medium,high,critical \
  -c $threads \
  -o nuclei.txt

echo "[SUCCESS] Nuclei scan completed"

# --------------------------------------------------

echo "[INFO] Step 11: Final Aggregation"

cat urls.txt params.txt api_endpoints.txt \
  | sort -u > final_targets.txt

echo -e "\n[SUCCESS] Reconnaissance completed"
echo "[OUTPUT] Location: recon/$domain"