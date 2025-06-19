import 'package:http/http.dart' as http;

Future<String> getPublicIP() async {
  try {
    const url = 'https://api.ipify.org';
    var response = await http.get(Uri.parse(
      url,
    ));
    if (response.statusCode == 200) {
      // The response body is the IP in plain text, so just
      // return it as-is.
      return response.body;
    } else {
      // The request failed with a non-200 code
      // The ipify.org API has a lot of guaranteed uptime
      // promises, so this shouldn't ever actually happen.
      final statusCode = response.statusCode;
      final body = response.body;
      return '$statusCode: $body';
    }
  } on Exception catch (_) {
    // Request failed due to an error, most likely because
    // the phone isn't connected to the internet.
    return 'Unable to retrieve public IP';
  }
}
