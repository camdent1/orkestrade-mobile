import 'package:flutter/material.dart';
import 'dart:async';
import '../services/location_service.dart';
import '../services/camera_service.dart';
import '../services/supabase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _locationMonitoring = false;
  List<Map<String, dynamic>> _activeTimers = [];
  List<Map<String, dynamic>> _projects = [];
  StreamSubscription? _timersSubscription;
  StreamSubscription? _projectsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _timersSubscription?.cancel();
    _projectsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    // Listen to active timers
    _timersSubscription = SupabaseService.getActiveTimers().listen((timers) {
      setState(() {
        _activeTimers = timers;
      });
    });

    // Listen to projects
    _projectsSubscription = SupabaseService.getProjects().listen((projects) {
      setState(() {
        _projects = projects;
      });
    });
  }

  Future<void> _toggleLocationMonitoring() async {
    if (_locationMonitoring) {
      LocationService.stopLocationMonitoring();
      setState(() {
        _locationMonitoring = false;
      });
    } else {
      await LocationService.startLocationMonitoring();
      setState(() {
        _locationMonitoring = true;
      });
    }
  }

  Future<void> _captureReceipt() async {
    final imageFile = await CameraService.captureReceipt();
    if (imageFile != null) {
      final success = await CameraService.uploadAndProcessReceipt(imageFile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Receipt uploaded successfully!'
                : 'Failed to upload receipt'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orkestrade Mobile'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Location monitoring card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _locationMonitoring ? Icons.location_on : Icons.location_off,
                      color: _locationMonitoring ? Colors.green : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Monitoring',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _locationMonitoring ? 'Active' : 'Inactive',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _locationMonitoring,
                      onChanged: (value) => _toggleLocationMonitoring(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Active timers section
            if (_activeTimers.isNotEmpty) ...[
              Text(
                'Active Timers',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 1,
                child: ListView.builder(
                  itemCount: _activeTimers.length,
                  itemBuilder: (context, index) {
                    final timer = _activeTimers[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.timer, color: Colors.green),
                        title: Text(timer['project_name'] ?? 'Unknown Project'),
                        subtitle: Text('Source: ${timer['timer_source'] ?? 'Unknown'}'),
                        trailing: Text(
                          timer['start_time'] != null
                              ? DateTime.parse(timer['start_time']).toLocal().toString().split('.')[0]
                              : '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Projects section
            if (_projects.isNotEmpty) ...[
              Text(
                'Active Projects (${_projects.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: ListView.builder(
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final project = _projects[index];
                    final hasGeofence = project['latitude'] != null && 
                                       project['longitude'] != null;
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          hasGeofence ? Icons.location_on : Icons.location_off,
                          color: hasGeofence ? Colors.green : Colors.grey,
                        ),
                        title: Text(project['name'] ?? 'Unknown Project'),
                        subtitle: Text(project['client_name'] ?? 'No client'),
                        trailing: hasGeofence
                            ? Text('${project['geofence_radius'] ?? 150}m')
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _captureReceipt,
        tooltip: 'Capture Receipt',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}