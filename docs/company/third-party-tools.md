# Third Party Systems and Platforms

This section documents the core third party systems and platforms that power our daily work at Mbodi. Understanding our platform stack helps new team members get productive quickly and ensures everyone is using our systems effectively.

## Documentation & Knowledge Management

### Notion

**Purpose**: Central documentation, project planning, and knowledge base
**Access**: All team members with workspace access
**Use Cases**: Meeting notes, project documentation, process guides, team wiki, project planning

**Best Practices**:

- Use consistent templates for meeting notes and project documentation
- Link related pages and maintain clear page hierarchies
- Keep information current and archive outdated content
- Use @mentions for collaboration and task assignments
- Organize content with clear naming conventions and tags

### Google Drive

**Purpose**: File storage, document collaboration, and sharing
**Access**: All team members with company Google accounts
**Use Cases**: Document collaboration, file sharing, presentation storage, form creation

**Best Practices**:

- Use shared drives for team collaboration
- Maintain consistent folder structures and naming conventions
- Set appropriate sharing permissions and access levels
- Use version history and commenting for collaborative editing
- Regularly clean up and organize files

## Development & Engineering

### GitHub

**Purpose**: Code repository, version control, and development collaboration
**Access**: All technical team members with organization access
**Use Cases**: Source code management, code reviews, issue tracking, documentation, CI/CD workflows

**Best Practices**:

- Write clear, descriptive commit messages following conventional commit format
- Use pull requests for all code changes with required reviews
- Follow consistent branch naming: `feature/description`, `bugfix/description`, `hotfix/description`
- Keep repositories organized with clear README files and documentation
- Use GitHub Issues for bug tracking and feature requests
- Implement branch protection rules for main/production branches
- Tag releases and maintain changelog documentation

## Integration & Workflow

### GitHub ↔ Linear Integration

**Purpose**: Seamless connection between code changes and project management
**Setup**: Automatic linking of commits, PRs, and issues using Linear's GitHub app

**Workflow**:

- Reference Linear issues in commit messages: `git commit -m "feat: add user auth (LIN-123)"`
- Pull requests automatically update linked Linear issues
- Issue status changes based on PR status (merged = completed)
- Use Linear's branch creation feature to maintain consistent naming

### Notion ↔ Other Systems

**Purpose**: Central documentation hub that references work across platforms
**Integration Points**:

- Embed Linear roadmaps and project views in Notion pages
- Link to GitHub repositories and documentation from Notion
- Store Google Drive files and folders within Notion pages
- Create meeting notes that reference Linear issues and GitHub discussions

## Project Management

### Linear

**Purpose**: Issue tracking, project management, and development workflow
**Access**: All team members with workspace access
**Use Cases**: Bug tracking, feature requests, sprint planning, roadmap management, task assignment

**Best Practices**:

- Write clear, actionable issue descriptions with acceptance criteria
- Use consistent labeling system: `bug`, `feature`, `improvement`, `documentation`
- Set appropriate priorities: `urgent`, `high`, `medium`, `low`
- Link related issues and GitHub pull requests
- Update issue status regularly and add progress comments
- Use Linear's GitHub integration to automatically update issues from commits
- Organize work into projects and milestones for better tracking
- Use estimates and cycle tracking for sprint planning

## System Access & Permissions

### Access Levels

- **Admin**: Full administrative access (founders, IT admin)
- **Member**: Standard team member access
- **Guest**: Limited access for contractors or external collaborators
- **Viewer**: Read-only access for stakeholders

### Platform-Specific Access

#### GitHub

- **Organization Owners**: Founders and CTO
- **Team Maintainers**: Senior engineers and team leads
- **Members**: All technical team members
- **Outside Collaborators**: External contributors (limited repo access)

#### Linear

- **Admin**: Leadership team and project managers
- **Member**: All team members (can create and edit issues)
- **Guest**: External stakeholders (view-only access to specific projects)

#### Notion

- **Admin**: Leadership team and designated content managers
- **Member**: All team members (can edit and create pages)
- **Guest**: External collaborators (limited page access)

#### Google Drive

- **Admin**: IT admin and leadership
- **Editor**: Team members with editing rights to shared drives
- **Viewer**: Read-only access to specific folders or documents

## Getting Access

### New Team Member Setup

1. **Google Workspace**: Create company email and Google Drive access
2. **GitHub**: Add to Mbodi organization with appropriate team membership
3. **Linear**: Invite to workspace with member-level access
4. **Notion**: Add to company workspace with editing permissions
5. **Role-Specific**: Additional system access based on team and responsibilities

### Access Request Process

1. **Submit Request**: Use Linear issue template for system access requests
2. **Manager Approval**: Direct manager approves the request
3. **IT/Admin Provisioning**: Designated admin provisions access within 24 hours
4. **Confirmation**: New user confirms access and completes any required setup

### Access Reviews

- **Quarterly**: Review all team member access levels
- **Role Changes**: Update access when team members change roles
- **Project-Based**: Grant temporary access for specific projects as needed

### Offboarding Checklist

- [ ] Revoke GitHub organization access
- [ ] Remove from Linear workspace
- [ ] Transfer ownership of Notion pages and databases
- [ ] Remove from Google Drive shared drives
- [ ] Transfer or archive important work documents
- [ ] Update team contact lists and documentation

## Best Practices Summary

### Daily Workflow

1. **Start with Linear**: Check assigned issues and daily priorities
2. **GitHub**: Create feature branches using Linear's branch creation
3. **Development**: Make commits with Linear issue references
4. **Documentation**: Update relevant Notion pages with progress
5. **Collaboration**: Share files via Google Drive, discuss in Linear comments

### Communication Guidelines

- **Quick Updates**: Use Linear comments for project-specific updates
- **Documentation**: Use Notion for detailed documentation and meeting notes
- **File Sharing**: Use Google Drive for documents, presentations, and large files
- **Code Discussion**: Use GitHub PR comments for technical discussions

### Organization Standards

- **Naming Conventions**: Use consistent naming across all platforms
- **Tagging**: Apply consistent labels in Linear and tags in Notion
- **File Structure**: Maintain organized folder structures in Drive and Notion
- **Version Control**: Use semantic versioning and clear commit messages

## System Maintenance

### Regular Maintenance Tasks

- **Weekly**: Clean up completed Linear issues and outdated Notion pages
- **Monthly**: Review and organize Google Drive folders and permissions
- **Quarterly**: Audit access permissions across all platforms
- **Annually**: Evaluate system effectiveness and consider alternatives

### Troubleshooting & Support

- **GitHub Issues**: Check GitHub Status page, contact GitHub Support
- **Linear Problems**: Use Linear's in-app support or community forum
- **Notion Outages**: Check Notion Status page, use mobile app as backup
- **Google Drive**: Google Workspace Admin console, Google Support

---

*This documentation reflects our core third party systems and platforms: GitHub, Linear, Notion, and Google Drive. As we grow and our needs evolve, we'll evaluate additional platforms that integrate well with this foundation.*
