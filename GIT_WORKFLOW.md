# Git Workflow for Personal Site

This repository is a fork of the Jekyll Chirpy theme with git hooks removed for personal use.

## Repository Setup

- **origin**: Your personal repository (`https://github.com/gpayne9/guydevops.com.git`)
- **upstream**: Original Chirpy theme (`https://github.com/cotes2020/jekyll-theme-chirpy.git`)

## Daily Workflow

### Regular Commits (Your Content)
```bash
git add .
git commit -m "Add new post about AWS S3 and CloudFront"
git push origin main
```

You can now use any commit message format you want - no more conventional commit requirements!

## Updating from Upstream Theme

### Check for Theme Updates
```bash
git fetch upstream
git log HEAD..upstream/master --oneline
```

### Pull Theme Updates
```bash
# Create a new branch for the update
git checkout -b theme-update-$(date +%Y%m%d)

# Pull the latest changes from upstream
git pull upstream master

# Resolve any conflicts if they occur
# Test your site to make sure everything works
bundle exec jekyll serve

# If everything looks good, merge back to main
git checkout main
git merge theme-update-$(date +%Y%m%d)
git push origin main

# Clean up the temporary branch
git branch -d theme-update-$(date +%Y%m%d)
```

### Handling Conflicts
If you get conflicts during the theme update:

1. **Review conflicts**: Look at files that conflict
2. **Keep your customizations**: Usually keep your `_config.yml`, `_posts/`, `_tabs/about.md`
3. **Accept theme updates**: For `_layouts/`, `_includes/`, `_sass/`, `assets/`
4. **Test thoroughly**: Run `bundle exec jekyll serve` to test

## What Was Removed

- ✅ **Husky git hooks** - No more commit message validation
- ✅ **Commitlint** - No more conventional commit requirements  
- ✅ **Semantic release** - Simplified for personal use

## What Was Kept

- ✅ **Theme functionality** - All Jekyll theme features work
- ✅ **Build tools** - npm scripts for CSS/JS building
- ✅ **Upstream connection** - Can still pull theme updates

## Quick Commands

```bash
# Your daily workflow
git add . && git commit -m "updates" && git push

# Check for theme updates
git fetch upstream && git log HEAD..upstream/master --oneline

# Emergency: Reset to last working state
git reset --hard HEAD~1
```

---

*No more git hook errors! Commit freely! 🚀*
