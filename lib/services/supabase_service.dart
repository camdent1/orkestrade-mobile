import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL']!;
  static String get supabaseKey => dotenv.env['SUPABASE_ANON_KEY']!;
  
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }
  
  static Future<bool> postLocationEvent({
    required String projectId,
    required String deviceId,
    required double latitude,
    required double longitude,
    required String eventType, // 'enter' or 'exit'
  }) async {
    try {
      // Post to location_events table (for tracking)
      final locationResponse = await client.from('location_events').insert({
        'project_id': projectId,
        'device_id': deviceId,
        'latitude': latitude,
        'longitude': longitude,
        'event_type': eventType,
        'created_at': DateTime.now().toIso8601String(),
      }).select();
      
      // Handle time tracking based on event type
      if (eventType == 'enter') {
        await _startTimer(projectId, deviceId, latitude, longitude);
      } else if (eventType == 'exit') {
        await _stopTimer(projectId, deviceId, latitude, longitude);
      }
      
      return locationResponse.isNotEmpty;
    } catch (e) {
      print('Error posting location event: $e');
      return false;
    }
  }
  
  static Future<void> _startTimer(String projectId, String deviceId, double lat, double lng) async {
    try {
      // Check if timer already exists for this device/project
      final existingTimer = await client
          .from('time_entries')
          .select('id')
          .eq('project_id', projectId)
          .eq('device_id', deviceId)
          .is_('end_time', null)
          .maybeSingle();
      
      if (existingTimer != null) {
        print('Timer already running for project $projectId on device $deviceId');
        return;
      }
      
      // Start new timer
      await client.from('time_entries').insert({
        'project_id': projectId,
        'device_id': deviceId,
        'start_time': DateTime.now().toIso8601String(),
        'start_latitude': lat,
        'start_longitude': lng,
        'entry_method': 'geofence',
        'status': 'active',
      });
      
      print('Started timer for project $projectId');
    } catch (e) {
      print('Error starting timer: $e');
    }
  }
  
  static Future<void> _stopTimer(String projectId, String deviceId, double lat, double lng) async {
    try {
      // Find active timer for this device/project
      final activeTimer = await client
          .from('time_entries')
          .select('id, start_time')
          .eq('project_id', projectId)
          .eq('device_id', deviceId)
          .is_('end_time', null)
          .maybeSingle();
      
      if (activeTimer == null) {
        print('No active timer found for project $projectId on device $deviceId');
        return;
      }
      
      final endTime = DateTime.now();
      final startTime = DateTime.parse(activeTimer['start_time']);
      final duration = endTime.difference(startTime).inMinutes;
      
      // Stop timer
      await client.from('time_entries')
          .update({
            'end_time': endTime.toIso8601String(),
            'end_latitude': lat,
            'end_longitude': lng,
            'duration_minutes': duration,
            'status': 'completed',
          })
          .eq('id', activeTimer['id']);
      
      print('Stopped timer for project $projectId (Duration: ${duration}min)');
    } catch (e) {
      print('Error stopping timer: $e');
    }
  }
  
  static Stream<List<Map<String, dynamic>>> getActiveTimers() {
    return client
        .from('active_timers')
        .stream(primaryKey: ['id'])
        .map((data) => List<Map<String, dynamic>>.from(data));
  }
  
  static Stream<List<Map<String, dynamic>>> getProjects() {
    return client
        .from('projects')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .map((data) => List<Map<String, dynamic>>.from(data));
  }
  
  static Future<bool> uploadReceipt({
    required String filePath,
    required String fileName,
  }) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      await client.storage
          .from('receipts')
          .uploadBinary('uploads/$fileName', bytes);
      
      return true;
    } catch (e) {
      print('Error uploading receipt: $e');
      return false;
    }
  }
}