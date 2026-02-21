import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const ShareLocationApp());
}

class ShareLocationApp extends StatelessWidget {
  const ShareLocationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Share Location',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const HomePage(),
    );
  }
}

ThemeData _buildLightTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    useMaterial3: true,
  );
}

ThemeData _buildDarkTheme() {
  const baseColor = Color(0xFF131726);
  const accent = Color(0xFF7C88FF);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: baseColor,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: Color(0xFF9AA2FF),
      surface: Color(0xFF1A1F33),
      onPrimary: Colors.white,
      onSurface: Colors.white,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF1D2338),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Random _random = Random();
  late final List<FriendLocation> _friends;
  Timer? _locationTimer;
  Timer? _selfTimer;
  bool _sharingEnabled = true;
  DateTime _lastSync = DateTime.now();
  double _myLat = 37.7749;
  double _myLng = -122.4194;

  @override
  void initState() {
    super.initState();
    _friends = [
      FriendLocation(name: 'Ava', latitude: 37.7790, longitude: -122.4190, speedKph: 4),
      FriendLocation(name: 'Liam', latitude: 37.7680, longitude: -122.4290, speedKph: 8),
      FriendLocation(name: 'Noah', latitude: 37.7720, longitude: -122.4090, speedKph: 2),
      FriendLocation(name: 'Mia', latitude: 37.7650, longitude: -122.4160, speedKph: 6),
    ];

    _locationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_sharingEnabled) return;
      setState(() {
        for (var i = 0; i < _friends.length; i++) {
          final drift = (_random.nextDouble() - 0.5) * 0.0012;
          final drift2 = (_random.nextDouble() - 0.5) * 0.0012;
          _friends[i] = _friends[i].copyWith(
            latitude: _friends[i].latitude + drift,
            longitude: _friends[i].longitude + drift2,
            speedKph: max(1, _friends[i].speedKph + (_random.nextDouble() * 4 - 2)),
          );
        }
        _lastSync = DateTime.now();
      });
    });

    _selfTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_sharingEnabled) return;
      setState(() {
        _myLat += (_random.nextDouble() - 0.5) * 0.0008;
        _myLng += (_random.nextDouble() - 0.5) * 0.0008;
      });
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _selfTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onlineCount = _sharingEnabled ? _friends.length + 1 : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Location'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusHero(
                sharingEnabled: _sharingEnabled,
                onlineCount: onlineCount,
                lastSync: _lastSync,
              ),
              const SizedBox(height: 16),
              _LiveMeCard(latitude: _myLat, longitude: _myLng, enabled: _sharingEnabled),
              const SizedBox(height: 16),
              Text('Friends nearby', style: theme.textTheme.titleLarge),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: _friends.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final friend = _friends[index];
                    return _FriendTile(friend: friend, enabled: _sharingEnabled);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _sharingEnabled = !_sharingEnabled;
            _lastSync = DateTime.now();
          });
        },
        icon: Icon(_sharingEnabled ? Icons.location_off : Icons.my_location),
        label: Text(_sharingEnabled ? 'Stop sharing' : 'Start sharing'),
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({
    required this.sharingEnabled,
    required this.onlineCount,
    required this.lastSync,
  });

  final bool sharingEnabled;
  final int onlineCount;
  final DateTime lastSync;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sec = now.difference(lastSync).inSeconds;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: sharingEnabled
              ? const [Color(0xFF5966FF), Color(0xFF7A4DFF)]
              : const [Color(0xFF40455E), Color(0xFF2D3045)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sharingEnabled ? 'Live sharing enabled' : 'Live sharing paused',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sharingEnabled
                ? '$onlineCount people visible · synced ${sec}s ago'
                : 'Your friends cannot see your location right now',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _LiveMeCard extends StatelessWidget {
  const _LiveMeCard({required this.latitude, required this.longitude, required this.enabled});

  final double latitude;
  final double longitude;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: enabled ? const Color(0x3324D484) : const Color(0x33F66666),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                enabled ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                color: enabled ? const Color(0xFF24D484) : const Color(0xFFF66666),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Text(
              enabled ? 'LIVE' : 'OFFLINE',
              style: TextStyle(
                color: enabled ? const Color(0xFF24D484) : const Color(0xFFF66666),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend, required this.enabled});

  final FriendLocation friend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF2C3150),
              child: Text(friend.name.substring(0, 1)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(friend.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${friend.latitude.toStringAsFixed(5)}, ${friend.longitude.toStringAsFixed(5)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${friend.speedKph.toStringAsFixed(1)} km/h',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: enabled ? const Color(0xFF24D484) : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      enabled ? 'updating' : 'paused',
                      style: TextStyle(
                        color: enabled ? const Color(0xFF24D484) : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FriendLocation {
  const FriendLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.speedKph,
  });

  final String name;
  final double latitude;
  final double longitude;
  final double speedKph;

  FriendLocation copyWith({
    String? name,
    double? latitude,
    double? longitude,
    double? speedKph,
  }) {
    return FriendLocation(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speedKph: speedKph ?? this.speedKph,
    );
  }
}
