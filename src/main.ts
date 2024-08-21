import * as core from '@actions/core'
import * as exec from '@actions/exec'
import * as io from '@actions/io'
import * as fs from 'fs'
import * as path from 'path'

async function run(): Promise<void> {
  try {
    // Get inputs
    const specTemplate = core.getInput('spec_template', { required: true })
    const version = core.getInput('version') || new Date().getTime().toString()
    const release = core.getInput('release', { required: true })
    const approot = core.getInput('approot', { required: true })
    const project = core.getInput('project', { required: true })
    const deployDir = core.getInput('deploy_dir') || 'deploy'
    const runLint = core.getInput('run_lint') === 'true'
    const rpmmacrosTemplate = core.getInput('rpmmacros_template')

    // Set up environment variables and paths
    const workspace = process.env.GITHUB_WORKSPACE || ''
    const buildDir = path.join(workspace, deployDir, 'BUILD')
    const buildRoot = path.join(buildDir, `${project}-${version}-${release}`)
    const specDir = path.join(workspace, deployDir, 'SPECS')
    const generatedSpec = path.join(
      specDir,
      `${project}-${version}-${release}.spec`
    )

    // Create necessary directories
    await io.mkdirP(buildRoot)
    await io.mkdirP(specDir)

    // Generate spec file
    const specContent = fs
      .readFileSync(specTemplate, 'utf8')
      .replace(/\$VERSION/g, version)
      .replace(/\$RELEASE/g, release)
      .replace(/\$BRAND/g, '')
      .replace(/\$APPROOT/g, approot)
      .replace(/\$BUILDROOT/g, buildRoot)
    fs.writeFileSync(generatedSpec, specContent)

    // Create .rpmmacros file
    const homeDir = process.env.HOME || ''
    const rpmmacrosPath = path.join(homeDir, '.rpmmacros')
    if (rpmmacrosTemplate && fs.existsSync(rpmmacrosTemplate)) {
      const rpmmacrosContent = fs
        .readFileSync(rpmmacrosTemplate, 'utf8')
        .replace(/\$DEPLOYMENTROOT/g, workspace)
      fs.writeFileSync(rpmmacrosPath, rpmmacrosContent)
    } else {
      const defaultRpmmacros =
        `%_topdir ${workspace}/${deployDir}\n` +
        '%_builddir %{_topdir}/BUILD\n' +
        '%_rpmdir %{_topdir}/RPMS\n' +
        '%_sourcedir %{_topdir}/SOURCES\n' +
        '%_specdir %{_topdir}/SPECS\n' +
        '%_srcrpmdir %{_topdir}/SRPMS\n' +
        '%_buildrootdir %{_topdir}/BUILDROOT'
      fs.writeFileSync(rpmmacrosPath, defaultRpmmacros)
    }

    // Run rpmlint if enabled
    if (runLint) {
      await exec.exec('rpmlint', [generatedSpec])
    }

    // Create source tarball
    const sourceDir = path.join(workspace, deployDir, 'SOURCES')
    await io.mkdirP(sourceDir)
    await exec.exec('git', [
      'archive',
      '--output',
      `${sourceDir}/${project}-${version}.tar.gz`,
      '--prefix',
      `${project}-${version}/`,
      'HEAD'
    ])

    // Log all inputs
    core.info('Action inputs:')
    core.info(`spec_template: ${specTemplate}`)
    core.info(`version: ${version}`)
    core.info(`release: ${release}`)
    core.info(`approot: ${approot}`)
    core.info(`project: ${project}`)
    core.info(`deploy_dir: ${deployDir}`)
    core.info(`run_lint: ${runLint}`)
    core.info(`rpmmacros_template: ${rpmmacrosTemplate}`)

    // Log important paths
    core.info(`Workspace: ${workspace}`)
    core.info(`Build Root: ${buildRoot}`)
    core.info(`Generated Spec: ${generatedSpec}`)

    // Build RPM
    const rpmbuildArgs = [
      '-bb',
      '--define',
      `_tmppath /tmp`,
      '--define',
      `_topdir ${workspace}/${deployDir}`,
      '--define',
      `_appdir ${approot}`,
      '--define',
      `_app ${project}`,
      '--buildroot',
      buildRoot,
      '-v',
      generatedSpec
    ]

    core.info('Running rpmbuild command:')
    core.info(`rpmbuild ${rpmbuildArgs.join(' ')}`)

    await exec.exec('rpmbuild', rpmbuildArgs, {
      listeners: {
        stdout: data => {
          core.info(data.toString())
        },
        stderr: data => {
          core.error(data.toString())
        }
      }
    })

    // Find built RPM
    const rpmDir = path.join(workspace, deployDir, 'RPMS', 'noarch')
    const rpmFiles = fs
      .readdirSync(rpmDir)
      .filter(file => file.endsWith('.rpm'))
    if (rpmFiles.length === 0) {
      throw new Error('No RPM file found after build')
    }
    const rpmPath = path.join(rpmDir, rpmFiles[0])

    // Set outputs
    core.setOutput('rpm_path', rpmPath)
    core.setOutput('rpm_name', rpmFiles[0])
    core.setOutput('rpm_dir_path', rpmDir)
    core.setOutput('spec_file', generatedSpec)
  } catch (error: any) {
    core.setFailed(`Action failed with error: ${error.message}`)
    core.error(error.stack)
  }
}

run()
