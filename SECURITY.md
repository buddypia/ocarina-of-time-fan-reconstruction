# Security Policy / セキュリティポリシー

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.5.x   | :white_check_mark: |
| < 0.5   | :x:                |

---

## Reporting a Vulnerability or Accidental Secret Leak

We take the security of this project and the protection of credentials, keys, and private data very seriously.

### What to Report:
1. **Accidental Credential / API Key Leaks**: If you discover any active API tokens, private keys, passwords, or personal credentials accidentally committed to the repository.
2. **Arbitrary Code Execution / Engine Exploits**: Vulnerabilities in save file deserialization (`JSON.parse_string`), mod loading, or external script execution that could allow malicious code execution on a player's machine.
3. **Path Traversal / Local File Overwrite**: Issues where save paths or asset paths might write outside the intended directory.

### How to Report:
- Please **DO NOT** report security vulnerabilities or exposed secrets via public GitHub Issues, Pull Requests, or Discussions.
- Instead, submit a confidential report using **GitHub Private Vulnerability Reporting** (under the repository's Security tab -> "Report a vulnerability").
- If Private Vulnerability Reporting is unavailable, contact the project maintainers via email or private channel.

### Response Timeline:
- **Acknowledgement**: Within 48 hours.
- **Assessment & Mitigation**: We will review the finding, rotate/invalidate any exposed credentials immediately, and purge sensitive git history via git filter-repo / BFG if necessary.
- **Security Advisory**: A public patch and advisory will be published once the issue is mitigated.

---

## Policy on Copyrighted Data Submissions

If any user or contributor inadvertently submits proprietary game ROMs, proprietary binaries, or copyrighted Nintendo assets:
- These will be immediately removed from the pull request or repository.
- Branches containing copyrighted data will be permanently purged.
- Please see [LEGAL_DISCLAIMER.md](LEGAL_DISCLAIMER.md) and [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.
