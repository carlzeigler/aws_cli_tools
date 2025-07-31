# First Public Release Checklist (v1.0.0)

Follow these steps to publish the first release of the LMS Base EC2 Launch Template:

## 1. Prepare the Repository
- [ ] Create a new GitHub repository (e.g., `lms-ec2-base-template`).
- [ ] Extract the contents of `lms-ec2-base-template.tar.gz` and push them to the `main` branch:
  ```bash
  tar -xvzf lms-ec2-base-template.tar.gz
  cd lms-ec2-base-template
  git init
  git remote add origin git@github.com:<your-org>/lms-ec2-base-template.git
  git add .
  git commit -m "Initial commit: v1.0.0"
  git push -u origin main
  ```

## 2. Configure GitHub Repository
- [ ] Add branch protection rules for `main` (see README recommendations).
- [ ] Ensure GitHub Actions are enabled (for linting and syntax checks).
- [ ] Update repository description and tags.

## 3. Add Screenshots
- [ ] Replace placeholder screenshots in `docs/images/` with actual images:
  - [ ] AWS Launch Template page
  - [ ] Running EC2 instance
  - [ ] Sample HTTPS web page

## 4. Create the Release
- [ ] Go to **Releases** in GitHub.
- [ ] Click **Draft a new release**.
- [ ] Set **Tag version**: `v1.0.0`.
- [ ] Set **Release title**: `v1.0.0 - Initial Release`.
- [ ] Paste contents of `RELEASE_DRAFT_v1.0.0.md` into the release notes.
- [ ] Publish the release.

## 5. Post-Release
- [ ] Announce the release internally or to the community.
- [ ] Monitor issues and feedback for future updates.
