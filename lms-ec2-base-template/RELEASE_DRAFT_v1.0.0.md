# v1.0.0 - Initial Release

## Summary
This is the first release of **LMS Base EC2 Launch Template**, a hardened and configurable RHEL 8 EC2 Launch Template for AWS.

## Features
- Hardened RHEL 8 configuration:
  - SSH hardening (no root login, key-only authentication).
  - Sudo logging (`/var/log/sudo.log`).
- Configurable via EC2 tags:
  - `Hostname` (default: `ec2-default-host`)
  - `Domain` (default: `lms4all.com`)
  - `WebServer` (`apache` or `nginx`, default: `apache`)
- Web server setup:
  - HTTPS with a self-signed CA and redirect from HTTP.
  - Apache or Nginx selectable at launch.
- Storage setup:
  - Secondary volume `/dev/sdb` auto-mounted at `/data/v1`.
- Optional CloudWatch logging for system, sudo, and web logs.
- Preconfigured firewall (SSH + HTTPS).

## Repository Enhancements
- **README.md** with Quickstart, usage instructions, and project structure.
- **CHANGELOG.md** tracking changes.
- **CONTRIBUTING.md**, **CODE_OF_CONDUCT.md**, and GitHub issue/PR templates.
- **GitHub Actions CI** for script linting and syntax checks.

## Installation
1. Clone the repository.
2. Edit `create_launch_template.sh` to set your configuration (key pair, security group, CloudWatch option).
3. Run `./create_launch_template.sh` to create the template.
4. Launch instances using `./launch_instance.sh`.

## Next Steps
- Add SSM IAM role integration for SSH-less management.
- Add prebuilt CloudWatch dashboards.

---
*Release Date: 2025-07-31*
