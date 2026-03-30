# ReconSuite

Fast | Smart | Automated Reconnaissance Engine

ReconSuite is a high-performance automation framework designed for security researchers, bug bounty hunters, and penetration testers. It streamlines the reconnaissance process by integrating multiple industry-standard tools into a single workflow.

---

## Banner

<img width="694" height="415" alt="image" src="https://github.com/user-attachments/assets/f5297aab-11ff-416b-92bd-b29849439db9" />

---

## Overview

ReconSuite automates the complete reconnaissance lifecycle:

* Subdomain discovery
* Live host identification
* Endpoint and URL collection
* JavaScript analysis for secrets
* Parameter and API discovery
* Fuzzing and vulnerability scanning

---

## Features

* Subdomain Enumeration — subfinder, amass
* Live Host Detection — httpx
* Endpoint Collection — gau, waybackurls, katana
* JavaScript Analysis — extract API keys, tokens, secrets
* Parameter Mining — IDOR, SSRF, Open Redirect
* API Discovery — REST, GraphQL endpoints
* API Response Capture — parallel curl requests
* Wordlist Generation — custom fuzzing inputs
* Fuzzing — ffuf
* Vulnerability Scanning — nuclei

---

## Screenshots

<img width="1360" height="73" alt="image" src="https://github.com/user-attachments/assets/29a44bf1-7baf-4051-9ad0-d428f5c08ff8" />

---

## Requirements

Ensure the following tools are installed:

* subfinder
* amass
* httpx
* gau
* waybackurls
* katana
* ffuf
* nuclei
* curl

---

## Installation

```bash
git clone https://github.com/soham1111111/reconsuite.git
```

```bash
cd reconsuite
```

```bash
chmod +x recon.sh
```

---

## Usage

```bash
./recon.sh target.com
```

Example:

```bash
./recon.sh example.com
```

---

## Output Structure

```
recon/
 └── target.com/
      ├── final_subs.txt
      ├── live.txt
      ├── urls.txt
      ├── params.txt
      ├── api_endpoints.txt
      ├── secrets.txt
      ├── nuclei.txt
      └── final_targets.txt
```

---

## Performance

* Multi-threaded execution (default: 100 threads)
* Parallel processing for faster results
* Optimized for large-scale reconnaissance

---

## Contributing

1. Fork the repository
2. Create a new branch
3. Commit your changes
4. Submit a Pull Request

---

## License

This project is licensed under the MIT License.

---

## Author

Soham

---
