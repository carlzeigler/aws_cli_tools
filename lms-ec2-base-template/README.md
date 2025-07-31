# LMS Base EC2 Launch Template

## Quickstart
1. **Create the launch template**  
```bash
./create_launch_template.sh
```

2. **Launch an instance**  
```bash
./launch_instance.sh myserver dev.lms4all.com nginx
```

3. **Access your instance**  
- SSH: `ssh -i <your-key>.pem jcz@<instance-public-ip>`  
- Web: `https://myserver.dev.lms4all.com`  


This repository provides scripts to create and manage a hardened RHEL 8 EC2 Launch Template with optional CloudWatch logging.

## Features
- **Configurable hostname, domain, and web server (Apache/Nginx)** using EC2 tags.
- **Users:** `jcz` (with sudo) and `sas` (group `sas`), each with their own SSH key pair.
- **Security:** Disables root SSH, enforces key-based auth, logs sudo commands.
- **Web:** Self-signed CA and HTTPS setup with HTTP->HTTPS redirect.
- **Storage:** Mounts a secondary EBS volume (`/dev/sdb`) at `/data/v1`.
- **Firewall:** Opens SSH (22) and HTTPS (443).
- **Optional CloudWatch:** Sends logs (sudo, web server, system) to CloudWatch.

## File Overview
- `create_launch_template.sh` – Creates the EC2 Launch Template with your chosen options.
- `hardened_userdata.sh` – User data for instance configuration (base script).
- `hardened_userdata_with_cw.sh` – Same as above, but adds CloudWatch logging.
- `launch_instance.sh` – Helper script to quickly launch new instances with tags.

## Prerequisites
1. AWS CLI installed and configured (`aws configure`).
2. An existing key pair (`lms-pem-7`) in **us-east-1**.
3. An existing security group (`launch-wizard-1`).
4. IAM permissions to create launch templates and run instances.

## Step 1: Create the Launch Template
Edit `create_launch_template.sh` to adjust:
- `ENABLE_CLOUDWATCH` to `true` or `false`.
- Key pair name, security group, etc.

Then run:
```bash
./create_launch_template.sh
```

This will create the launch template `LMS-Base-Launch-Template`.

## Step 2: Launch an Instance
Use the helper script:
```bash
./launch_instance.sh <Hostname> [Domain] [WebServer]
```
Examples:
```bash
./launch_instance.sh web01        # Hostname=web01, Domain=lms4all.com, WebServer=apache
./launch_instance.sh web02 dev.lms4all.com nginx
```

Or use AWS CLI directly:
```bash
aws ec2 run-instances   --launch-template LaunchTemplateName=LMS-Base-Launch-Template   --tag-specifications 'ResourceType=instance,Tags=[{Key=Hostname,Value=web01},{Key=Domain,Value=dev.lms4all.com},{Key=WebServer,Value=nginx}]'
```

### Tag Defaults
- `Hostname` → `ec2-default-host`
- `Domain` → `lms4all.com`
- `WebServer` → `apache`

## Step 3: Access the Instance
- SSH using the key pair (`lms-pem-7`) as user `jcz`.
- HTTPS website will be available at `https://<Hostname>.<Domain>`.

## Notes
- Change `AMI_ID` in `create_launch_template.sh` if Red Hat updates the AMI.
- Extend the CloudWatch config for additional log sources if needed.
- SSM IAM role integration can be added later for SSH-less access.

## Contributing
Contributions are welcome! Please:
1. Fork the repo.
2. Create a feature branch.
3. Submit a pull request with a clear description of changes.

## License
This project is licensed under the MIT License (see `LICENSE` for details).


## Recommended GitHub Settings (Optional)
> These are **not enforced** but recommended for maintaining code quality.
>
> In your repository settings under **Branches → Branch protection rules**, you may want to:
> - Require pull request reviews before merging.
> - Require status checks to pass before merging (e.g., CI linting).
> - Require branches to be up to date before merging.
> - Disallow force pushes and deletions on `main`.



## Project Structure

```
lms-ec2-base-template/
├── README.md                      # Project overview and usage instructions
├── LICENSE                        # MIT license
├── CHANGELOG.md                   # Version history
├── .gitignore                     # Git ignore rules
├── create_launch_template.sh      # Script to create the EC2 launch template
├── launch_instance.sh             # Helper script to launch instances
├── hardened_userdata.sh           # Base user data script (Apache/Nginx)
├── hardened_userdata_with_cw.sh   # User data script with CloudWatch logging
├── .github/
│   ├── PULL_REQUEST_TEMPLATE.md   # Pull request template
│   ├── workflows/
│   │   └── lint.yml               # GitHub Actions workflow for linting
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md          # Bug report template
│       └── feature_request.md     # Feature request template
```



## Screenshots

### AWS Console: Launch Template
![AWS Console Launch Template](docs/images/launch-template.png)

### AWS Console: Running Instance
![AWS Console Instance](docs/images/running-instance.png)

### Sample HTTPS Web Page
![Sample HTTPS Page](docs/images/sample-webpage.png)

> **Note:** Add screenshots to `docs/images/` when available.


## Contributor Tasks
- [ ] Replace placeholder screenshots in `docs/images/` with actual images:
  - [ ] `launch-template.png` – Screenshot of AWS Launch Template page.
  - [ ] `running-instance.png` – Screenshot of a running EC2 instance in AWS Console.
  - [ ] `sample-webpage.png` – Screenshot of the sample HTTPS page in a browser.
- [ ] Verify README links after adding images.
- [ ] Update CHANGELOG.md with the addition of screenshots.
