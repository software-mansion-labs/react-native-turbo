HOTWIRE_NATIVE_IOS_REPO_PATH="https://github.com/hotwired/hotwire-native-ios.git"
HOTWIRE_NATIVE_IOS_VERSION=$1
PATCH_FILE=$(realpath ./patches/hotwire-native-ios.patch)

# First argument is the version tag
if [ -z "$HOTWIRE_NATIVE_IOS_VERSION" ]
  then
    echo "No version tag supplied"
    exit 1
fi

echo "hotwire-native-ios version: $HOTWIRE_NATIVE_IOS_VERSION"

# Shallow clone the hotwire-native-ios repo
cd ./ios
rm -rf vendor
mkdir vendor
cd vendor
git clone --branch $HOTWIRE_NATIVE_IOS_VERSION --depth 1 $HOTWIRE_NATIVE_IOS_REPO_PATH

# Apply patch
cd hotwire-native-ios
git apply $PATCH_FILE

# Keep the Source folder and remove the rest
for file in * .*; do
  if [ "$file" != "Source" ] && [ "$file" != "." ] && [ "$file" != ".." ]; then
    rm -rf $file
  fi
done
