class XenditConfig {
  // ──────────────────────────────────────────────────────────────────────────
  // Paste your Xendit keys here.
  // Dashboard → https://dashboard.xendit.co → Settings → Developers → API Keys
  //
  //  Test keys look like:
  //    Secret key : xnd_development_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  //    Public key : xnd_public_development_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  //
  // WARNING: Never commit real production keys to source control.
  // ──────────────────────────────────────────────────────────────────────────
  static const secretKey = 'xnd_development_OiFZ9jy2xRD9t3OOD2Ebs9HV5I92tCqsji6zdzr5iNDMieCEMVjtZseWuwn4X';
  static const publicKey = 'xnd_public_development_CWptmbh0QZdZiATzhwyznGnZX3Tj9P6Jt0L1NCWykEtb71vF1XmDpfj0Zh5U5d';

  // Returns true once real keys have been filled in.
  static bool get isConfigured =>
      !secretKey.startsWith('YOUR_') && !publicKey.startsWith('YOUR_');
}
