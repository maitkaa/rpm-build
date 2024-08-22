# RPM Build Action

This GitHub Action builds RPM packages using a custom spec template. It's designed to work with various applications and supports customizable build environments.

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

To use this action in your workflow, include it as a step:

```yaml
jobs:
  build-rpm:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build RPM
        uses: maitkaa/rpm-build@v1
        with:
          spec_template: ${{ github.workspace }}/packaging/myapp.spec-template
          version: ${{ env.VERSION }}
          release: ${{ env.RELEASE }}
          approot: /opt/myapp
          project: myapp
          deploy_dir: packaging
          rpmmacros_template: ${{ github.workspace }}/packaging/.rpmmacros-template
          run_lint: 'true'
```

## Spec File Template

Your spec file template should use variables that will be replaced during the build process. Here's a simple example:

```spec
Name: $PROJECT
Version: $VERSION
Release: $RELEASE
Summary: My Application
License: MIT
BuildArch: noarch

%define _app    $PROJECT
%define _appdir $APPROOT
%define buildroot $BUILDROOT

%description
This is my application.

%prep
# Prep steps here

%build
# Build steps here

%install
mkdir -p %{buildroot}%{_appdir}
cp -R . %{buildroot}%{_appdir}

%files
%{_appdir}

%changelog
* Wed Aug 22 2024 Your Name <your.email@example.com> - $VERSION-$RELEASE
- Initial RPM release
```

## RPM Macros Template

Your `.rpmmacros-template` file might look like this:

```
%_topdir $DEPLOYMENTROOT/packaging
%_tmppath /tmp
```

## Directory Structure

Ensure your repository has a structure similar to this:

```
your-repo/
├── .github/
│   └── workflows/
│       └── build-rpm.yml
├── packaging/
│   ├── myapp.spec-template
│   └── .rpmmacros-template
└── src/
    └── (your application source files)
```

## Requirements

This action runs in a Docker container based on Rocky Linux. It installs the necessary RPM build tools and dependencies within the container.

## Customization

You can customize the build environment by forking this action and modifying the `Dockerfile` and `entrypoint.sh` script.

## Contributing

Contributions to improve this action are welcome. Please feel free to submit issues or pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.