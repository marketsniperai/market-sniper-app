import 'package:market_sniper_app/screens/menu_screen.dart';
import 'package:market_sniper_app/screens/account_screen.dart';
import 'package:market_sniper_app/screens/partner_terms_screen.dart';

void main() {
  print("Verifying Menu Dependencies...");
  const m = MenuScreen();
  const a = AccountScreen();
  const p = PartnerTermsScreen();
  print("Instantiation Success: $m, $a, $p");
}
