#!/bin/bash

set -e

echo "Starting RPM build process"

# Determine the actual workspace
if [ -d "/github/workspace" ]; then
    WORKSPACE="/github/workspace"
elif [ -d "/workspace" ]; then
    WORKSPACE=$(pwd)
else
    echo "Error: Unable to determine workspace directory"
    exit 1
fi

echo "Debug: Determined workspace is $WORKSPACE"
echo "Debug: Current directory is $(pwd)"

# Set variables from inputs
SPEC_TEMPLATE="$INPUT_SPEC_TEMPLATE"
VERSION="$INPUT_VERSION"
RELEASE="$INPUT_RELEASE"
APPROOT="$INPUT_APPROOT"
PROJECT="$INPUT_PROJECT"
DEPLOY_DIR="$INPUT_DEPLOY_DIR"
RPMMACROS_TEMPLATE="$INPUT_RPMMACROS_TEMPLATE"
RUN_LINT="$INPUT_RUN_LINT"

# Set up environment variables
BUILD_DIR="$WORKSPACE/$DEPLOY_DIR/BUILD"
RPM_BUILD_ROOT="$WORKSPACE/$DEPLOY_DIR/BUILDROOT"
GENERATED_SPEC="$WORKSPACE/$DEPLOY_DIR/SPECS/${PROJECT}-${GITHUB_REF##*/}-$VERSION.spec"

echo "Debug: Listing workspace contents:"
ls -R $WORKSPACE

echo "Debug: Environment variables:"
env

echo "Debug: SPEC_TEMPLATE=$SPEC_TEMPLATE"
echo "Debug: GENERATED_SPEC=$GENERATED_SPEC"

if [ ! -f "$SPEC_TEMPLATE" ]; then
    echo "Error: Spec template file not found: $SPEC_TEMPLATE"
    exit 1
fi

echo "Generating Spec File..."
mkdir -p "$(dirname "$GENERATED_SPEC")"
sed -e "s/\$VERSION/$VERSION/g" \
    -e "s/\$RELEASE/$RELEASE/g" \
    -e "s/\$BRAND//g" \
    -e "s#\$APPROOT#$APPROOT#g" \
    -e "s#\$BUILDROOT#$RPM_BUILD_ROOT#g" \
    "$SPEC_TEMPLATE" > "$GENERATED_SPEC"

echo "Generated spec file:"
cat "$GENERATED_SPEC"

echo "Creating rpmmacros..."
if [ ! -f "$RPMMACROS_TEMPLATE" ]; then
    echo "Error: RPM macros template file not found: $RPMMACROS_TEMPLATE"
    exit 1
fi

sed "s#\$DEPLOYMENTROOT#$WORKSPACE#g" "$RPMMACROS_TEMPLATE" > ~/.rpmmacros
echo "Generated .rpmmacros:"
cat ~/.rpmmacros

# Run rpmlint if enabled
if [ "$RUN_LINT" = "true" ]; then
    echo "Running rpmlint..."
    rpmlint "$GENERATED_SPEC"
fi

echo "Building RPM..."
mkdir -p "$RPM_BUILD_ROOT"
rpmbuild -bb --define "_tmppath /tmp" "$GENERATED_SPEC" --buildroot="$RPM_BUILD_ROOT"

# Find the built RPM
RPM_DIR="$WORKSPACE/RPMS/noarch"
RPM_NAME=$(ls "$RPM_DIR" | grep ".rpm$" | head -n 1)
RPM_PATH="$RPM_DIR/$RPM_NAME"

echo "Debug: RPM build completed. Listing RPM directory contents:"
ls -l "$RPM_DIR"

# Set outputs
echo "spec_file=$GENERATED_SPEC" >> $GITHUB_OUTPUT
echo "rpm_path=$RPM_PATH" >> $GITHUB_OUTPUT
echo "rpm_name=$RPM_NAME" >> $GITHUB_OUTPUT
echo "rpm_dir_path=$RPM_DIR" >> $GITHUB_OUTPUT

echo "RPM build completed successfully!"