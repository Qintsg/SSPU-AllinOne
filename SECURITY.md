# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |
| < latest | :x:               |

Only the latest release receives security updates. Please always update to the most recent version.

## Reporting a Vulnerability

If you discover a security vulnerability in SSPU-AllinOne, please report it responsibly.

**Do NOT open a public GitHub Issue for security vulnerabilities.**

Instead, please report via email to:

**qintanshiguang@163.com**

### What to include

- A description of the vulnerability
- Steps to reproduce the issue
- The potential impact
- Any suggested fix (if available)

### Response timeline

- **Acknowledgment**: within 48 hours
- **Initial assessment**: within 5 business days
- **Fix or mitigation**: depends on severity, typically within 14 days for critical issues

### What to expect

- You will receive an acknowledgment of your report
- We will work with you to understand and validate the issue
- A fix will be developed and tested privately
- A security advisory will be published when the fix is released
- You will be credited in the advisory (unless you prefer to remain anonymous)

## Scope

This policy covers the SSPU-AllinOne application code in this repository, including:

- Flutter application code (`lib/`)
- Platform-specific code (`android/`, `ios/`, `macos/`, `linux/`, `windows/`)
- Build and release scripts (`scripts/`, `.github/`)

### Out of scope

- Third-party dependencies (report to their respective maintainers)
- Social engineering attacks
- Issues requiring physical access to the user's device

## Security Best Practices for Contributors

- Never commit secrets, API keys, tokens, passwords, or credentials
- Use `flutter_secure_storage` for sensitive user data
- Do not log sensitive information
- All external network requests should be validated
- User data stays on device — do not introduce cloud sync without explicit discussion

## Credits

This security policy is adapted from standard open source security practices.
