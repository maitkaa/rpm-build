#!/bin/bash

set -e

echo "Starting RPM build process..."

# Set variables from inputs
SPEC_TEMPLATE="$INPUT_SPEC_TEMPLATE"
VERSION="$INPUT_VERSION"
RELEASE="$INPUT_RELEASE"
APPROOT="$INPUT_APPROOT"
PROJECT="$INPUT_PROJECT"
DEPLOY_DIR="$INPUT_DEPLOY_DIR"
RPMMACROS_TEMPLATE="$INPUT_RPMMACROS_TEMPLATE"
RUN_LINT="$INPUT_RUN_LINT"
PROJECT_EXCLUDE_PATHS="$INPUT_PROJECT_EXCLUDE_PATHS"

# Set up environment variables
WORKSPACE=$(pwd)
BUILD_DIR="$WORKSPACE/$DEPLOY_DIR/BUILD"
RPM_BUILD_ROOT="$BUILD_DIR/${PROJECT}-${GITHUB_REF##*/}-$VERSION"
GENERATED_SPEC="$WORKSPACE/$DEPLOY_DIR/SPECS/${PROJECT}-${GITHUB_REF##*/}-$VERSION.spec"

echo "Creating necessary directories..."
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

echo "Creating rpmmacros..."
if [ ! -f "$RPMMACROS_TEMPLATE" ]; then
    echo "Error: RPM macros template file not found: $RPMMACROS_TEMPLATE"
    exit 1
fi

sed "s#\$DEPLOYMENTROOT#$WORKSPACE#g" "$RPMMACROS_TEMPLATE" > ~/.rpmmacros

echo "Creating version file..."
echo "${PROJECT}-${VERSION}-${RELEASE}" > "$RPM_BUILD_ROOT$APPROOT/version"

echo "Copying files to BUILDROOT..."
rsync -av --exclude={$PROJECT_EXCLUDE_PATHS} "$WORKSPACE/" "$RPM_BUILD_ROOT$APPROOT/"

if [ "$RUN_LINT" = "true" ]; then
    echo "Running rpmlint..."
    rpmlint "$GENERATED_SPEC"
fi

echo "Building RPM..."
rpmbuild -bb \
    --define "_tmppath /tmp" \
    --define "_topdir $WORKSPACE/$DEPLOY_DIR" \
    --define "_builddir $BUILD_DIR" \
    --define "_rpmdir $WORKSPACE/$DEPLOY_DIR/RPMS" \
    --define "_srcrpmdir $WORKSPACE/$DEPLOY_DIR/SRPMS" \
    --define "_specdir $WORKSPACE/$DEPLOY_DIR/SPECS" \
    "$GENERATED_SPEC" \
    --buildroot="$RPM_BUILD_ROOT"

RPM_DIR="$WORKSPACE/$DEPLOY_DIR/RPMS/noarch"
RPM_NAME=$(ls "$RPM_DIR" | grep ".rpm$" | head -n 1)
RPM_PATH="$RPM_DIR/$RPM_NAME"

echo "spec_file=$GENERATED_SPEC" >> $GITHUB_OUTPUT
echo "rpm_path=$RPM_PATH" >> $GITHUB_OUTPUT
echo "rpm_name=$RPM_NAME" >> $GITHUB_OUTPUT
echo "rpm_dir_path=$RPM_DIR" >> $GITHUB_OUTPUT

echo "RPM build completed successfully!"