@protocol: 'None'
service Service2 {
  /* Async API to talk to Service2. */
  event Received2: {
    messageToPass: String;
  }
}
