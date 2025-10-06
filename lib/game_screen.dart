import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ic9_halloween_storybook/title_screen.dart';

class SpookyItem {
  final int id;
  final String imagePath;
  final bool isTrap;
  double top;
  double left;
  double opacity;

  SpookyItem({
    required this.id,
    required this.imagePath,
    required this.isTrap,
    this.top = 0,
    this.left = 0,
    this.opacity = 1.0,
  });
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final List<SpookyItem> _items = [];
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final Random _random = Random();
  bool _isGameActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupGame());
  }

  void _setupGame() {
    _musicPlayer.play(AssetSource('audio/background_music.mp3'));
    _musicPlayer.setReleaseMode(ReleaseMode.loop);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final allItemPaths = [
      'assets/images/pumpkin.png',
      'assets/images/ghost.png',
      'assets/images/bat.png',
      'assets/images/spider.png',
      'assets/images/skull.png',
    ];
    allItemPaths.shuffle();

    final winningPath = allItemPaths.first;
    final trapPaths = allItemPaths.sublist(1);

    setState(() {
      // Create the single winning item
      _items.add(SpookyItem(
        id: 0,
        imagePath: winningPath,
        isTrap: false,
        top: _random.nextDouble() * (screenHeight - 100),
        left: _random.nextDouble() * (screenWidth - 100),
        opacity: 0.5 + _random.nextDouble() * 0.5,
      ));
      // Create multiple trap items
      for (int i = 1; i < 15; i++) {
        _items.add(SpookyItem(
          id: i,
          imagePath: trapPaths[_random.nextInt(trapPaths.length)], // Pick a random trap
          isTrap: true,
          top: _random.nextDouble() * (screenHeight - 100),
          left: _random.nextDouble() * (screenWidth - 100),
          opacity: 0.5 + _random.nextDouble() * 0.5,
        ));
      }
    });

    Future.delayed(const Duration(milliseconds: 500), _animateItems);
  }
  
  void _animateItems() {
    if (!mounted || !_isGameActive) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    setState(() {
      for (var item in _items) {
        item.left += (_random.nextDouble() * 20) - 10;
        item.top += (_random.nextDouble() * 20) - 10;
        item.left = item.left.clamp(0, screenWidth - 80);
        item.top = item.top.clamp(0, screenHeight - 80);
        item.opacity = 0.4 + _random.nextDouble() * 0.6;
      }
    });

    Future.delayed(const Duration(seconds: 2), _animateItems);
  }

  void _onItemTapped(SpookyItem item) {
    if (!_isGameActive) return;

    if (item.isTrap) {
      // Play sound
      _sfxPlayer.play(AssetSource('audio/jumpscare.mp3'));

      ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide previous message if any
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("👻 Oops! That's a trap!"),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Winning logic remains the same
      setState(() {
        _isGameActive = false;
        _musicPlayer.stop();
      });
      _sfxPlayer.play(AssetSource('audio/win_sound.mp3'));
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.orange.shade800,
          title: const Text('Congratulations!'),
          content: const Text('You Found It! Happy Halloween!'),
          actions: [
            TextButton(
              onPressed: () {
                 Navigator.of(context).pop();
                 Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const TitleScreen())
                 );
              },
              child: const Text('Play Again', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/images/background.jpg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          ..._items.map((item) {
            return AnimatedPositioned(
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              top: item.top,
              left: item.left,
              child: GestureDetector(
                onTap: () => _onItemTapped(item),
                child: AnimatedOpacity(
                  duration: const Duration(seconds: 2),
                  opacity: item.opacity,
                  child: Image.asset(item.imagePath, width: 80),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}