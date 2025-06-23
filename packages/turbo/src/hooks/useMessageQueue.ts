import { useCallback, useRef } from 'react';
import type { NativeSyntheticEvent } from 'react-native';

import type { SessionMessageCallback, MessageEvent } from '../types';

type SessionMessageCallbackArrayElement = SessionMessageCallback | undefined;

export function useMessageQueue(
  onMessageCallback: SessionMessageCallback | undefined
) {
  const onMessageCallbacks = useRef<SessionMessageCallbackArrayElement[]>([
    onMessageCallback,
  ]);

  const registerMessageListener = useCallback(
    (listener: SessionMessageCallback) => {
      onMessageCallbacks.current.push(listener);

      return {
        remove: () => {
          onMessageCallbacks.current = onMessageCallbacks.current.filter(
            (callback) => callback !== listener
          );
        },
      };
    },
    []
  );

  const handleOnMessage = useCallback(
    (e: NativeSyntheticEvent<MessageEvent>) => {
      onMessageCallbacks.current.forEach((listener) => {
        listener?.(e.nativeEvent);
      });
    },
    []
  );

  return { registerMessageListener, handleOnMessage };
}
