import { Platform, requireNativeComponent, UIManager } from 'react-native';
import { findNodeHandle } from 'react-native';

const LINKING_ERROR =
  `The package react-native-turbo doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

export function dispatchCommand(
  ref: React.RefObject<any>,
  command: string,
  ...args: any[]
) {
  const viewConfig = UIManager.getViewManagerConfig('RNVisitableView');

  if (!viewConfig) {
    throw new Error(LINKING_ERROR);
  }

  UIManager.dispatchViewManagerCommand(
    findNodeHandle(ref.current),
    viewConfig.Commands[command]!,
    args
  );
}

const RNVisitableView = requireNativeComponent<any>('RNVisitableView');

export default RNVisitableView;
