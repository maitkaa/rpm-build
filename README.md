# RPM Build GitHub Action

This action builds RPMs from a spec file template. It's designed to be flexible and can be used in various CI/CD pipelines for projects that require RPM packaging.

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `spec_template` | Path to the spec file template | Yes | - |
| `version` | Version for the RPM | No | Current timestamp |
| `release` | Release number for the RPM | Yes | - |
| `approot` | Application root directory | Yes | - |
| `project` | Project name | Yes | - |
| `deploy_dir` | Deployment directory | No | 'deploy' |
| `run_lint` | Whether to run rpmlint on the generated spec file | No | 'true' |
| `rpmmacros_template` | Path to the .rpmmacros template file | No | - |

## Outputs

| Output | Description |
|--------|-------------|
| `rpm_path` | Path to the built RPM file |
| `rpm_name` | Name of the built RPM file |
| `rpm_dir_path` | Path to RPMS directory |
| `spec_file` | Path to the generated spec file |

## Usage

Here's an example of how to use this action in your workflow:

```yaml
name: Build RPM

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Build RPM
      uses: your-github-username/rpm-build-action@v1
      with:
        spec_template: 'path/to/your/spec-template.spec'
        version: '1.0.0'
        release: '1'
        approot: '/opt/myapp'
        project: 'myproject'
        deploy_dir: 'rpmbuild'
        run_lint: 'true'
        rpmmacros_template: 'path/to/your/rpmmacros-template'
      
    - name: Upload RPM
      uses: actions/upload-artifact@v3
      with:
        name: rpm-package
        path: ${{ steps.build.outputs.rpm_path }}
```

## Requirements

- This action is designed to run on a Linux environment with RPM tools installed.
- The runner should have `git`, `rpmbuild`, and `rpmlint` (if linting is enabled) installed.

## Contributing

Contributions to improve this action are welcome. Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.