#!/bin/bash

set -e

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
WORKSPACE="/github/workspace"
BUILD_DIR="$WORKSPACE/$DEPLOY_DIR/BUILD"
RPM_BUILD_ROOT="$WORKSPACE/$DEPLOY_DIR/BUILDROOT"
GENERATED_SPEC="$WORKSPACE/$DEPLOY_DIR/SPECS/${PROJECT}-${GITHUB_REF##*/}-$VERSION.spec"

# Generate Spec File
sed -e "s/\$VERSION/$VERSION/g" \
    -e "s/\$RELEASE/$RELEASE/g" \
    -e "s/\$BRAND//g" \
    -e "s#\$APPROOT#$APPROOT#g" \
    -e "s#\$BUILDROOT#$RPM_BUILD_ROOT#g" \
    "$SPEC_TEMPLATE" > "$GENERATED_SPEC"

echo "Generated spec file:"
cat "$GENERATED_SPEC"

# Create rpmmacros
sed "s#\$DEPLOYMENTROOT#$WORKSPACE#g" "$RPMMACROS_TEMPLATE" > ~/.rpmmacros
echo "Generated .rpmmacros:"
cat ~/.rpmmacros

# Run rpmlint if enabled
if [ "$RUN_LINT" = "true" ]; then
    echo "Running rpmlint..."
    rpmlint "$GENERATED_SPEC"
fi

# Build RPM
mkdir -p "$RPM_BUILD_ROOT"
rpmbuild -bb --define "_tmppath /tmp" "$GENERATED_SPEC" --buildroot="$RPM_BUILD_ROOT"

# Find the built RPM
RPM_DIR="$WORKSPACE/RPMS/noarch"
RPM_NAME=$(ls "$RPM_DIR" | grep ".rpm$" | head -n 1)
RPM_PATH="$RPM_DIR/$RPM_NAME"

# Set outputs
echo "spec_file=$GENERATED_SPEC" >> $GITHUB_OUTPUT
echo "rpm_path=$RPM_PATH" >> $GITHUB_OUTPUT
echo "rpm_name=$RPM_NAME" >> $GITHUB_OUTPUT
echo "rpm_dir_path=$RPM_DIR" >> $GITHUB_OUTPUT

echo "RPM build completed successfully!"