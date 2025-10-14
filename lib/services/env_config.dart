class EnvConfig {
  // Optional: If set, the app will call this HTTPS Function for B2C payout initiation
  // instead of a Firebase Callable. Leave empty to use the callable (mpesaB2C).
  static const String mpesaB2CInvokeUrl = '';

  // Optional: For your reference only (not used by the app). Set these in Firebase portal when
  // creating the Cloud Functions so Safaricom can hit the callback URLs.
  static const String mpesaB2CResultUrl = '';
  static const String mpesaB2CTimeoutUrl = '';
}
