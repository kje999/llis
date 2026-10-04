/// Constants and configuration for the 5 supported PCSO 6-number lotto games.
class LottoConstants {
  LottoConstants._();

  static const String appName = 'Lucky Lotto Information System (LLIS)';
  static const String appVersion = '2.0.0 Modern Web';
  static const String author = 'Kenth Joshua Espina';

  // The 5 fixed PCSO games codes
  static const String ultra658 = 'ULTRA_6_58';
  static const String grand655 = 'GRAND_6_55';
  static const String super649 = 'SUPER_6_49';
  static const String mega645 = 'MEGA_6_45';
  static const String lotto642 = 'LOTTO_6_42';

  static const List<String> supportedCodes = [
    ultra658,
    grand655,
    super649,
    mega645,
    lotto642,
  ];

  static const String defaultDisclaimer =
      'Lottery draws are random. Historical statistics, frequency analysis, '
      'and statistical suggestions do not guarantee future winning numbers. '
      'This feature is provided for informational and entertainment purposes only.';

  static const String pcsoOfficialUrl = 'https://www.pcso.gov.ph/searchlottoresult.aspx';
}
