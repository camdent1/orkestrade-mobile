import 'dart:convert';
import 'dart:io';

class WebhookTest {
  static Future<void> testWebhookEndpoint({
    String host = 'localhost',
    int port = 8080,
  }) async {
    final client = HttpClient();
    
    try {
      // Test payload matching Locative format
      final testPayload = {
        'latitude': '37.7749',
        'longitude': '-122.4194',
        'device': 'test-device-001',
        'trigger': 'test',
        'id': 'test-location-id'
      };
      
      final request = await client.postUrl(Uri.parse('http://$host:$port'));
      request.headers.contentType = ContentType.json;
      request.write(json.encode(testPayload));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      print('Test Response Status: ${response.statusCode}');
      print('Test Response Body: $responseBody');
      
      // Test geofence entry
      final entryPayload = {
        'latitude': '37.7749',
        'longitude': '-122.4194',
        'device': 'test-device-001',
        'trigger': 'enter',
        'id': 'project-123'
      };
      
      final entryRequest = await client.postUrl(Uri.parse('http://$host:$port'));
      entryRequest.headers.contentType = ContentType.json;
      entryRequest.write(json.encode(entryPayload));
      
      final entryResponse = await entryRequest.close();
      final entryResponseBody = await entryResponse.transform(utf8.decoder).join();
      
      print('Entry Response Status: ${entryResponse.statusCode}');
      print('Entry Response Body: $entryResponseBody');
      
      // Test geofence exit
      final exitPayload = {
        'latitude': '37.7750',
        'longitude': '-122.4195',
        'device': 'test-device-001',
        'trigger': 'exit',
        'id': 'project-123'
      };
      
      final exitRequest = await client.postUrl(Uri.parse('http://$host:$port'));
      exitRequest.headers.contentType = ContentType.json;
      exitRequest.write(json.encode(exitPayload));
      
      final exitResponse = await exitRequest.close();
      final exitResponseBody = await exitResponse.transform(utf8.decoder).join();
      
      print('Exit Response Status: ${exitResponse.statusCode}');
      print('Exit Response Body: $exitResponseBody');
      
    } catch (e) {
      print('Test Error: $e');
    } finally {
      client.close();
    }
  }
  
  static void printWebhookExample() {
    print('=== Locative Webhook Format ===');
    print('POST http://your-app-host:8080');
    print('Content-Type: application/json');
    print('');
    print('Entry Payload:');
    print(json.encode({
      'latitude': '37.7749',
      'longitude': '-122.4194', 
      'device': 'iphone-cameron',
      'trigger': 'enter',
      'id': 'takumi-workshop'
    }, toEncodable: null));
    print('');
    print('Exit Payload:');
    print(json.encode({
      'latitude': '37.7750',
      'longitude': '-122.4195',
      'device': 'iphone-cameron', 
      'trigger': 'exit',
      'id': 'takumi-workshop'
    }, toEncodable: null));
  }
}