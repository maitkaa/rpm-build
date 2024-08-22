#!/bin/bash

set -ex

echo "Starting RPM build process"

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
WORKSPACE=$(pwd)
BUILD_DIR="$WORKSPACE/$DEPLOY_DIR/BUILD"
RPM_BUILD_ROOT="$BUILD_DIR/${PROJECT}-${GITHUB_REF##*/}-$VERSION"
GENERATED_SPEC="$WORKSPACE/$DEPLOY_DIR/SPECS/${PROJECT}-${GITHUB_REF##*/}-$VERSION.spec"

echo "Debug: Environment variables:"
env

echo "Debug: SPEC_TEMPLATE=$SPEC_TEMPLATE"
echo "Debug: GENERATED_SPEC=$GENERATED_SPEC"
echo "Debug: RPM_BUILD_ROOT=$RPM_BUILD_ROOT"

# Create necessary directories
mkdir -p "$RPM_BUILD_ROOT$APPROOT"
mkdir -p "$(dirname "$GENERATED_SPEC")"
mkdir -p "$WORKSPACE/$DEPLOY_DIR/RPMS/noarch"
mkdir -p "$WORKSPACE/$DEPLOY_DIR/SRPMS"

if [ ! -f "$SPEC_TEMPLATE" ]; then
    echo "Error: Spec template file not found: $SPEC_TEMPLATE"
    exit 1
fi

echo "Generating Spec File..."
sed -e "s/\$VERSION/$VERSION/g" \
    -e "s/\$RELEASE/$RELEASE/g" \
    -e "s/\$BRAND//g" \
    -e "s#\$APPROOT#$APPROOT#g" \
    -e "s#\$BUILDROOT#$RPM_BUILD_ROOT#g" \
    -e "s#\$BUILD#$BUILD_DIR#g" \
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

# Create version file
echo "Creating version file..."
mkdir -p "$RPM_BUILD_ROOT$APPROOT"
echo "${PROJECT}-${VERSION}-${RELEASE}" > "$RPM_BUILD_ROOT$APPROOT/version"
echo "Version file contents:"
cat "$RPM_BUILD_ROOT$APPROOT/version"

# Debug: List contents of important directories
echo "Contents of $RPM_BUILD_ROOT:"
ls -la "$RPM_BUILD_ROOT"
echo "Contents of $RPM_BUILD_ROOT$APPROOT:"
ls -la "$RPM_BUILD_ROOT$APPROOT"

# Run rpmlint if enabled
if [ "$RUN_LINT" = "true" ]; then
    echo "Running rpmlint..."
    rpmlint "$GENERATED_SPEC"
fi

echo "Building RPM..."
rpmbuild -bb -v \
    --define "_tmppath /tmp" \
    --define "_topdir $WORKSPACE/$DEPLOY_DIR" \
    --define "_builddir $BUILD_DIR" \
    --define "_rpmdir $WORKSPACE/$DEPLOY_DIR/RPMS" \
    --define "_srcrpmdir $WORKSPACE/$DEPLOY_DIR/SRPMS" \
    --define "_specdir $WORKSPACE/$DEPLOY_DIR/SPECS" \
    "$GENERATED_SPEC" \
    --buildroot="$RPM_BUILD_ROOT"

# Find the built RPM
RPM_DIR="$WORKSPACE/$DEPLOY_DIR/RPMS/noarch"
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