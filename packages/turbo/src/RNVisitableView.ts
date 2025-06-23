import {
  NativeSyntheticEvent,
  Platform,
  requireNativeComponent,
  StyleProp,
  UIManager,
  ViewStyle,
  Linking,
  findNodeHandle,
} from 'react-native';

import type {
  AlertHandler,
  DispatchCommandTypes,
  LoadEvent,
  MessageEvent,
  VisitProposal,
  ErrorEvent,
  OpenExternalUrlEvent,
  FormSubmissionEvent,
  ContentProcessDidTerminateEvent,
  ContentInsetObject,
  ProgressViewOffsetObject,
} from './types';

// Interface should match RNVisitableView exported properties in native code
export interface RNVisitableViewProps {
  url: string;
  sessionHandle?: string;
  applicationNameForUserAgent?: string;
  pullToRefreshEnabled: boolean;
  scrollEnabled: boolean;
  contentInset: ContentInsetObject;
  progressViewOffset?: ProgressViewOffsetObject;
  refreshControlTopAnchor: number;
  webViewDebuggingEnabled: boolean;
  allowsInlineMediaPlayback: boolean;
  onLoad?: (e: NativeSyntheticEvent<LoadEvent>) => void;
  onMessage?: (e: NativeSyntheticEvent<MessageEvent>) => void;
  onError?: (e: NativeSyntheticEvent<ErrorEvent>) => void;
  onVisitProposal?: (e: NativeSyntheticEvent<VisitProposal>) => void;
  onWebAlert?: (e: NativeSyntheticEvent<AlertHandler>) => void;
  onWebConfirm?: (e: NativeSyntheticEvent<AlertHandler>) => void;
  onOpenExternalUrl?: (e: NativeSyntheticEvent<OpenExternalUrlEvent>) => void;
  onFormSubmissionStarted?: (
    e: NativeSyntheticEvent<FormSubmissionEvent>
  ) => void;
  onFormSubmissionFinished?: (
    e: NativeSyntheticEvent<FormSubmissionEvent>
  ) => void;
  onShowLoading: () => void;
  onHideLoading: () => void;
  onContentProcessDidTerminate?: (
    e: NativeSyntheticEvent<ContentProcessDidTerminateEvent>
  ) => void;
  style?: StyleProp<ViewStyle>;
}

const LINKING_ERROR =
  `The package react-native-turbo doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

function transformCommandToAcceptableType(command: number): number | string {
  if (Platform.OS === 'ios') {
    return command;
  }
  return command.toString();
}

const initializeWebView = async (webViewRef: React.RefObject<any>) => {
  const initializationPromise = new Promise<void>((resolve) =>
    setTimeout(resolve, 1)
  );

  if (!webViewRef?.current) {
    return initializationPromise;
  }

  webViewRef.current.initializationPromise =
    webViewRef.current.initializationPromise || initializationPromise;

  return webViewRef.current.initializationPromise;
};

export async function dispatchCommand(
  ref: React.RefObject<any>,
  command: DispatchCommandTypes,
  ...args: any[]
) {
  const viewConfig = UIManager.getViewManagerConfig('RNVisitableView');

  if (!viewConfig) {
    throw new Error(LINKING_ERROR);
  }

  const transformedCommand = transformCommandToAcceptableType(
    viewConfig.Commands[command]!
  );

  if (transformedCommand === undefined) {
    return;
  }

  // Using initializeWebView makes sure that we call the native method
  // after the native sessionHandle prop is set.
  await initializeWebView(ref);

  const reactTag = findNodeHandle(ref.current);

  if (!reactTag) {
    return;
  }

  UIManager.dispatchViewManagerCommand(reactTag, transformedCommand, args);
}

export async function openExternalURL({
  url,
}: OpenExternalUrlEvent): Promise<void> {
  const supported = await Linking.canOpenURL(url);

  if (supported) {
    await Linking.openURL(url);
  } else {
    console.error(`Don't know how to open this URL: ${url}`);
  }
}

const RNVisitableView =
  requireNativeComponent<RNVisitableViewProps>('RNVisitableView');

export default RNVisitableView;
