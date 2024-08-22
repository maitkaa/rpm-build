# Custom RPM Build Action

This GitHub Action builds RPM packages using a custom spec template and RPM macros. It's designed to work with PHP applications and supports customizable build environments.

## Features

- Builds RPM packages from a spec template
- Supports custom RPM macros
- Configurable application root, project name, and deployment directory
- Optional rpmlint check
- Outputs paths and names of generated files for easy artifact handling

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `spec_template` | Path to the spec template file | Yes | - |
| `version` | RPM version | Yes | - |
| `release` | RPM release number | Yes | - |
| `approot` | Application root directory | Yes | - |
| `project` | Project name | Yes | - |
| `deploy_dir` | Deployment directory | Yes | - |
| `rpmmacros_template` | Path to the .rpmmacros template file | Yes | - |
| `run_lint` | Whether to run rpmlint | No | `'true'` |

## Outputs

| Output | Description |
|--------|-------------|
| `spec_file` | Path to the generated spec file |
| `rpm_path` | Path to the built RPM file |
| `rpm_name` | Name of the built RPM file |
| `rpm_dir_path` | Path to the directory containing the built RPM |

## Usage

To use this action in your workflow, you can include it as a step:

```yaml
jobs:
  build-rpm:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build RPM
        uses: maitkaa/rpm-build@v1.0.1
        with:
          spec_template: ${{ github.workspace }}/deploy/SPECS/project.spec-template
          version: ${{ env.VERSION }}
          release: ${{ env.RELEASE }}
          approot: /srv/www
          project: MyProject
          deploy_dir: deploy
          rpmmacros_template: ${{ github.workspace }}/deploy/bin/.rpmmacros-template
          run_lint: 'true'
```

## Requirements

This action runs in a Docker container based on Rocky Linux 9. It installs the necessary RPM build tools and dependencies within the container.

## Customization

You can customize the build environment by modifying the `Dockerfile` included in this action. If you need additional packages or configurations, add them to the `Dockerfile`.

## Contributing

Contributions to improve this action are welcome. Please feel free to submit issues or pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.