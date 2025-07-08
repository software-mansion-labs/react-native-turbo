# Check if android/vendor directory exists
if [ ! -d "./android/vendor" ]; then
  # If the vendor folder does not exist, we're not using the published package.
  # We can safely exit here, because postinstall script will be executed again when vendor folder is created. 
  exit 0
fi

CURRENT_DIR=$(realpath .)
MONOREPO_SUFFIX="examples/turbo-demo-expo-example/node_modules/react-native-turbo"
SKIP_RSYNC=0
PARENT_FOLDER=$(realpath .. | awk -F/ '{print $NF}')

# Skip postinstall for `yarn install` called from inside `turbo-demo-expo-example`
if [[ "$CURRENT_DIR" == *"$MONOREPO_SUFFIX" ]]; then
  SKIP_RSYNC=1
elif [ "$PARENT_FOLDER" == "node_modules" ]; then
  REACT_NATIVE_DIR=$(realpath ../react-native/android)
else
  # We are in the monorepo in `packages/turbo`
  REACT_NATIVE_DIR=$(realpath ../../node_modules/react-native/android)
fi

if [ $SKIP_RSYNC -eq 0 ]; then
  VENDOR_DIR=$(realpath ./android/vendor)
  # Copying the vendor files to the react-native android folder is necessary to run the app with react-native run-android command.
  rsync -av $VENDOR_DIR/ $REACT_NATIVE_DIR
fi