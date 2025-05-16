export type Action = 'advance' | 'replace' | 'restore';

export interface VisitProposal {
  url: string;
  action: Action;
}

export interface LoadEvent {
  title: string;
  url: string;
}

export interface OpenExternalUrlEvent {
  url: string;
}

export interface FormSubmissionEvent {
  url: string;
}

export interface ContentProcessDidTerminateEvent {
  url: string;
}

export type MessageEvent = object;

export interface AlertHandler {
  message: string;
}

export interface ErrorEvent {
  url: string;
  statusCode: SystemStatusCode | HTTPStatusCode;
  description?: string;
}

export type HTTPStatusCode = number;

export enum SystemStatusCode {
  NETWORK_FAILURE = 0,
  TIMEOUT_FAILURE = -1,
  CONTENT_TYPE_MISMATCH = -2,
  PAGE_LOAD_FAILURE = -3,
  UNKNOWN = -4,
}

export type ContentInsetObject = {
  bottom?: number;
  left?: number;
  right?: number;
  top?: number;
};

export type ProgressViewOffsetObject = {
  scale: boolean;
  start: number;
  end: number;
};

export type StradaMessage = {
  component: string;
  event: string;
  data: {
    metadata: {
      url: string;
    };
    [key: string]: any;
  };
};

export type SessionMessageCallback = (message: object) => void;

export type OnErrorCallback = (error: ErrorEvent) => void;

export type EventSubscription = {
  remove: () => void;
};

export type StradaComponentProps = {
  sessionHandle: string;
  url: string;
  name: string;
  registerMessageListener: (
    listener: SessionMessageCallback
  ) => EventSubscription;
  sendToBridge: (message: StradaMessage) => void;
};

export type StradaComponent = React.ComponentType<StradaComponentProps> & {
  componentName: string;
};

export type StradaMessages = {
  [event: string]: StradaMessage;
};

// List of methods available for RNVisitableView module
export type DispatchCommandTypes =
  | 'injectJavaScript'
  | 'reload'
  | 'refresh'
  | 'sendAlertResult'
  | 'sendConfirmResult';

export type DispatchCommand = (
  ref: React.RefObject<any>,
  command: DispatchCommandTypes,
  ...args: any[]
) => void;
