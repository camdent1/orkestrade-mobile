import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'supabase_service.dart';

class LocationService {
  static HttpServer? _server;
  static List<Map<String, dynamic>> _geofences = [];
  static final Map<String, String> _deviceTracker = {};
  
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.locationAlways.request();
    return status.isGranted;
  }
  
  static Future<void> loadGeofences() async {
    try {
      final projects = await SupabaseService.client
          .from('projects')
          .select('id, name, latitude, longitude, geofence_radius')
          .eq('status', 'active')
          .not('latitude', 'is', null)
          .not('longitude', 'is', null);
      
      _geofences = List<Map<String, dynamic>>.from(projects);
      print('Loaded ${_geofences.length} geofences');
    } catch (e) {
      print('Error loading geofences: $e');
    }
  }
  
  static Future<void> startWebhookServer({int port = 8080}) async {
    await loadGeofences();
    
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      print('Webhook server started on port $port');
      
      _server!.listen((HttpRequest request) async {
        await _handleWebhookRequest(request);
      });
    } catch (e) {
      print('Error starting webhook server: $e');
    }
  }
  
  static Future<void> stopWebhookServer() async {
    await _server?.close();
    _server = null;
    print('Webhook server stopped');
  }
  
  static Future<void> _handleWebhookRequest(HttpRequest request) async {
    try {
      if (request.method != 'POST') {
        _sendResponse(request.response, 405, 'Method not allowed');
        return;
      }
      
      final payload = await _readRequestBody(request);
      final webhookData = json.decode(payload);
      
      if (!_validateWebhookPayload(webhookData)) {
        _sendResponse(request.response, 400, 'Invalid payload');
        return;
      }
      
      final result = await _processWebhookPayload(webhookData);
      _sendResponse(request.response, result['status'], result['message']);
      
    } catch (e) {
      print('Error handling webhook: $e');
      _sendResponse(request.response, 500, 'Internal server error');
    }
  }
  
  static Future<String> _readRequestBody(HttpRequest request) async {
    final content = StringBuffer();
    await for (final chunk in request) {
      content.write(String.fromCharCodes(chunk));
    }
    return content.toString();
  }
  
  static bool _validateWebhookPayload(Map<String, dynamic> payload) {
    // Locative webhook schema validation
    if (!payload.containsKey('latitude') || !payload.containsKey('longitude')) {
      return false;
    }
    if (!payload.containsKey('device') || !payload.containsKey('trigger')) {
      return false;
    }
    
    final trigger = payload['trigger'] as String;
    if (trigger != 'test' && !payload.containsKey('id')) {
      return false;
    }
    
    // Validate coordinates
    try {
      final lat = double.parse(payload['latitude'].toString());
      final lng = double.parse(payload['longitude'].toString());
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        return false;
      }
    } catch (e) {
      return false;
    }
    
    return true;
  }
  
  static Future<Map<String, dynamic>> _processWebhookPayload(Map<String, dynamic> payload) async {
    final device = payload['device'] as String;
    final trigger = payload['trigger'] as String;
    final latitude = double.parse(payload['latitude'].toString());
    final longitude = double.parse(payload['longitude'].toString());
    
    switch (trigger.toLowerCase()) {
      case 'enter':
        return await _handleGeofenceEntry(device, payload['id'] as String, latitude, longitude);
      
      case 'exit':
        return await _handleGeofenceExit(device, payload['id'] as String, latitude, longitude);
      
      case 'test':
        return {'status': 200, 'message': 'OK'};
      
      default:
        print('Unidentified message: $trigger');
        return {'status': 422, 'message': 'Unprocessable entity'};
    }
  }
  
  static Future<Map<String, dynamic>> _handleGeofenceEntry(String device, String locationId, double lat, double lng) async {
    print('Device $device entered geofence $locationId');
    
    // Clean location ID (remove hyphens like Locative does)
    final cleanLocationId = locationId.replaceAll('-', '');
    
    // Update device tracker
    _deviceTracker[device] = cleanLocationId;
    
    // Find matching geofence project
    final project = _geofences.firstWhere(
      (g) => g['id'] == cleanLocationId,
      orElse: () => <String, dynamic>{},
    );
    
    if (project.isNotEmpty) {
      // Post location event to Supabase
      await SupabaseService.postLocationEvent(
        projectId: cleanLocationId,
        deviceId: device,
        latitude: lat,
        longitude: lng,
        eventType: 'enter',
      );
      
      print('Started timer for project: ${project['name']}');
    }
    
    return {'status': 200, 'message': 'OK'};
  }
  
  static Future<Map<String, dynamic>> _handleGeofenceExit(String device, String locationId, double lat, double lng) async {
    print('Device $device exited geofence $locationId');
    
    // Clean location ID
    final cleanLocationId = locationId.replaceAll('-', '');
    
    // Check if device was actually in this location
    if (_deviceTracker[device] != cleanLocationId) {
      // Device wasn't in this location, ignore exit
      return {'status': 200, 'message': 'OK'};
    }
    
    // Update device tracker to "not home"
    _deviceTracker[device] = 'not_home';
    
    // Find matching geofence project
    final project = _geofences.firstWhere(
      (g) => g['id'] == cleanLocationId,
      orElse: () => <String, dynamic>{},
    );
    
    if (project.isNotEmpty) {
      // Post location event to Supabase
      await SupabaseService.postLocationEvent(
        projectId: cleanLocationId,
        deviceId: device,
        latitude: lat,
        longitude: lng,
        eventType: 'exit',
      );
      
      print('Stopped timer for project: ${project['name']}');
    }
    
    return {'status': 200, 'message': 'OK'};
  }
  
  static void _sendResponse(HttpResponse response, int statusCode, String message) {
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.text;
    response.write(message);
    response.close();
  }
  
  static Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }
  
  static String? getDeviceLocation(String device) {
    return _deviceTracker[device];
  }
  
  static Map<String, String> getAllDeviceLocations() {
    return Map<String, String>.from(_deviceTracker);
  }
}