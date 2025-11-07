// import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ApiService {
  Future<void> initPlaidIntegration() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final idToken = await user.getIdToken();

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };

      // final url = Uri.parse('http://10.0.2.2:8080/init');
      final url = Uri.parse('http://localhost:8080/init');

      print(url);
      final response = await http.get(url, headers: headers);
      print(response.toString());
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   LinkTokenConfiguration configuration = LinkTokenConfiguration(
      //       token: data['link_token'],
      //   );
      //   await PlaidLink.create(configuration: configuration);
      //   PlaidLink.onSuccess.listen((LinkSuccess event) async {
      //     final publicToken = event.toJson()['publicToken'];
      //     final url2 = Uri.parse('http://10.0.2.2:8080/create/$publicToken');

      //     final response2 = await http.get(url2);

      //     if (response2.statusCode == 200) {
      //       final data2 = json.decode(response2.body);
      //       if(data2 != null && data2['access_token'] != null) {
      //         final SharedPreferences prefs = await SharedPreferences.getInstance();
      //         final List<String> tokens = prefs.getStringList('accessTokens') ?? [];
      //         tokens.add(data2['access_token']);
              
      //         await prefs.setStringList('accessTokens', tokens);

      //         return;
      //       }
      //     }
      //   });
      //   PlaidLink.open();
      // } else {
      //   throw Exception('Failed to load data from the API');
      // }
    } catch (e) {
      throw Exception('Failed to load data from the API: $e');
    }
  }
}