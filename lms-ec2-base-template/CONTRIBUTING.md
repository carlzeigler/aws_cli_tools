# Contributing to LMS Base EC2 Launch Template

Thank you for considering contributing! We welcome contributions to improve this project.

## How to Contribute

1. **Fork the repository**  
   Create your own fork of the repository.

2. **Create a feature branch**  
   ```bash
   git checkout -b feature/my-feature
   ```

3. **Make changes**  
   - Follow project coding standards.
   - Update documentation if your change affects usage.

4. **Test your changes**  
   Ensure all scripts pass linting and basic validation:
   ```bash
   shellcheck *.sh
   for file in *.sh; do bash -n "$file"; done
   ```

5. **Commit changes**  
   Use clear, concise commit messages:
   ```bash
   git commit -m "Add feature: description of change"
   ```

6. **Push to your fork**  
   ```bash
   git push origin feature/my-feature
   ```

7. **Open a Pull Request**  
   Provide details using the pull request template.

## Reporting Issues
- Use the **bug report template** for bugs.
- Use the **feature request template** for new ideas.

## Contributor Tasks
- Replace placeholder screenshots in `docs/images/`.
- Keep the `CHANGELOG.md` updated with any changes.
- Update the README if your changes affect usage.

## Code of Conduct
By participating, you agree to maintain a respectful and inclusive environment.

