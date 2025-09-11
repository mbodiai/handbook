# Mbodi Handbook Setup

Your company handbook has been set up with MkDocs and the Material theme!

## Getting Started

### 1. Install Dependencies

```bash
pip install "mkdocs>=1.5.0" "mkdocs-material>=9.0.0" "mkdocs-jupyter>=0.24.0"
```

This will install MkDocs, the Material theme, and Jupyter notebook support.

### 2. Serve the Handbook Locally

```bash
mkdocs serve
```

The handbook will be available at `http://127.0.0.1:8000`

### 3. Build for Production

```bash
mkdocs build
```

This creates a `site/` directory with static HTML files ready for deployment.

## Structure Created

```
docs/
├── index.md                    # Main homepage
├── company/
│   ├── mission.md             # Company mission statement
│   ├── values.md              # Core values
│   └── okrs.md                # Objectives and Key Results
├── engineering/
│   ├── index.md               # Engineering overview
│   ├── adr/index.md           # Architecture Decision Records
│   ├── rfcs/index.md          # Request for Comments
│   └── runbooks/index.md      # Operational procedures
├── product/
│   └── prd/index.md           # Product Requirements Documents
├── ops/index.md               # Operations
├── people/index.md            # HR and team information
├── security/index.md          # Security policies
└── legal/index.md             # Legal documents
```

## Next Steps

1. **Customize Content** - Update the placeholder content with your actual company information
2. **Add Team Members** - Populate the people section with your team
3. **Configure Theme** - Adjust colors, logos, and styling in `mkdocs.yml`
4. **Set Up Deployment** - Configure automatic deployment to your hosting platform
5. **Add Authentication** - Consider adding access controls if needed


## Contributing

All team members should contribute to keeping the handbook up-to-date:

1. Create a branch for your changes
2. Update the relevant documentation
3. Test locally with `mkdocs serve`
4. Submit a pull request for review
5. Deploy changes once approved

---

Your handbook is ready to use! Start by running `mkdocs serve` to see it in action.
