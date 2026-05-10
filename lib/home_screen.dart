import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'registered_face.dart';
import 'face_embedding_service.dart';
import 'face_storage_service.dart';
import 'register_screen.dart';
import 'recognize_screen.dart';
import 'registered_faces_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final FaceEmbeddingService _embeddingService;
  late final FaceStorageService _storageService;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _embeddingService = FaceEmbeddingService();
    await _embeddingService.initialize();
    _storageService = FaceStorageService(_embeddingService);
    _storageService.init();
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _embeddingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: _ready ? _buildBody() : _buildLoading(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF00E5FF)),
          const SizedBox(height: 20),
          const Text('Initializing…', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            _embeddingService.isInitialized
                ? 'Model ready ✔'
                : 'Downloading face recognition model\n(~2 MB, first launch only)',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.face_retouching_natural,
                      color: Color(0xFF00E5FF), size: 24),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FaceID',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5)),
                    Text('Recognition System',
                        style: TextStyle(fontSize: 13, color: Colors.white38)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Stats card
            ValueListenableBuilder(
              valueListenable: Hive.box<RegisteredFace>('faces').listenable(),
              builder: (context, box, _) {
                return _StatsCard(count: box.length);
              },
            ),

            const SizedBox(height: 32),

            const Text('Actions',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),

            // Action cards
            _ActionCard(
              icon: Icons.person_add_alt_1_rounded,
              title: 'Register Face',
              subtitle: 'Enroll a new person',
              color: const Color(0xFF00E5FF),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RegisterScreen(
                    embeddingService: _embeddingService,
                    storageService: _storageService,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.manage_search_rounded,
              title: 'Recognize Face',
              subtitle: 'Identify a registered person',
              color: const Color(0xFF69FF8E),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecognizeScreen(
                    embeddingService: _embeddingService,
                    storageService: _storageService,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.people_alt_rounded,
              title: 'Registered Faces',
              subtitle: 'View & manage enrolled users',
              color: const Color(0xFFFF8C69),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RegisteredFacesScreen(storageService: _storageService),
                ),
              ),
            ),
            const SizedBox(height: 24), // Added some bottom padding
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int count;
  const _StatsCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00E5FF).withOpacity(0.12),
            const Color(0xFF00E5FF).withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$count',
                  style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF00E5FF),
                      height: 1)),
              const SizedBox(height: 4),
              Text(count == 1 ? 'Person registered' : 'People registered',
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
          const Spacer(),
          Icon(
            count > 0 ? Icons.verified_user_rounded : Icons.person_off_rounded,
            color: const Color(0xFF00E5FF).withOpacity(0.4),
            size: 48,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }
}
