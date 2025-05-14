import { Component } from 'react';
import type { EmitterSubscription } from 'react-native';

import type {
  StradaMessage,
  StradaMessages,
  StradaComponentProps,
  SessionMessageCallback,
} from './types';

const stradaMessageListener = (component: BridgeComponent) => (e: object) => {
  const message = e as StradaMessage;
  if (message?.component !== component.name) {
    return;
  }
  component.previousMessages[message.event] = message;
  component.onReceive(message);
};

class BridgeComponent extends Component<StradaComponentProps> {
  name: string;
  url: string;
  sessionHandle: string;
  messageEventListenerSubscription?: EmitterSubscription;
  previousMessages: StradaMessages = {};
  registerMessageListener: (
    listener: SessionMessageCallback
  ) => EmitterSubscription;
  sendToBridge: (message: StradaMessage) => void;

  constructor(props: StradaComponentProps) {
    super(props);

    this.url = props.url;
    this.name = props.name;
    this.sessionHandle = props.sessionHandle;
    this.registerMessageListener = props.registerMessageListener;
    this.sendToBridge = props.sendToBridge;

    this.onReceive = this.onReceive.bind(this);
    this.replyTo = this.replyTo.bind(this);
  }

  componentDidMount() {
    this.messageEventListenerSubscription = this.registerMessageListener(
      stradaMessageListener(this)
    );
  }

  componentWillUnmount() {
    this.messageEventListenerSubscription?.remove();
  }

  onReceive(_message: StradaMessage) {
    // This is a no-op, but it can be overridden by the subclass
  }

  replyTo(event: string, data?: object) {
    const previousMessage = this.previousMessages[event];
    const messageToSend = previousMessage
      ? {
          ...previousMessage,
          data: {
            ...previousMessage.data,
            ...data,
          },
        }
      : {
          component: this.name,
          event,
          data: {
            ...data,
            metadata: {
              url: this.url,
            },
          },
        };
    this.sendToBridge(messageToSend);
  }

  render() {
    return null;
  }
}

export { BridgeComponent };
