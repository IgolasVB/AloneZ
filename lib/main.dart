import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return MaterialApp(
      title: 'Alonel Game',
      home: SafeArea(
        child: Scaffold(
          body: GameWidget(
            game: MyGame(padding: padding),
            autofocus: true,
            initialActiveOverlays: const ['StartMenu'],
            overlayBuilderMap: {
              'StartMenu': (BuildContext context, MyGame game) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'ALONE Z',
                        style: TextStyle(
                          color: Colors.cyan,
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () {
                          game.overlays.remove('StartMenu');
                          game.overlays.add('PauseButton');
                          game.resumeEngine();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('START GAME', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
              'GameOver': (BuildContext context, MyGame game) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'GAME OVER',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          game.overlays.remove('GameOver');
                          game.restart();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Restart', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
              'PauseButton': (BuildContext context, MyGame game) {
                return Positioned(
                  top: 60,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.pause, color: Colors.white, size: 36),
                    onPressed: () {
                      if (!game.isGameOver) {
                        game.pauseEngine();
                        game.overlays.remove('PauseButton');
                        game.overlays.add('PauseMenu');
                      }
                    },
                  ),
                );
              },
              'PauseMenu': (BuildContext context, MyGame game) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'PAUSED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () {
                          game.overlays.remove('PauseMenu');
                          game.overlays.add('PauseButton');
                          game.resumeEngine();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('RESUME', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            },
          ),
        ),
      ),
    );
  }
}

class MyGame extends FlameGame
    with KeyboardEvents, PanDetector, TapDetector, HasCollisionDetection {
  late Player player;
  final List<Enemy> enemies = [];
  late TextComponent livesText;
  late TextComponent scoreText;
  late TextComponent levelText;
  late TextComponent highScoreText;
  late SharedPreferences prefs;
  late EdgeInsets padding;
  bool isGameOver = false;
  int score = 0;
  int highScore = 0;
  int currentLevel = 1;

  MyGame({required this.padding});

  @override
  void update(double dt) {
    super.update(dt);
    if (!isGameOver) {
      // Removed random enemy spawn for level-based gameplay
    }
  }

  @override
  Future<void> onLoad() async {
    // Carrega o high score
    prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('highScore') ?? 0;

    // Preload audio
    try {
      // await FlameAudio.audioCache.load('shot.mp3');
    } catch (e) {
      print('Failed to load audio: $e');
    }

    // Add background
    final background = Background();
    background.size = size;
    add(background);

    player = Player();
    player.gameSize = size;
    player.position = Vector2(
      size.x / 2 - Player.playerSize / 2,
      size.y - Player.playerSize - 20,
    );
    add(player);

    final textStyle = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(blurRadius: 4.0, color: Colors.black, offset: Offset(2, 2)),
        ],
      ),
    );

    livesText = TextComponent(
      text: '❤️ x${player.lives}',
      position: Vector2(15, 15),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          shadows: [
            Shadow(blurRadius: 4.0, color: Colors.black, offset: Offset(2, 2)),
          ],
        ),
      ),
    );
    add(livesText);

    scoreText = TextComponent(
      text: 'SCORE: $score',
      position: Vector2(size.x / 2, 15),
      anchor: Anchor.topCenter,
      textRenderer: textStyle,
    );
    add(scoreText);

    highScoreText = TextComponent(
      text: 'HI-SCORE: $highScore',
      position: Vector2(size.x / 2, 45),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 4.0, color: Colors.black, offset: Offset(2, 2))],
        ),
      ),
    );
    add(highScoreText);

    levelText = TextComponent(
      text: 'LEVEL: $currentLevel',
      position: Vector2(size.x - 15, 15),
      anchor: Anchor.topRight,
      textRenderer: textStyle,
    );
    add(levelText);

    // Add enemies for level 1
    spawnLevel();
    
    // Pause the engine initially so the Start Menu handles resuming
    pauseEngine();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          player.isMovingLeft = true;
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowRight:
          player.isMovingRight = true;
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowUp:
          player.isMovingUp = true;
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowDown:
          player.isMovingDown = true;
          return KeyEventResult.handled;
        case LogicalKeyboardKey.space:
          player.shoot();
          return KeyEventResult.handled;
      }
    } else if (event is KeyUpEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          player.isMovingLeft = false;
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowRight:
          player.isMovingRight = false;
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowUp:
          player.isMovingUp = false;
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowDown:
          player.isMovingDown = false;
          return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    player.position += info.delta.global;
  }

  @override
  void onTapDown(TapDownInfo info) {
    player.shoot();
  }

  void updateLives() {
    livesText.text = '❤️ x${player.lives}';
  }

  void updateScore() {
    scoreText.text = 'SCORE: $score';
    if (score > highScore) {
      highScore = score;
      highScoreText.text = 'HI-SCORE: $highScore';
      prefs.setInt('highScore', highScore);
    }
  }

  void updateLevel() {
    levelText.text = 'LEVEL: $currentLevel';
  }

  void spawnHeartPowerup() {
    final heart = HeartPowerup()
      ..position = Vector2(Random().nextDouble() * (size.x - 30), -30)
      ..gameSize = size;
    add(heart);
  }

  void spawnWeaponPowerup() {
    final powerup = WeaponPowerup()
      ..position = Vector2(Random().nextDouble() * (size.x - 30), -30)
      ..gameSize = size;
    add(powerup);
  }

  void spawnLevel() {
    enemies.clear();
    
    // Até o level 9 vai aumentando as naves, a partir do 10 estabiliza em 5 naves
    int numEnemies = currentLevel < 10 ? currentLevel + 1 : 5;
    
    for (int i = 0; i < numEnemies; i++) {
      final enemy = Enemy();
      enemy.gameSize = size;
      enemy.player = player;
      enemy.level = currentLevel;
      enemy.maxHealth = currentLevel;
      enemy.health = enemy.maxHealth;
      enemy.position = Vector2(
        (size.x / (numEnemies + 1)) * (i + 1),
        size.y * 0.2,
      );
      enemies.add(enemy);
      add(enemy);
    }
  }

  void gameOver() {
    if (isGameOver) return;
    isGameOver = true;
    overlays.remove('PauseButton');
    overlays.add('GameOver');
    pauseEngine();
  }

  void restart() {
    isGameOver = false;
    score = 0;
    currentLevel = 1;
    player.lives = 3;
    player.hitCount = 0;
    player.weaponLevel = 1;
    player.shootInterval = 1.0;
    updateScore();
    updateLevel();
    updateLives();
    
    player.position = Vector2(
      size.x / 2 - Player.playerSize / 2,
      size.y - Player.playerSize - 20,
    );
    
    children.whereType<Enemy>().forEach((enemy) => enemy.removeFromParent());
    children.whereType<Bullet>().forEach((bullet) => bullet.removeFromParent());
    children.whereType<PlayerBullet>().forEach((bullet) => bullet.removeFromParent());
    children.whereType<Explosion>().forEach((explosion) => explosion.removeFromParent());
    
    enemies.clear();
    spawnLevel();
    overlays.add('PauseButton');
    resumeEngine();
  }
}

class Player extends SpriteComponent with CollisionCallbacks {
  static const double speed = 200.0;
  static const double playerSize = 50.0;

  bool isMovingLeft = false;
  bool isMovingRight = false;
  bool isMovingUp = false;
  bool isMovingDown = false;

  late Vector2 gameSize;
  int lives = 3;
  int hitCount = 0;
  double shootTimer = 0.0;
  double shootInterval = 1.0; // Shoot every 1 second
  int weaponLevel = 1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await Sprite.load('ship.png');
    size = Vector2.all(playerSize);
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isMovingLeft) {
      position.x -= speed * dt;
    }
    if (isMovingRight) {
      position.x += speed * dt;
    }
    if (isMovingUp) {
      position.y -= speed * dt;
    }
    if (isMovingDown) {
      position.y += speed * dt;
    }
    // Clamp position to screen boundaries
    position.x = position.x.clamp(0.0, gameSize.x - size.x);
    position.y = position.y.clamp(0.0, gameSize.y - size.y);

    // Player shooting
    shootTimer += dt;
    if (shootTimer >= shootInterval) {
      shootTimer = 0.0;
      shoot();
    }
  }

  void heal() {
    lives++;
    (parent as MyGame).updateLives();
  }

  void takeDamage() {
    if ((parent as MyGame).isGameOver) return;
    
    hitCount++;
    if (hitCount % 2 == 0) {
      lives--;
      if (lives < 0) lives = 0;
      (parent as MyGame).updateLives();
      if (lives <= 0) {
        (parent as MyGame).gameOver();
      }
    }
  }

  void upgradeWeapon() {
    if (shootInterval > 0.3) {
      shootInterval -= 0.15; // Atira mais rápido
    } else if (weaponLevel < 3) {
      weaponLevel++; // Adiciona mais tiros simultâneos
    }
  }

  void shoot() {
    if (weaponLevel == 1) {
      _spawnBullet(Vector2(0, -1));
    } else if (weaponLevel == 2) {
      _spawnBullet(Vector2(-0.2, -1));
      _spawnBullet(Vector2(0.2, -1));
    } else {
      _spawnBullet(Vector2(-0.3, -1));
      _spawnBullet(Vector2(0, -1));
      _spawnBullet(Vector2(0.3, -1));
    }
    
    // Play sound
    try {
      // FlameAudio.play('shot.mp3', volume: 0.3);
    } catch (e) {
      // Silently fail if audio doesn't exist
    }
  }

  void _spawnBullet(Vector2 dir) {
    final bullet = PlayerBullet();
    bullet.position =
        position.clone() +
            Vector2(size.x / 2 - bullet.size.x / 2, -bullet.size.y);
    bullet.direction = dir.normalized();
    (parent as MyGame).add(bullet);
  }
}

class Background extends SpriteComponent {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await Sprite.load('background.png');
  }
}

class PlayerBullet extends PositionComponent with CollisionCallbacks {
  static const double bulletSize = 8.0;
  static const double speed = 400.0;
  late Vector2 direction;

  @override
  Future<void> onLoad() async {
    this.size = Vector2.all(bulletSize);
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direction * speed * dt;
    // Remove if off screen
    final gameSize = (parent as MyGame).size;
    if (position.x < -size.x ||
        position.x > gameSize.x + size.x ||
        position.y < -size.y ||
        position.y > gameSize.y + size.y) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Enemy) {
      // Damage enemy
      other.health--;
      removeFromParent(); // Remove bullet
      if (other.health <= 0) {
        // Enemy dies
        other.removeFromParent();
        (parent as MyGame).enemies.remove(other);
        final game = parent as MyGame;
        game.score += 10; // Add score
        game.updateScore();
        
        // Check for extra life every 100 score
        if (game.score > 0 && game.score % 100 == 0) {
          game.spawnHeartPowerup();
        }
        
        // Check for weapon upgrade every 150 score
        if (game.score > 0 && game.score % 150 == 0) {
          game.spawnWeaponPowerup();
        }
        
        // Check if level complete
        if (game.enemies.isEmpty) {
          game.currentLevel++;
          game.updateLevel();
          game.spawnLevel();
        }
      }
      // Create explosion animation
      final explosion = Explosion()
        ..position = other.position.clone()
        ..gameSize = other.gameSize;
      (parent as MyGame).add(explosion);
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Colors.cyan,
    );
  }
}

class Enemy extends SpriteComponent {
  static const double enemySize = 40.0;
  late Vector2 gameSize;
  late Player player;
  double shootTimer = 0.0;
  late double shootInterval;
  late double moveSpeed;
  double direction = 1.0; // 1 for right, -1 for left
  late int health; // New: health system
  late int maxHealth; // New: max health system
  late int level;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await Sprite.load('ship2.png');
    size = Vector2.all(enemySize);
    add(CircleHitbox());
    
    // Calcula dificuldade a cada 10 níveis
    int difficultyTier = level ~/ 10;
    
    // Mais rápido a cada 10 níveis (começa em 50)
    moveSpeed = 50.0 + (difficultyTier * 20.0);
    
    if (difficultyTier >= 1) {
      // A partir do level 10, como tem menos naves, elas atiram BEM mais rápido para compensar
      shootInterval = max(0.4, 0.9 - (difficultyTier * 0.1));
    } else {
      // Levels 1 a 9 atiram devagar
      shootInterval = 1.8;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    shootTimer += dt;
    if (shootTimer >= shootInterval) {
      shootTimer = 0.0;
      shoot();
    }
    // Move left and right slowly
    position.x += moveSpeed * direction * dt;
    if (position.x <= 0 || position.x >= gameSize.x - size.x) {
      direction = -direction;
    }
    // Clamp to prevent sticking
    position.x = position.x.clamp(0.0, gameSize.x - size.x);
  }

  void shoot() {
    final bullet = Bullet();
    bullet.position = position.clone();
    bullet.difficultyTier = level ~/ 10; // Repassa a dificuldade para a bala

    // Calculate base direction towards player
    Vector2 toPlayer = player.position - position;
    Vector2 baseDirection;
    if (toPlayer.length > 0.1) {
      baseDirection = toPlayer.normalized();
    } else {
      // If too close, shoot in a random direction
      double angle = Random().nextDouble() * 2 * pi;
      baseDirection = Vector2(cos(angle), sin(angle));
    }

    // Add random angle variation (±30 degrees)
    double randomAngle =
        (Random().nextDouble() - 0.5) * pi / 3; // ±30 degrees in radians

    // Rotate the direction vector
    double cosAngle = cos(randomAngle);
    double sinAngle = sin(randomAngle);
    Vector2 rotatedDirection = Vector2(
      baseDirection.x * cosAngle - baseDirection.y * sinAngle,
      baseDirection.x * sinAngle + baseDirection.y * cosAngle,
    );

    bullet.direction = rotatedDirection;
    (parent as MyGame).add(bullet);
    // Play sound
    try {
      // FlameAudio.play('shot.mp3', volume: 0.5);
    } catch (e) {
      // Silently fail if audio doesn't exist
    }
  }


}

class Bullet extends PositionComponent with CollisionCallbacks {
  static const double bulletSize = 10.0;
  late double speed;
  late Vector2 direction;
  int difficultyTier = 0;

  @override
  Future<void> onLoad() async {
    this.size = Vector2.all(bulletSize);
    add(CircleHitbox());
    
    // A bala fica mais rápida a cada 10 níveis
    speed = 250.0 + (difficultyTier * 50.0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direction * speed * dt;
    // Remove if off screen
    final gameSize = (parent as MyGame).size;
    if (position.x < -size.x ||
        position.x > gameSize.x + size.x ||
        position.y < -size.y ||
        position.y > gameSize.y + size.y) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      other.takeDamage();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()..color = Colors.yellow,
    );
  }
}

class Explosion extends PositionComponent {
  late Vector2 gameSize;
  double lifeTimer = 0.0;
  static const double maxLife = 0.5; // Duração da explosão
  final List<_ExplosionParticle> particles = [];
  
  // Pré-alocar objetos Paint para evitar criar centenas por frame
  final Paint _mainPaint = Paint()..style = PaintingStyle.fill;
  final Paint _glowPaint = Paint()..style = PaintingStyle.fill;

  Explosion() : super(size: Vector2.all(64.0)) {
    final random = Random();
    // Gerar 25 partículas para a explosão
    for (int i = 0; i < 25; i++) {
      double angle = random.nextDouble() * 2 * pi;
      double speed = random.nextDouble() * 150 + 50; // Velocidade aleatória
      double particleSize = random.nextDouble() * 4 + 2; // Tamanho aleatório
      Color color = [
        const Color(0xFFFF0000), // Vermelho
        const Color(0xFFFF6B35), // Laranja escuro
        const Color(0xFFFFA500), // Laranja claro
        const Color(0xFFFFFFFF), // Branco
      ][random.nextInt(4)];
      
      particles.add(_ExplosionParticle(
        velocity: Vector2(cos(angle), sin(angle)) * speed,
        color: color,
        size: particleSize,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (parent != null) {
      gameSize = (parent as MyGame).size;
    }
    
    lifeTimer += dt;
    if (lifeTimer >= maxLife) {
      removeFromParent();
    }
    
    // Atualizar posição das partículas
    for (var particle in particles) {
      particle.position += particle.velocity * dt;
      particle.velocity *= 0.92; // Desaceleração suave (fricção)
    }
  }

  @override
  void render(Canvas canvas) {
    double progress = lifeTimer / maxLife;
    double opacity = 1.0 - progress;
    if (opacity <= 0.0) return;

    final center = Offset(size.x / 2, size.y / 2);

    for (var particle in particles) {
      final currentSize = particle.size * (1.0 - progress * 0.5);
      final offset = center + Offset(particle.position.x, particle.position.y);
      
      // Efeito de brilho super leve (sem Blur pesado, apenas um círculo maior semi-transparente)
      _glowPaint.color = particle.color.withOpacity(opacity * 0.3);
      canvas.drawCircle(offset, currentSize * 2.5, _glowPaint);
      
      // Partícula principal
      _mainPaint.color = particle.color.withOpacity(opacity);
      canvas.drawCircle(offset, currentSize, _mainPaint);
    }
  }
}

class _ExplosionParticle {
  Vector2 position = Vector2.zero();
  Vector2 velocity;
  Color color;
  double size;

  _ExplosionParticle({
    required this.velocity,
    required this.color,
    required this.size,
  });
}

class HeartPowerup extends PositionComponent with CollisionCallbacks {
  static const double heartSize = 30.0;
  late Vector2 gameSize;
  static const double fallSpeed = 150.0;

  HeartPowerup() : super(size: Vector2.all(heartSize)) {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += fallSpeed * dt;
    if (parent != null) {
      gameSize = (parent as MyGame).size;
      if (position.y > gameSize.y + size.y) {
        removeFromParent();
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      other.heal();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final textPaint = TextPaint(
      style: const TextStyle(
        fontSize: 30,
        shadows: [Shadow(blurRadius: 4.0, color: Colors.black, offset: Offset(2, 2))],
      ),
    );
    textPaint.render(canvas, '❤️', Vector2.zero());
  }
}

class WeaponPowerup extends PositionComponent with CollisionCallbacks {
  static const double itemSize = 30.0;
  late Vector2 gameSize;
  static const double fallSpeed = 150.0;

  WeaponPowerup() : super(size: Vector2.all(itemSize)) {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += fallSpeed * dt;
    if (parent != null) {
      gameSize = (parent as MyGame).size;
      if (position.y > gameSize.y + size.y) {
        removeFromParent();
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      other.upgradeWeapon();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final textPaint = TextPaint(
      style: const TextStyle(
        fontSize: 30,
        shadows: [Shadow(blurRadius: 4.0, color: Colors.black, offset: Offset(2, 2))],
      ),
    );
    textPaint.render(canvas, '⚡', Vector2.zero());
  }
}
