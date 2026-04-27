import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async' as async;
import 'dart:math';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isMobileAdsSupported) {
    await MobileAds.instance.initialize();
  }
  runApp(const MyApp());
}

bool get isMobileAdsSupported {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

String get freeCoinsRewardedAdUnitId {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      if (kDebugMode) {
        return 'ca-app-pub-3940256099942544/5224354917';
      }
      return 'ca-app-pub-6322228074557650/6767991465';
    case TargetPlatform.iOS:
      return 'ca-app-pub-3940256099942544/1712485313';
    default:
      return '';
  }
}

enum ShipUpgradeType {
  damage,
  fireRate,
  bulletSpeed,
  shieldDuration,
  doubleShot,
}

enum ControlMode { drag, joystick }

extension ControlModeDetails on ControlMode {
  String get storageValue => switch (this) {
    ControlMode.drag => 'drag',
    ControlMode.joystick => 'joystick',
  };

  String get title => switch (this) {
    ControlMode.drag => 'ARRASTAR',
    ControlMode.joystick => 'ANALOGICO',
  };

  String get description => switch (this) {
    ControlMode.drag => 'Mover arrastando e tiro automatico.',
    ControlMode.joystick => 'Mover no analogico e atirar no botao.',
  };

  static ControlMode fromStorage(String? value) {
    return ControlMode.values.firstWhere(
      (mode) => mode.storageValue == value,
      orElse: () => ControlMode.drag,
    );
  }
}

extension ShipUpgradeTypeDetails on ShipUpgradeType {
  String get title => switch (this) {
    ShipUpgradeType.damage => 'DANO +1',
    ShipUpgradeType.fireRate => 'TIRO +10%',
    ShipUpgradeType.bulletSpeed => 'LASER +15%',
    ShipUpgradeType.shieldDuration => 'ESCUDO +2S',
    ShipUpgradeType.doubleShot => 'TIRO DUPLO',
  };

  String get description => switch (this) {
    ShipUpgradeType.damage => 'Seus tiros causam mais dano.',
    ShipUpgradeType.fireRate => 'Sua nave atira mais rapido.',
    ShipUpgradeType.bulletSpeed => 'Seus lasers viajam mais rapido.',
    ShipUpgradeType.shieldDuration => 'Escudos duram mais tempo.',
    ShipUpgradeType.doubleShot => 'Dispara dois lasers por vez.',
  };

  IconData get icon => switch (this) {
    ShipUpgradeType.damage => Icons.local_fire_department,
    ShipUpgradeType.fireRate => Icons.bolt,
    ShipUpgradeType.bulletSpeed => Icons.speed,
    ShipUpgradeType.shieldDuration => Icons.shield,
    ShipUpgradeType.doubleShot => Icons.call_split,
  };

  Color get color => switch (this) {
    ShipUpgradeType.damage => Colors.redAccent,
    ShipUpgradeType.fireRate => Colors.amberAccent,
    ShipUpgradeType.bulletSpeed => Colors.lightBlueAccent,
    ShipUpgradeType.shieldDuration => Colors.cyanAccent,
    ShipUpgradeType.doubleShot => Colors.greenAccent,
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return MaterialApp(
      title: 'AloneZ',
      home: SafeArea(
        child: Scaffold(
          body: GameWidget(
            game: MyGame(padding: padding),
            autofocus: true,
            initialActiveOverlays: const ['StartMenu'],
            overlayBuilderMap: {
              'StartMenu': (BuildContext context, MyGame game) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/fundomenu.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: Container(color: const Color(0x66000000)),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/alonez.png',
                            width: 320,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 20),
                          CoinCounter(value: game.coins, fontSize: 28),
                          const SizedBox(height: 40),
                          MainMenuButton(
                            label: 'PLAY',
                            primary: true,
                            icon: Icons.play_arrow,
                            onPressed: () {
                              game.overlays.remove('StartMenu');
                              game.overlays.add('PauseButton');
                              game.resumeEngine();
                            },
                          ),
                          const SizedBox(height: 20),
                          MainMenuButton(
                            label: 'LOJA',
                            icon: Icons.store,
                            onPressed: () {
                              game.overlays.remove('StartMenu');
                              game.overlays.add('ShopMenu');
                            },
                          ),
                          const SizedBox(height: 20),
                          MainMenuButton(
                            label: 'INVENTARIO',
                            icon: Icons.rocket_launch,
                            onPressed: () {
                              game.overlays.remove('StartMenu');
                              game.overlays.add('InventoryMenu');
                            },
                          ),
                          const SizedBox(height: 20),
                          MainMenuButton(
                            label: 'COINS GRATIS',
                            icon: Icons.smart_display,
                            onPressed: () {
                              game.overlays.remove('StartMenu');
                              game.overlays.add('FreeCoinsMenu');
                            },
                          ),
                          const SizedBox(height: 20),
                          MainMenuButton(
                            label: 'MISSOES',
                            icon: Icons.star,
                            onPressed: () {
                              game.overlays.remove('StartMenu');
                              game.overlays.add('MissionsMenu');
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Material(
                        color: Colors.transparent,
                        child: IconButton(
                          onPressed: () {
                            game.overlays.remove('StartMenu');
                            game.overlays.add('SettingsMenu');
                          },
                          icon: const Icon(Icons.settings),
                          color: Colors.white,
                          iconSize: 34,
                          tooltip: 'Configuracoes',
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0x99020712),
                            foregroundColor: Colors.white,
                            fixedSize: const Size(54, 54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(
                                color: Colors.cyan,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              'SettingsMenu': (BuildContext context, MyGame game) {
                return SettingsMenuView(
                  game: game,
                  onBack: () {
                    game.overlays.remove('SettingsMenu');
                    game.overlays.add('StartMenu');
                  },
                );
              },
              'MissionsMenu': (BuildContext context, MyGame game) {
                return StatefulBuilder(
                  builder: (context, setState) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'MISSOES',
                            style: TextStyle(
                              color: Colors.cyan,
                              fontSize: 54,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(blurRadius: 10, color: Colors.black),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          MissionCard(
                            icon: Icons.local_fire_department,
                            title: 'DESTRUA 100 INIMIGOS',
                            progressText: game.destroyEnemiesMissionText,
                            color: Colors.pinkAccent,
                            actionText: game.canClaimDestroyEnemiesMission
                                ? 'RESGATAR C ${MyGame.destroyEnemiesMissionReward}'
                                : null,
                            onAction: () {
                              game.claimDestroyEnemiesMission();
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 14),
                          MissionCard(
                            icon: Icons.military_tech,
                            title: 'ALCANCE O LEVEL 20',
                            progressText: game.reachLevelMissionText,
                            color: Colors.lightBlueAccent,
                            actionText: game.canClaimReachLevelMission
                                ? 'RESGATAR C ${MyGame.reachLevelMissionReward}'
                                : null,
                            onAction: () {
                              game.claimReachLevelMission();
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 14),
                          MissionCard(
                            icon: Icons.emoji_events,
                            title: 'BATA SEU HI-SCORE',
                            progressText: game.beatHighScoreMissionText,
                            color: Colors.amber,
                            actionText: game.canClaimBeatHighScoreMission
                                ? 'RESGATAR C ${MyGame.beatHighScoreMissionReward}'
                                : null,
                            onAction: () {
                              game.claimBeatHighScoreMission();
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: () {
                              game.overlays.remove('MissionsMenu');
                              game.overlays.add('StartMenu');
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 15,
                              ),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text(
                              'VOLTAR',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              'FreeCoinsMenu': (BuildContext context, MyGame game) {
                return FreeCoinsMenuView(
                  game: game,
                  onBack: () {
                    game.overlays.remove('FreeCoinsMenu');
                    game.overlays.add('StartMenu');
                  },
                );
              },
              'ShopMenu': (BuildContext context, MyGame game) {
                return StatefulBuilder(
                  builder: (context, setState) {
                    return Stack(
                      children: [
                        SingleChildScrollView(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 20),
                                const Text(
                                  'LOJA',
                                  style: TextStyle(
                                    color: Colors.cyan,
                                    fontSize: 64,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                CoinCounter(value: game.coins, fontSize: 28),
                                const SizedBox(height: 30),
                                Wrap(
                                  spacing: 20,
                                  runSpacing: 20,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    ShopShipCard(
                                      imagePath: 'assets/images/ship1.png',
                                      name: 'NAVE CIANO',
                                      price: MyGame.ship1Price,
                                      owned: game.ownsShip1,
                                      canBuy: game.canBuyShip1,
                                      onBuy: () {
                                        game.buyShip1();
                                        setState(() {});
                                      },
                                    ),
                                    ShopShipCard(
                                      imagePath: 'assets/images/ship3.png',
                                      name: 'NAVE RUBI',
                                      price: MyGame.ship3Price,
                                      owned: game.ownsShip3,
                                      canBuy: game.canBuyShip3,
                                      onBuy: () {
                                        game.buyShip3();
                                        setState(() {});
                                      },
                                    ),
                                    ShopShipCard(
                                      imagePath: 'assets/images/ship4.png',
                                      name: 'NAVE OURO',
                                      price: MyGame.ship4Price,
                                      owned: game.ownsShip4,
                                      canBuy: game.canBuyShip4,
                                      onBuy: () {
                                        game.buyShip4();
                                        setState(() {});
                                      },
                                    ),
                                    ShopShipCard(
                                      imagePath: 'assets/images/ship5.png',
                                      name: 'NAVE VIOLETA',
                                      price: MyGame.ship5Price,
                                      owned: game.ownsShip5,
                                      canBuy: game.canBuyShip5,
                                      onBuy: () {
                                        game.buyShip5();
                                        setState(() {});
                                      },
                                    ),
                                    ShopShipCard(
                                      imagePath: 'assets/images/ship6.png',
                                      name: 'NAVE NEBULA',
                                      price: MyGame.ship6Price,
                                      owned: game.ownsShip6,
                                      canBuy: game.canBuyShip6,
                                      onBuy: () {
                                        game.buyShip6();
                                        setState(() {});
                                      },
                                    ),
                                    ShopShipCard(
                                      imagePath: 'assets/images/ship7.png',
                                      name: 'NAVE SOLAR',
                                      price: MyGame.ship7Price,
                                      owned: game.ownsShip7,
                                      canBuy: game.canBuyShip7,
                                      onBuy: () {
                                        game.buyShip7();
                                        setState(() {});
                                      },
                                    ),
                                    ShopShipCard(
                                      imagePath: 'assets/images/ship8.png',
                                      name: 'NAVE COSMICA',
                                      price: MyGame.ship8Price,
                                      owned: game.ownsShip8,
                                      canBuy: game.canBuyShip8,
                                      onBuy: () {
                                        game.buyShip8();
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                        FixedBackArrow(
                          onPressed: () {
                            game.overlays.remove('ShopMenu');
                            game.overlays.add('StartMenu');
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              'InventoryMenu': (BuildContext context, MyGame game) {
                return StatefulBuilder(
                  builder: (context, setState) {
                    return InventoryMenuView(
                      game: game,
                      onChanged: () => setState(() {}),
                      onBack: () {
                        game.overlays.remove('InventoryMenu');
                        game.overlays.add('StartMenu');
                      },
                    );
                  },
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
                          shadows: [
                            Shadow(blurRadius: 10, color: Colors.black),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          game.overlays.remove('GameOver');
                          game.restart();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text(
                          'Restart',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          game.backToMenu();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text(
                          'MENU',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              'BossUpgrade': (BuildContext context, MyGame game) {
                return BossUpgradeView(game: game);
              },
              'PauseButton': (BuildContext context, MyGame game) {
                return GameplayHudView(
                  game: game,
                  onPause: () {
                    if (!game.isGameOver) {
                      game.pauseEngine();
                      game.overlays.remove('PauseButton');
                      game.overlays.add('PauseMenu');
                    }
                  },
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
                          shadows: [
                            Shadow(blurRadius: 10, color: Colors.black),
                          ],
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text(
                          'RESUME',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          game.overlays.remove('PauseMenu');
                          game.overlays.add('ConfirmBackToMenu');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text(
                          'MENU',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              'ConfirmBackToMenu': (BuildContext context, MyGame game) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'VOLTAR AO MENU?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(blurRadius: 10, color: Colors.black),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Voce vai perder o progresso da partida atual.',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () {
                          game.backToMenu();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text(
                          'CONFIRMAR',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          game.overlays.remove('ConfirmBackToMenu');
                          game.overlays.add('PauseMenu');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text(
                          'CANCELAR',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

class CoinCounter extends StatelessWidget {
  final int value;
  final double fontSize;

  const CoinCounter({super.key, required this.value, this.fontSize = 24});

  @override
  Widget build(BuildContext context) {
    final coinSize = fontSize + 10;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: coinSize,
          height: coinSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.amber,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 8,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Text(
            'C',
            style: TextStyle(
              color: Colors.black,
              fontSize: fontSize * 0.7,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$value',
          style: TextStyle(
            color: Colors.amber,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
          ),
        ),
      ],
    );
  }
}

class BossUpgradeView extends StatelessWidget {
  final MyGame game;

  const BossUpgradeView({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final center = game.upgradeSelectionPosition;
    final left = (center.x - 92).clamp(8.0, screenSize.width - 200);
    final top = center.y.clamp(80.0, screenSize.height - 88);

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xD0071B38),
                border: Border.all(color: Colors.white70, width: 1.5),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black87,
                    blurRadius: 10,
                    offset: Offset(2, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: game.currentUpgradeOptions
                    .map(
                      (upgrade) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: BossUpgradeIcon(
                          upgrade: upgrade,
                          onPressed: () => game.applyBossUpgrade(upgrade),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class BossUpgradeIcon extends StatelessWidget {
  final ShipUpgradeType upgrade;
  final VoidCallback onPressed;

  const BossUpgradeIcon({
    super.key,
    required this.upgrade,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${upgrade.title}\n${upgrade.description}',
      child: SizedBox(
        width: 84,
        height: 64,
        child: IconButton(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0x99020712),
            fixedSize: const Size(84, 64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: upgrade.color, width: 2),
            ),
          ),
          icon: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(upgrade.icon, color: upgrade.color, size: 24),
              const SizedBox(height: 3),
              Text(
                upgrade.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameplayHudView extends StatefulWidget {
  final MyGame game;
  final VoidCallback onPause;

  const GameplayHudView({super.key, required this.game, required this.onPause});

  @override
  State<GameplayHudView> createState() => _GameplayHudViewState();
}

class _GameplayHudViewState extends State<GameplayHudView> {
  async.Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    widget.game.onShieldStateChanged = _refresh;
    _refreshTimer = async.Timer.periodic(const Duration(milliseconds: 250), (
      _,
    ) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    if (widget.game.onShieldStateChanged == _refresh) {
      widget.game.onShieldStateChanged = null;
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final hasStoredShield = game.storedShields > 0;
    final isShieldActive = game.player.shieldTimer > 0;
    final canUseShield = hasStoredShield && !isShieldActive && !game.isGameOver;
    final hasStoredRapidFire = game.storedRapidFires > 0;
    final isRapidFireActive = game.player.rapidFireTimer > 0;
    final canUseRapidFire =
        hasStoredRapidFire && !isRapidFireActive && !game.isGameOver;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final actionButtonsTop = (screenHeight * 0.42).clamp(
      220.0,
      screenHeight - 170.0,
    );

    return Stack(
      children: [
        Positioned(
          top: 60,
          right: 10,
          child: IconButton(
            icon: const Icon(Icons.pause, color: Colors.white, size: 36),
            onPressed: widget.onPause,
          ),
        ),
        Positioned(
          top: actionButtonsTop,
          right: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'Usar escudo',
                      onPressed: canUseShield
                          ? () {
                              game.useStoredShield();
                              setState(() {});
                            }
                          : null,
                      icon: Icon(
                        Icons.shield,
                        color: isShieldActive
                            ? Colors.cyanAccent
                            : hasStoredShield
                            ? Colors.white
                            : Colors.white38,
                        size: 26,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0x99020712),
                        disabledBackgroundColor: const Color(0x66020712),
                        fixedSize: const Size(42, 42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isShieldActive
                                ? Colors.cyanAccent
                                : const Color(0xFF5EDCFF),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        height: 22,
                        constraints: const BoxConstraints(minWidth: 18),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: hasStoredShield
                              ? Colors.cyanAccent
                              : const Color(0xFF777777),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          '${game.storedShields}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    if (isShieldActive)
                      Positioned(
                        left: -5,
                        right: -5,
                        bottom: -18,
                        child: Text(
                          '${game.player.shieldTimer.ceil()}s',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 6, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Material(
                color: Colors.transparent,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'Usar tiro rapido',
                      onPressed: canUseRapidFire
                          ? () {
                              game.useStoredRapidFire();
                              setState(() {});
                            }
                          : null,
                      icon: Icon(
                        Icons.flash_on,
                        color: isRapidFireActive
                            ? Colors.amberAccent
                            : hasStoredRapidFire
                            ? Colors.white
                            : Colors.white38,
                        size: 26,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0x99020712),
                        disabledBackgroundColor: const Color(0x66020712),
                        fixedSize: const Size(42, 42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isRapidFireActive
                                ? Colors.amberAccent
                                : const Color(0xFFFFD54F),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        height: 22,
                        constraints: const BoxConstraints(minWidth: 18),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: hasStoredRapidFire
                              ? Colors.amberAccent
                              : const Color(0xFF777777),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          '${game.storedRapidFires}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    if (isRapidFireActive)
                      Positioned(
                        left: -5,
                        right: -5,
                        bottom: -18,
                        child: Text(
                          '${game.player.rapidFireTimer.ceil()}s',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 6, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (game.controlMode == ControlMode.joystick) ...[
          Positioned(left: 42, bottom: 58, child: MovementJoystick(game: game)),
          Positioned(right: 22, bottom: 58, child: FireButton(game: game)),
        ],
      ],
    );
  }
}

class MovementJoystick extends StatefulWidget {
  final MyGame game;

  const MovementJoystick({super.key, required this.game});

  @override
  State<MovementJoystick> createState() => _MovementJoystickState();
}

class _MovementJoystickState extends State<MovementJoystick> {
  static const double baseSize = 92;
  static const double knobSize = 36;
  Offset knobOffset = Offset.zero;

  void _update(Offset localPosition) {
    final center = const Offset(baseSize / 2, baseSize / 2);
    final raw = localPosition - center;
    final maxDistance = (baseSize - knobSize) / 2;
    final distance = raw.distance;
    final clamped = distance > maxDistance
        ? Offset.fromDirection(raw.direction, maxDistance)
        : raw;

    setState(() {
      knobOffset = clamped;
    });

    final normalized = clamped / maxDistance;
    widget.game.player.hudMoveDirection = Vector2(normalized.dx, normalized.dy);
  }

  void _reset() {
    setState(() {
      knobOffset = Offset.zero;
    });
    widget.game.player.hudMoveDirection = Vector2.zero();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => _update(details.localPosition),
      onPanUpdate: (details) => _update(details.localPosition),
      onPanEnd: (_) => _reset(),
      onPanCancel: _reset,
      child: Container(
        width: baseSize,
        height: baseSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x66020712),
          border: Border.all(color: Colors.cyanAccent, width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: knobOffset,
              child: Container(
                width: knobSize,
                height: knobSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(210),
                  border: Border.all(color: Colors.cyanAccent, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FireButton extends StatelessWidget {
  final MyGame game;

  const FireButton({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => game.player.startHudFiring(),
      onTapUp: (_) => game.player.stopHudFiring(),
      onTapCancel: game.player.stopHudFiring,
      child: Container(
        width: 76,
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x99020712),
          border: Border.all(color: Colors.redAccent, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 10)],
        ),
        child: const Icon(
          Icons.local_fire_department,
          color: Colors.redAccent,
          size: 38,
        ),
      ),
    );
  }
}

class MainMenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onPressed;

  const MainMenuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = primary
        ? const Color(0xFFFF4FBF)
        : const Color(0xFF5EDCFF);
    final backgroundColor = primary
        ? const Color(0xCC5A063C)
        : const Color(0xCC061B36);
    final iconColor = primary ? Colors.white : const Color(0xFF78E6FF);
    final glowColor = primary
        ? const Color(0xA6FF4FBF)
        : const Color(0xA65EDCFF);
    final buttonWidth = min(320.0, MediaQuery.sizeOf(context).width - 32);

    return Container(
      width: buttonWidth,
      height: primary ? 66 : 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: glowColor, blurRadius: 14, spreadRadius: 1),
          const BoxShadow(
            color: Colors.black87,
            blurRadius: 10,
            offset: Offset(3, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: borderColor, width: 3),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: primary ? 36 : 30),
            const SizedBox(width: 12),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: primary ? 30 : 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FixedBackArrow extends StatelessWidget {
  final VoidCallback onPressed;

  const FixedBackArrow({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      top: 12,
      child: Material(
        color: Colors.transparent,
        child: IconButton(
          onPressed: onPressed,
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          iconSize: 34,
          tooltip: 'Voltar',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0x99020712),
            foregroundColor: Colors.white,
            fixedSize: const Size(54, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.cyan, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsMenuView extends StatefulWidget {
  final MyGame game;
  final VoidCallback onBack;

  const SettingsMenuView({super.key, required this.game, required this.onBack});

  @override
  State<SettingsMenuView> createState() => _SettingsMenuViewState();
}

class _SettingsMenuViewState extends State<SettingsMenuView> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/fundomenu.png', fit: BoxFit.cover),
        ),
        Positioned.fill(child: Container(color: const Color(0xAA000000))),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CONFIGURACOES',
                style: TextStyle(
                  color: Colors.cyan,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
              const SizedBox(height: 34),
              const Text(
                'CONTROLE',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: ControlMode.values
                    .map(
                      (mode) => ControlModeButton(
                        mode: mode,
                        selected: widget.game.controlMode == mode,
                        onPressed: () {
                          widget.game.setControlMode(mode);
                          setState(() {});
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        FixedBackArrow(onPressed: widget.onBack),
      ],
    );
  }
}

class ControlModeButton extends StatelessWidget {
  final ControlMode mode;
  final bool selected;
  final VoidCallback onPressed;

  const ControlModeButton({
    super.key,
    required this.mode,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 112,
      child: ElevatedButton(
        onPressed: selected ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(12),
          backgroundColor: selected ? Colors.amber : const Color(0xEE071B38),
          foregroundColor: selected ? Colors.black : Colors.white,
          disabledBackgroundColor: Colors.amber,
          disabledForegroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: selected ? Colors.white : Colors.cyan,
              width: 2,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mode == ControlMode.drag ? Icons.swipe : Icons.gamepad,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              mode.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              mode.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class FreeCoinsMenuView extends StatefulWidget {
  final MyGame game;
  final VoidCallback onBack;

  const FreeCoinsMenuView({
    super.key,
    required this.game,
    required this.onBack,
  });

  @override
  State<FreeCoinsMenuView> createState() => _FreeCoinsMenuViewState();
}

class _FreeCoinsMenuViewState extends State<FreeCoinsMenuView> {
  async.Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    widget.game.onFreeCoinsAdStateChanged = _refresh;
    widget.game.loadFreeCoinsRewardedAd();
    _refreshTimer = async.Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      widget.game.loadFreeCoinsRewardedAd();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    if (widget.game.onFreeCoinsAdStateChanged == _refresh) {
      widget.game.onFreeCoinsAdStateChanged = null;
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final canWatchAd = game.canWatchFreeCoinsAd;
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'COINS GRATIS',
                style: TextStyle(
                  color: Colors.cyan,
                  fontSize: 54,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
              const SizedBox(height: 20),
              CoinCounter(value: game.coins, fontSize: 28),
              const SizedBox(height: 30),
              Text(
                game.freeCoinsAdMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: canWatchAd
                    ? () => game.showFreeCoinsRewardedAd()
                    : null,
                icon: const Icon(Icons.smart_display),
                label: Text(
                  canWatchAd
                      ? 'ASSISTIR +${MyGame.freeCoinsRewardAmount} C'
                      : game.freeCoinsAdButtonText,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 15,
                  ),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: const Color(0xFF777777),
                  disabledForegroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        FixedBackArrow(onPressed: widget.onBack),
      ],
    );
  }
}

class MissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String progressText;
  final Color color;
  final String? actionText;
  final VoidCallback? onAction;

  const MissionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.progressText,
    required this.color,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xCC071B38),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 12,
            offset: Offset(3, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 8, color: Colors.black)],
              ),
            ),
          ),
          Text(
            progressText,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
            ),
          ),
          if (actionText != null) ...[
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: Text(
                actionText!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ShopShipCard extends StatelessWidget {
  final String imagePath;
  final String name;
  final int price;
  final bool owned;
  final bool canBuy;
  final VoidCallback onBuy;

  const ShopShipCard({
    super.key,
    required this.imagePath,
    required this.name,
    required this.price,
    required this.owned,
    required this.canBuy,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: 220,
      decoration: BoxDecoration(
        color: owned ? const Color(0xAA2A2100) : Colors.black54,
        border: Border.all(
          color: owned ? Colors.amber : Colors.cyan,
          width: owned ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (owned) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: const Text(
                'JA COMPRADA',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Image.asset(imagePath, width: 90, height: 90, fit: BoxFit.contain),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 8, color: Colors.black)],
            ),
          ),
          const SizedBox(height: 10),
          owned
              ? const Text(
                  'Disponivel no inventario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                )
              : CoinCounter(value: price, fontSize: 20),
          const SizedBox(height: 15),
          if (owned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'COMPRADA',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: canBuy ? onBuy : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'COMPRAR',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

class InventoryMenuView extends StatelessWidget {
  final MyGame game;
  final VoidCallback onChanged;
  final VoidCallback onBack;

  const InventoryMenuView({
    super.key,
    required this.game,
    required this.onChanged,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Container(color: const Color(0xCC020712))),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Center(
            child: Column(
              children: [
                const Text(
                  'INVENTARIO',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(blurRadius: 12, color: Colors.black),
                      Shadow(blurRadius: 18, color: Colors.cyan),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 320,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xCC071B38),
                    border: Border.all(color: Colors.amber, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black87,
                        blurRadius: 14,
                        offset: Offset(3, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'NAVE EQUIPADA',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Image.asset(
                        'assets/images/${game.selectedShipAsset}',
                        width: 110,
                        height: 110,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  alignment: WrapAlignment.center,
                  children: [
                    InventoryShipCard(
                      imagePath: 'assets/images/ship.png',
                      assetName: 'ship.png',
                      name: 'NAVE PADRAO',
                      unlocked: true,
                      selected: game.selectedShipAsset == 'ship.png',
                      onSelect: () async {
                        await game.selectShip('ship.png');
                        onChanged();
                      },
                    ),
                    InventoryShipCard(
                      imagePath: 'assets/images/ship1.png',
                      assetName: 'ship1.png',
                      name: 'NAVE CIANO',
                      unlocked: game.ownsShip1,
                      selected: game.selectedShipAsset == 'ship1.png',
                      onSelect: () async {
                        await game.selectShip('ship1.png');
                        onChanged();
                      },
                    ),
                    InventoryShipCard(
                      imagePath: 'assets/images/ship3.png',
                      assetName: 'ship3.png',
                      name: 'NAVE RUBI',
                      unlocked: game.ownsShip3,
                      selected: game.selectedShipAsset == 'ship3.png',
                      onSelect: () async {
                        await game.selectShip('ship3.png');
                        onChanged();
                      },
                    ),
                    InventoryShipCard(
                      imagePath: 'assets/images/ship4.png',
                      assetName: 'ship4.png',
                      name: 'NAVE OURO',
                      unlocked: game.ownsShip4,
                      selected: game.selectedShipAsset == 'ship4.png',
                      onSelect: () async {
                        await game.selectShip('ship4.png');
                        onChanged();
                      },
                    ),
                    InventoryShipCard(
                      imagePath: 'assets/images/ship5.png',
                      assetName: 'ship5.png',
                      name: 'NAVE VIOLETA',
                      unlocked: game.ownsShip5,
                      selected: game.selectedShipAsset == 'ship5.png',
                      onSelect: () async {
                        await game.selectShip('ship5.png');
                        onChanged();
                      },
                    ),
                    InventoryShipCard(
                      imagePath: 'assets/images/ship6.png',
                      assetName: 'ship6.png',
                      name: 'NAVE NEBULA',
                      unlocked: game.ownsShip6,
                      selected: game.selectedShipAsset == 'ship6.png',
                      onSelect: () async {
                        await game.selectShip('ship6.png');
                        onChanged();
                      },
                    ),
                    InventoryShipCard(
                      imagePath: 'assets/images/ship7.png',
                      assetName: 'ship7.png',
                      name: 'NAVE SOLAR',
                      unlocked: game.ownsShip7,
                      selected: game.selectedShipAsset == 'ship7.png',
                      onSelect: () async {
                        await game.selectShip('ship7.png');
                        onChanged();
                      },
                    ),
                    InventoryShipCard(
                      imagePath: 'assets/images/ship8.png',
                      assetName: 'ship8.png',
                      name: 'NAVE COSMICA',
                      unlocked: game.ownsShip8,
                      selected: game.selectedShipAsset == 'ship8.png',
                      onSelect: () async {
                        await game.selectShip('ship8.png');
                        onChanged();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
        FixedBackArrow(onPressed: onBack),
      ],
    );
  }
}

class InventoryShipCard extends StatelessWidget {
  final String imagePath;
  final String assetName;
  final String name;
  final bool unlocked;
  final bool selected;
  final Future<void> Function() onSelect;

  const InventoryShipCard({
    super.key,
    required this.imagePath,
    required this.assetName,
    required this.name,
    required this.unlocked,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Colors.amber
        : unlocked
        ? Colors.cyan
        : Colors.white24;
    final backgroundColor = selected
        ? const Color(0xAA2A2100)
        : unlocked
        ? const Color(0xCC071B38)
        : const Color(0xAA05070D);

    return Container(
      padding: const EdgeInsets.all(16),
      width: 220,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: selected ? 3 : 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          if (selected)
            const BoxShadow(
              color: Color(0x99FFC107),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          const BoxShadow(
            color: Colors.black87,
            blurRadius: 12,
            offset: Offset(3, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.amber
                    : unlocked
                    ? Colors.cyan
                    : Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                selected
                    ? 'EQUIPADA'
                    : unlocked
                    ? 'LIBERADA'
                    : 'LOCK',
                style: TextStyle(
                  color: selected || unlocked ? Colors.black : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: unlocked ? 1 : 0.35,
            child: Image.asset(
              imagePath,
              width: 104,
              height: 104,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 8, color: Colors.black)],
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: unlocked && !selected ? onSelect : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: selected ? Colors.amber : Colors.white,
              foregroundColor: Colors.black,
            ),
            child: Text(
              selected
                  ? 'USANDO'
                  : unlocked
                  ? 'EQUIPAR'
                  : 'BLOQUEADA',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class MyGame extends FlameGame
    with KeyboardEvents, PanDetector, TapDetector, HasCollisionDetection {
  static const int freeCoinsRewardAmount = 100;
  static const int freeCoinsCooldownMs = 5 * 60 * 1000;
  static const int freeCoinsDailyAdLimit = 20;
  static const int destroyEnemiesMissionTarget = 100;
  static const int destroyEnemiesMissionReward = 150;
  static const int destroyEnemiesMissionCooldownMs = 60 * 60 * 1000;
  static const int reachLevelMissionTarget = 20;
  static const int reachLevelMissionReward = 200;
  static const int reachLevelMissionCooldownMs = 60 * 60 * 1000;
  static const int beatHighScoreMissionReward = 400;
  static const int beatHighScoreMissionCooldownMs = 24 * 60 * 60 * 1000;

  static const int ship1Price = 300;
  static const int ship3Price = 500;
  static const int ship4Price = 800;
  static const int ship5Price = 1000;
  static const int ship6Price = 1500;
  static const int ship7Price = 4000;
  static const int ship8Price = 10000;

  late Player player;
  final List<Enemy> enemies = [];
  late TextComponent livesText;
  late TextComponent matchCoinsText;
  late TextComponent scoreText;
  late TextComponent levelText;
  late TextComponent highScoreText;
  late SharedPreferences prefs;
  late EdgeInsets padding;
  bool isGameOver = false;
  int score = 0;
  int coins = 0;
  int matchCoins = 0;
  int storedShields = 0;
  int storedRapidFires = 0;
  List<ShipUpgradeType> currentUpgradeOptions = [];
  Vector2 upgradeSelectionPosition = Vector2.zero();
  int destroyEnemiesMissionProgress = 0;
  int destroyEnemiesMissionClaimedAt = 0;
  int reachLevelMissionProgress = 1;
  int reachLevelMissionClaimedAt = 0;
  bool beatHighScoreMissionReady = false;
  int beatHighScoreMissionClaimedAt = 0;
  int highScore = 0;
  int currentLevel = 1;
  bool matchCoinsSaved = false;
  bool ownsShip1 = false;
  bool ownsShip3 = false;
  bool ownsShip4 = false;
  bool ownsShip5 = false;
  bool ownsShip6 = false;
  bool ownsShip7 = false;
  bool ownsShip8 = false;
  String selectedShipAsset = 'ship.png';
  ControlMode controlMode = ControlMode.drag;
  RewardedAd? _freeCoinsRewardedAd;
  bool _isFreeCoinsAdLoading = false;
  bool _isFreeCoinsAdShowing = false;
  int freeCoinsLastWatchedAt = 0;
  int freeCoinsAdsWatchedToday = 0;
  String freeCoinsAdsWatchedDay = '';
  String _freeCoinsAdStatusMessage = isMobileAdsSupported
      ? 'Carregando anuncio...'
      : 'Anuncios disponiveis apenas no Android/iOS.';
  VoidCallback? onFreeCoinsAdStateChanged;
  VoidCallback? onShieldStateChanged;

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
    coins = prefs.getInt('coins') ?? 0;
    destroyEnemiesMissionProgress =
        prefs.getInt('destroyEnemiesMissionProgress') ?? 0;
    destroyEnemiesMissionClaimedAt =
        prefs.getInt('destroyEnemiesMissionClaimedAt') ?? 0;
    reachLevelMissionProgress = prefs.getInt('reachLevelMissionProgress') ?? 1;
    reachLevelMissionClaimedAt =
        prefs.getInt('reachLevelMissionClaimedAt') ?? 0;
    beatHighScoreMissionReady =
        prefs.getBool('beatHighScoreMissionReady') ?? false;
    beatHighScoreMissionClaimedAt =
        prefs.getInt('beatHighScoreMissionClaimedAt') ?? 0;
    freeCoinsLastWatchedAt = prefs.getInt('freeCoinsLastWatchedAt') ?? 0;
    freeCoinsAdsWatchedToday = prefs.getInt('freeCoinsAdsWatchedToday') ?? 0;
    freeCoinsAdsWatchedDay = prefs.getString('freeCoinsAdsWatchedDay') ?? '';
    refreshFreeCoinsDailyLimit();
    ownsShip1 = prefs.getBool('ownsShip1') ?? false;
    ownsShip3 = prefs.getBool('ownsShip3') ?? false;
    ownsShip4 = prefs.getBool('ownsShip4') ?? false;
    ownsShip5 = prefs.getBool('ownsShip5') ?? false;
    ownsShip6 = prefs.getBool('ownsShip6') ?? false;
    ownsShip7 = prefs.getBool('ownsShip7') ?? false;
    ownsShip8 = prefs.getBool('ownsShip8') ?? false;
    selectedShipAsset = prefs.getString('selectedShipAsset') ?? 'ship.png';
    controlMode = ControlModeDetails.fromStorage(
      prefs.getString('controlMode'),
    );
    if (!isShipUnlocked(selectedShipAsset)) {
      selectedShipAsset = 'ship.png';
      prefs.setString('selectedShipAsset', selectedShipAsset);
    }

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
    player.shipAsset = selectedShipAsset;
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

    matchCoinsText = TextComponent(
      text: 'C $matchCoins',
      position: Vector2(15, 45),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(blurRadius: 4.0, color: Colors.black, offset: Offset(2, 2)),
          ],
        ),
      ),
    );
    add(matchCoinsText);

    scoreText = TextComponent(
      text: 'SCORE: $score',
      position: Vector2(15, 75),
      textRenderer: textStyle,
    );
    add(scoreText);

    highScoreText = TextComponent(
      text: 'HI-SCORE: $highScore',
      position: Vector2(size.x / 2, 15),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(blurRadius: 4.0, color: Colors.black, offset: Offset(2, 2)),
          ],
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
    loadFreeCoinsRewardedAd();

    // Pause the engine initially so the Start Menu handles resuming
    pauseEngine();
  }

  @override
  void onRemove() {
    _freeCoinsRewardedAd?.dispose();
    _freeCoinsRewardedAd = null;
    super.onRemove();
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
    if (controlMode != ControlMode.drag) return;
    player.position += info.delta.global;
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (controlMode != ControlMode.drag) return;
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
      registerHighScoreBeatenForMission();
    }
  }

  void updateCoins() {
    prefs.setInt('coins', coins);
  }

  String get _todayKey {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  void refreshFreeCoinsDailyLimit() {
    final today = _todayKey;
    if (freeCoinsAdsWatchedDay == today) return;

    freeCoinsAdsWatchedDay = today;
    freeCoinsAdsWatchedToday = 0;
    prefs.setString('freeCoinsAdsWatchedDay', freeCoinsAdsWatchedDay);
    prefs.setInt('freeCoinsAdsWatchedToday', freeCoinsAdsWatchedToday);
  }

  bool get hasFreeCoinsDailyAdsLeft {
    refreshFreeCoinsDailyLimit();
    return freeCoinsAdsWatchedToday < freeCoinsDailyAdLimit;
  }

  bool get isFreeCoinsAdCoolingDown {
    if (freeCoinsLastWatchedAt <= 0) return false;
    return _nowMs - freeCoinsLastWatchedAt < freeCoinsCooldownMs;
  }

  int get freeCoinsCooldownRemainingSeconds {
    if (!isFreeCoinsAdCoolingDown) return 0;
    final remainingMs = freeCoinsCooldownMs - (_nowMs - freeCoinsLastWatchedAt);
    return (remainingMs / 1000).ceil();
  }

  String get _freeCoinsCooldownText {
    final seconds = freeCoinsCooldownRemainingSeconds;
    final minutes = (seconds / 60).ceil();
    if (minutes > 1) return '${minutes}m';
    return '${seconds}s';
  }

  bool get canWatchFreeCoinsAd =>
      isMobileAdsSupported &&
      hasFreeCoinsDailyAdsLeft &&
      !isFreeCoinsAdCoolingDown &&
      _freeCoinsRewardedAd != null &&
      !_isFreeCoinsAdShowing;

  String get freeCoinsAdMessage {
    if (!isMobileAdsSupported) {
      return 'Anuncios disponiveis apenas no Android/iOS.';
    }
    if (!hasFreeCoinsDailyAdsLeft) {
      return 'Limite diario atingido. Volte amanha.';
    }
    if (isFreeCoinsAdCoolingDown) {
      return 'Aguarde $_freeCoinsCooldownText para assistir outro anuncio.';
    }
    if (_isFreeCoinsAdShowing) return 'Abrindo anuncio...';
    if (_isFreeCoinsAdLoading) return 'Carregando anuncio...';
    return _freeCoinsAdStatusMessage;
  }

  String get freeCoinsAdButtonText {
    if (!isMobileAdsSupported) return 'INDISPONIVEL';
    if (!hasFreeCoinsDailyAdsLeft) return 'LIMITE DIARIO';
    if (isFreeCoinsAdCoolingDown) return 'AGUARDE $_freeCoinsCooldownText';
    if (_isFreeCoinsAdShowing) return 'ABRINDO...';
    if (_isFreeCoinsAdLoading) return 'CARREGANDO...';
    return 'TENTAR NOVAMENTE';
  }

  void _notifyFreeCoinsAdStateChanged() {
    onFreeCoinsAdStateChanged?.call();
  }

  void loadFreeCoinsRewardedAd() {
    if (!isMobileAdsSupported ||
        !hasFreeCoinsDailyAdsLeft ||
        isFreeCoinsAdCoolingDown ||
        _isFreeCoinsAdLoading ||
        _freeCoinsRewardedAd != null) {
      return;
    }

    _isFreeCoinsAdLoading = true;
    _freeCoinsAdStatusMessage = 'Carregando anuncio...';
    _notifyFreeCoinsAdStateChanged();

    RewardedAd.load(
      adUnitId: freeCoinsRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _freeCoinsRewardedAd = ad;
          _isFreeCoinsAdLoading = false;
          _freeCoinsAdStatusMessage =
              'Assista um anuncio para ganhar $freeCoinsRewardAmount coins.';
          _notifyFreeCoinsAdStateChanged();
        },
        onAdFailedToLoad: (error) {
          _freeCoinsRewardedAd = null;
          _isFreeCoinsAdLoading = false;
          _freeCoinsAdStatusMessage =
              'Nao foi possivel carregar o anuncio. Tente novamente.';
          _notifyFreeCoinsAdStateChanged();
        },
      ),
    );
  }

  Future<void> showFreeCoinsRewardedAd() async {
    if (!hasFreeCoinsDailyAdsLeft || isFreeCoinsAdCoolingDown) {
      _notifyFreeCoinsAdStateChanged();
      return;
    }

    final ad = _freeCoinsRewardedAd;
    if (ad == null || _isFreeCoinsAdShowing) {
      loadFreeCoinsRewardedAd();
      return;
    }

    _freeCoinsRewardedAd = null;
    _isFreeCoinsAdShowing = true;
    _freeCoinsAdStatusMessage = 'Abrindo anuncio...';
    _notifyFreeCoinsAdStateChanged();

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isFreeCoinsAdShowing = false;
        loadFreeCoinsRewardedAd();
        _notifyFreeCoinsAdStateChanged();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isFreeCoinsAdShowing = false;
        _freeCoinsAdStatusMessage =
            'Nao foi possivel abrir o anuncio. Tente novamente.';
        loadFreeCoinsRewardedAd();
        _notifyFreeCoinsAdStateChanged();
      },
    );

    await ad.show(
      onUserEarnedReward: (ad, reward) {
        coins += freeCoinsRewardAmount;
        freeCoinsLastWatchedAt = _nowMs;
        freeCoinsAdsWatchedToday++;
        updateCoins();
        prefs.setInt('freeCoinsLastWatchedAt', freeCoinsLastWatchedAt);
        prefs.setInt('freeCoinsAdsWatchedToday', freeCoinsAdsWatchedToday);
        prefs.setString('freeCoinsAdsWatchedDay', freeCoinsAdsWatchedDay);
        _freeCoinsAdStatusMessage = 'Voce ganhou $freeCoinsRewardAmount coins!';
        _notifyFreeCoinsAdStateChanged();
      },
    );
  }

  int get _nowMs => DateTime.now().millisecondsSinceEpoch;

  bool get isDestroyEnemiesMissionCoolingDown {
    if (destroyEnemiesMissionClaimedAt <= 0) return false;
    return _nowMs - destroyEnemiesMissionClaimedAt <
        destroyEnemiesMissionCooldownMs;
  }

  bool get canClaimDestroyEnemiesMission =>
      !isDestroyEnemiesMissionCoolingDown &&
      destroyEnemiesMissionProgress >= destroyEnemiesMissionTarget;

  String get destroyEnemiesMissionText {
    if (isDestroyEnemiesMissionCoolingDown) {
      final remainingMs =
          destroyEnemiesMissionCooldownMs -
          (_nowMs - destroyEnemiesMissionClaimedAt);
      final remainingMinutes = (remainingMs / 60000).ceil();
      return 'AGUARDE ${remainingMinutes}m';
    }

    final progress = min(
      destroyEnemiesMissionProgress,
      destroyEnemiesMissionTarget,
    );
    return '$progress/$destroyEnemiesMissionTarget';
  }

  void registerEnemyDestroyedForMission() {
    if (isDestroyEnemiesMissionCoolingDown ||
        destroyEnemiesMissionProgress >= destroyEnemiesMissionTarget) {
      return;
    }

    destroyEnemiesMissionProgress++;
    prefs.setInt(
      'destroyEnemiesMissionProgress',
      destroyEnemiesMissionProgress,
    );
  }

  void claimDestroyEnemiesMission() {
    if (!canClaimDestroyEnemiesMission) return;

    coins += destroyEnemiesMissionReward;
    destroyEnemiesMissionProgress = 0;
    destroyEnemiesMissionClaimedAt = _nowMs;
    updateCoins();
    prefs.setInt(
      'destroyEnemiesMissionProgress',
      destroyEnemiesMissionProgress,
    );
    prefs.setInt(
      'destroyEnemiesMissionClaimedAt',
      destroyEnemiesMissionClaimedAt,
    );
  }

  bool get canClaimReachLevelMission =>
      !isReachLevelMissionCoolingDown &&
      reachLevelMissionProgress >= reachLevelMissionTarget;

  bool get isReachLevelMissionCoolingDown {
    if (reachLevelMissionClaimedAt <= 0) return false;
    return _nowMs - reachLevelMissionClaimedAt < reachLevelMissionCooldownMs;
  }

  String get reachLevelMissionText {
    if (isReachLevelMissionCoolingDown) {
      final remainingMs =
          reachLevelMissionCooldownMs - (_nowMs - reachLevelMissionClaimedAt);
      final remainingMinutes = (remainingMs / 60000).ceil();
      return 'AGUARDE ${remainingMinutes}m';
    }

    final progress = min(reachLevelMissionProgress, reachLevelMissionTarget);
    return '$progress/$reachLevelMissionTarget';
  }

  void updateReachLevelMissionProgress() {
    if (isReachLevelMissionCoolingDown) return;
    if (currentLevel <= reachLevelMissionProgress) return;

    reachLevelMissionProgress = currentLevel;
    prefs.setInt('reachLevelMissionProgress', reachLevelMissionProgress);
  }

  void claimReachLevelMission() {
    if (!canClaimReachLevelMission) return;

    coins += reachLevelMissionReward;
    reachLevelMissionProgress = 1;
    reachLevelMissionClaimedAt = _nowMs;
    updateCoins();
    prefs.setInt('reachLevelMissionProgress', reachLevelMissionProgress);
    prefs.setInt('reachLevelMissionClaimedAt', reachLevelMissionClaimedAt);
  }

  bool get isBeatHighScoreMissionCoolingDown {
    if (beatHighScoreMissionClaimedAt <= 0) return false;
    return _nowMs - beatHighScoreMissionClaimedAt <
        beatHighScoreMissionCooldownMs;
  }

  bool get canClaimBeatHighScoreMission =>
      !isBeatHighScoreMissionCoolingDown && beatHighScoreMissionReady;

  String get beatHighScoreMissionText {
    if (isBeatHighScoreMissionCoolingDown) {
      final remainingMs =
          beatHighScoreMissionCooldownMs -
          (_nowMs - beatHighScoreMissionClaimedAt);
      final remainingHours = (remainingMs / (60 * 60 * 1000)).ceil();
      return 'AGUARDE ${remainingHours}h';
    }

    return beatHighScoreMissionReady ? '1/1' : '0/1';
  }

  void registerHighScoreBeatenForMission() {
    if (isBeatHighScoreMissionCoolingDown || beatHighScoreMissionReady) {
      return;
    }

    beatHighScoreMissionReady = true;
    prefs.setBool('beatHighScoreMissionReady', beatHighScoreMissionReady);
  }

  void claimBeatHighScoreMission() {
    if (!canClaimBeatHighScoreMission) return;

    coins += beatHighScoreMissionReward;
    beatHighScoreMissionReady = false;
    beatHighScoreMissionClaimedAt = _nowMs;
    updateCoins();
    prefs.setBool('beatHighScoreMissionReady', beatHighScoreMissionReady);
    prefs.setInt(
      'beatHighScoreMissionClaimedAt',
      beatHighScoreMissionClaimedAt,
    );
  }

  bool get canBuyShip1 => !ownsShip1 && coins >= ship1Price;
  bool get canBuyShip3 => !ownsShip3 && coins >= ship3Price;
  bool get canBuyShip4 => !ownsShip4 && coins >= ship4Price;
  bool get canBuyShip5 => !ownsShip5 && coins >= ship5Price;
  bool get canBuyShip6 => !ownsShip6 && coins >= ship6Price;
  bool get canBuyShip7 => !ownsShip7 && coins >= ship7Price;
  bool get canBuyShip8 => !ownsShip8 && coins >= ship8Price;

  bool isShipUnlocked(String assetName) {
    if (assetName == 'ship.png') return true;
    if (assetName == 'ship1.png') return ownsShip1;
    if (assetName == 'ship3.png') return ownsShip3;
    if (assetName == 'ship4.png') return ownsShip4;
    if (assetName == 'ship5.png') return ownsShip5;
    if (assetName == 'ship6.png') return ownsShip6;
    if (assetName == 'ship7.png') return ownsShip7;
    if (assetName == 'ship8.png') return ownsShip8;
    return false;
  }

  Future<void> selectShip(String assetName) async {
    if (!isShipUnlocked(assetName)) return;

    selectedShipAsset = assetName;
    prefs.setString('selectedShipAsset', selectedShipAsset);
    player.shipAsset = selectedShipAsset;
    player.sprite = await Sprite.load(selectedShipAsset);
  }

  void setControlMode(ControlMode mode) {
    controlMode = mode;
    prefs.setString('controlMode', mode.storageValue);
    player.stopHudControls();
  }

  bool buyShip1() {
    if (!canBuyShip1) return false;

    coins -= ship1Price;
    ownsShip1 = true;
    prefs.setInt('coins', coins);
    prefs.setBool('ownsShip1', ownsShip1);
    return true;
  }

  bool buyShip3() {
    if (!canBuyShip3) return false;

    coins -= ship3Price;
    ownsShip3 = true;
    prefs.setInt('coins', coins);
    prefs.setBool('ownsShip3', ownsShip3);
    return true;
  }

  bool buyShip4() {
    if (!canBuyShip4) return false;

    coins -= ship4Price;
    ownsShip4 = true;
    prefs.setInt('coins', coins);
    prefs.setBool('ownsShip4', ownsShip4);
    return true;
  }

  bool buyShip5() {
    if (!canBuyShip5) return false;

    coins -= ship5Price;
    ownsShip5 = true;
    prefs.setInt('coins', coins);
    prefs.setBool('ownsShip5', ownsShip5);
    return true;
  }

  bool buyShip6() {
    if (!canBuyShip6) return false;

    coins -= ship6Price;
    ownsShip6 = true;
    prefs.setInt('coins', coins);
    prefs.setBool('ownsShip6', ownsShip6);
    return true;
  }

  bool buyShip7() {
    if (!canBuyShip7) return false;

    coins -= ship7Price;
    ownsShip7 = true;
    prefs.setInt('coins', coins);
    prefs.setBool('ownsShip7', ownsShip7);
    return true;
  }

  bool buyShip8() {
    if (!canBuyShip8) return false;

    coins -= ship8Price;
    ownsShip8 = true;
    prefs.setInt('coins', coins);
    prefs.setBool('ownsShip8', ownsShip8);
    return true;
  }

  void updateMatchCoins() {
    matchCoinsText.text = 'C $matchCoins';
  }

  void updateLevel() {
    levelText.text = 'LEVEL: $currentLevel';
    updateReachLevelMissionProgress();
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

  void spawnShieldPowerup(Vector2 position) {
    final powerup = ShieldPowerup()
      ..position = Vector2(
        position.x.clamp(0.0, max(0.0, size.x - ShieldPowerup.itemSize)),
        position.y,
      )
      ..gameSize = size;
    add(powerup);
  }

  void collectShieldPowerup() {
    storedShields++;
    onShieldStateChanged?.call();
  }

  void collectWeaponPowerup() {
    storedRapidFires++;
    onShieldStateChanged?.call();
  }

  bool useStoredShield() {
    if (storedShields <= 0 || player.shieldTimer > 0 || isGameOver) {
      return false;
    }

    storedShields--;
    player.activateShield();
    onShieldStateChanged?.call();
    return true;
  }

  bool useStoredRapidFire() {
    if (storedRapidFires <= 0 || player.rapidFireTimer > 0 || isGameOver) {
      return false;
    }

    storedRapidFires--;
    player.activateRapidFire();
    onShieldStateChanged?.call();
    return true;
  }

  void completeLevel({required bool defeatedBoss}) {
    if (defeatedBoss) {
      showBossUpgradeSelection();
      return;
    }

    advanceToNextLevel();
  }

  void advanceToNextLevel() {
    currentLevel++;
    updateLevel();
    spawnLevel();
  }

  void showBossUpgradeSelection() {
    upgradeSelectionPosition = Vector2(size.x / 2, size.y * 0.24);
    currentUpgradeOptions =
        ShipUpgradeType.values
            .where(
              (upgrade) =>
                  upgrade != ShipUpgradeType.doubleShot ||
                  !player.hasDoubleShot,
            )
            .toList()
          ..shuffle(Random());
    currentUpgradeOptions = currentUpgradeOptions.take(2).toList();
    overlays.add('BossUpgrade');
    pauseEngine();
  }

  void applyBossUpgrade(ShipUpgradeType upgrade) {
    player.applyUpgrade(upgrade);
    overlays.remove('BossUpgrade');
    advanceToNextLevel();
    resumeEngine();
  }

  int enemyHealthForLevel(int level) {
    if (level <= 10) {
      return max(1, (level / 2).ceil());
    }

    return 5 + ((level - 10) / 4).ceil();
  }

  void spawnLevel() {
    enemies.clear();

    if (currentLevel >= 10 && currentLevel <= 100 && currentLevel % 10 == 0) {
      final boss = Enemy();
      boss.gameSize = size;
      boss.player = player;
      boss.level = currentLevel;
      boss.bossLevel = currentLevel ~/ 10;
      boss.maxHealth = boss.bossMaxHealth;
      boss.health = boss.maxHealth;
      boss.targetY = size.y * 0.12;
      boss.position = Vector2(size.x / 2 - Enemy.bossSize / 2, -Enemy.bossSize);
      enemies.add(boss);
      add(boss);
      return;
    }

    // Até o level 9 vai aumentando as naves, a partir do 10 estabiliza em 5 naves
    int numEnemies = currentLevel < 10 ? currentLevel + 1 : 5;

    for (int i = 0; i < numEnemies; i++) {
      final enemy = Enemy();
      enemy.gameSize = size;
      enemy.player = player;
      enemy.level = currentLevel;
      enemy.maxHealth = enemyHealthForLevel(currentLevel);
      enemy.health = enemy.maxHealth;
      enemy.targetY = size.y * 0.2;
      enemy.position = Vector2(
        (size.x / (numEnemies + 1)) * (i + 1),
        -Enemy.enemySize - (i * 18),
      );
      enemies.add(enemy);
      add(enemy);
    }
  }

  void gameOver() {
    if (isGameOver) return;
    isGameOver = true;
    saveMatchCoins();
    overlays.remove('PauseButton');
    overlays.add('GameOver');
    pauseEngine();
  }

  void saveMatchCoins() {
    if (matchCoinsSaved) return;
    coins += matchCoins;
    matchCoins = 0;
    matchCoinsSaved = true;
    updateCoins();
    updateMatchCoins();
  }

  void clearActiveRunComponents() {
    removeWhere(
      (component) =>
          component is Enemy ||
          component is Bullet ||
          component is PlayerBullet ||
          component is Explosion ||
          component is HeartPowerup ||
          component is WeaponPowerup ||
          component is ShieldPowerup,
    );
    processLifecycleEvents();
    enemies.clear();
  }

  void restart() {
    isGameOver = false;
    score = 0;
    matchCoins = 0;
    matchCoinsSaved = false;
    storedShields = 0;
    storedRapidFires = 0;
    currentUpgradeOptions = [];
    upgradeSelectionPosition = Vector2.zero();
    currentLevel = 1;
    player.lives = 3;
    player.hitCount = 0;
    player.resetPowerups();
    updateScore();
    updateMatchCoins();
    updateLevel();
    updateLives();
    onShieldStateChanged?.call();

    player.position = Vector2(
      size.x / 2 - Player.playerSize / 2,
      size.y - Player.playerSize - 20,
    );

    clearActiveRunComponents();
    spawnLevel();
    overlays.remove('BossUpgrade');
    overlays.add('PauseButton');
    resumeEngine();
  }

  void backToMenu() {
    isGameOver = false;
    score = 0;
    matchCoins = 0;
    matchCoinsSaved = false;
    storedShields = 0;
    storedRapidFires = 0;
    currentUpgradeOptions = [];
    upgradeSelectionPosition = Vector2.zero();
    currentLevel = 1;
    player.lives = 3;
    player.hitCount = 0;
    player.resetPowerups();
    updateScore();
    updateLevel();
    updateLives();
    updateCoins();
    updateMatchCoins();
    onShieldStateChanged?.call();

    player.position = Vector2(
      size.x / 2 - Player.playerSize / 2,
      size.y - Player.playerSize - 20,
    );

    clearActiveRunComponents();
    spawnLevel();

    overlays.remove('PauseMenu');
    overlays.remove('ConfirmBackToMenu');
    overlays.remove('PauseButton');
    overlays.remove('GameOver');
    overlays.remove('BossUpgrade');
    overlays.add('StartMenu');
    pauseEngine();
  }
}

class Player extends SpriteComponent with CollisionCallbacks {
  static const double speed = 200.0;
  static const double playerSize = 50.0;
  static const double rapidFireShootInterval = 0.07;

  String shipAsset = 'ship.png';
  bool isMovingLeft = false;
  bool isMovingRight = false;
  bool isMovingUp = false;
  bool isMovingDown = false;
  bool isHudFiring = false;
  Vector2 hudMoveDirection = Vector2.zero();

  late Vector2 gameSize;
  int lives = 3;
  int hitCount = 0;
  double shootTimer = 0.0;
  double rapidFireTimer = 0.0;
  double shieldTimer = 0.0;
  int weaponLevel = 1;
  int damageUpgrade = 0;
  double fireRateMultiplier = 1.0;
  double bulletSpeedUpgradeMultiplier = 1.0;
  double shieldDurationBonus = 0.0;
  bool hasDoubleShot = false;

  int get shipNumber {
    if (shipAsset == 'ship.png') return 0;

    final match = RegExp(r'^ship(\d+)\.png$').firstMatch(shipAsset);
    if (match == null) return 0;

    return int.tryParse(match.group(1) ?? '') ?? 0;
  }

  int get bulletDamage {
    return shipNumber + 1 + damageUpgrade;
  }

  double get normalShootInterval =>
      switch (shipNumber) {
        1 => 0.9,
        3 => 0.8,
        4 => 0.7,
        5 => 0.6,
        6 => 0.5,
        7 => 0.4,
        8 => 0.3,
        _ => 1.0,
      } *
      fireRateMultiplier;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await Sprite.load(shipAsset);
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
    if (hudMoveDirection.length2 > 0) {
      position += hudMoveDirection * speed * dt;
    }
    // Clamp position to screen boundaries
    position.x = position.x.clamp(0.0, gameSize.x - size.x);
    position.y = position.y.clamp(0.0, gameSize.y - size.y);

    // Player shooting
    if (rapidFireTimer > 0) {
      rapidFireTimer -= dt;
      if (rapidFireTimer < 0) {
        rapidFireTimer = 0;
      }
    }
    if (shieldTimer > 0) {
      shieldTimer -= dt;
      if (shieldTimer < 0) {
        shieldTimer = 0;
      }
    }

    shootTimer += dt;
    final autoShootEnabled =
        parent is MyGame && (parent as MyGame).controlMode == ControlMode.drag;
    final shouldShoot = autoShootEnabled || isHudFiring;
    if (shouldShoot && shootTimer >= shootInterval) {
      shootTimer = 0.0;
      shoot();
    }
  }

  void heal() {
    lives++;
    (parent as MyGame).updateLives();
  }

  void takeDamage({int damage = 1}) {
    if ((parent as MyGame).isGameOver) return;
    if (shieldTimer > 0) return;

    hitCount += damage;
    final livesLost = hitCount ~/ 2;
    hitCount = hitCount % 2;

    if (livesLost > 0) {
      lives -= livesLost;
      lives = max(0, lives);
      final game = parent as MyGame;
      game.updateLives();
      if (lives <= 0) {
        game.gameOver();
      }
    }
  }

  void activateRapidFire() {
    rapidFireTimer = 5.0;
    shootTimer = shootInterval;
  }

  void activateShield() {
    shieldTimer = 5.0 + shieldDurationBonus;
    (parent as MyGame).onShieldStateChanged?.call();
  }

  void startHudFiring() {
    isHudFiring = true;
    shootTimer = shootInterval;
  }

  void stopHudFiring() {
    isHudFiring = false;
  }

  void stopHudControls() {
    isHudFiring = false;
    hudMoveDirection = Vector2.zero();
  }

  void applyUpgrade(ShipUpgradeType upgrade) {
    switch (upgrade) {
      case ShipUpgradeType.damage:
        damageUpgrade++;
      case ShipUpgradeType.fireRate:
        fireRateMultiplier = max(0.35, fireRateMultiplier * 0.9);
      case ShipUpgradeType.bulletSpeed:
        bulletSpeedUpgradeMultiplier += 0.15;
      case ShipUpgradeType.shieldDuration:
        shieldDurationBonus += 2.0;
      case ShipUpgradeType.doubleShot:
        hasDoubleShot = true;
    }
  }

  void shoot() {
    if (hasDoubleShot) {
      for (final offsetX in [-10.0, 10.0]) {
        _spawnBullet(
          Vector2(0, -1),
          offsetX: offsetX,
          color: bulletColor,
          speedMultiplier: bulletSpeedMultiplier * bulletSpeedUpgradeMultiplier,
          sizeBonus: bulletSizeBonus,
          style: bulletStyle,
        );
      }
      return;
    }

    _spawnBullet(
      Vector2(0, -1),
      color: bulletColor,
      speedMultiplier: bulletSpeedMultiplier * bulletSpeedUpgradeMultiplier,
      sizeBonus: bulletSizeBonus,
      style: bulletStyle,
    );

    // Play sound
    try {
      // FlameAudio.play('shot.mp3', volume: 0.3);
    } catch (e) {
      // Silently fail if audio doesn't exist
    }
  }

  Color get bulletColor => switch (shipNumber) {
    1 => Colors.lightBlueAccent,
    3 => Colors.pinkAccent,
    4 => Colors.amberAccent,
    5 => Colors.purpleAccent,
    6 => Colors.greenAccent,
    7 => Colors.deepOrangeAccent,
    8 => Colors.cyanAccent,
    _ => Colors.cyan,
  };

  int get bulletStyle => switch (shipNumber) {
    1 => 1,
    3 => 2,
    4 => 3,
    5 => 4,
    6 => 5,
    7 => 6,
    8 => 7,
    _ => 0,
  };

  double get bulletSizeBonus => switch (shipNumber) {
    _ => 0.0,
  };

  double get bulletSpeedMultiplier => switch (shipNumber) {
    6 => 1.45,
    8 => 1.25,
    _ => 1.0,
  };

  void _spawnBullet(
    Vector2 dir, {
    double offsetX = 0,
    Color color = Colors.cyan,
    double speedMultiplier = 1.0,
    double sizeBonus = 0.0,
    int style = 0,
  }) {
    final bullet = PlayerBullet();
    final bulletSize = PlayerBullet.laserSizeFor(
      damage: bulletDamage,
      sizeBonus: sizeBonus,
      style: style,
    );
    bullet.position =
        position.clone() +
        Vector2(size.x / 2 + offsetX - bulletSize.x / 2, -bulletSize.y);
    bullet.direction = dir.normalized();
    bullet.damage = bulletDamage;
    bullet.color = color;
    bullet.speedMultiplier = speedMultiplier;
    bullet.sizeBonus = sizeBonus;
    bullet.style = style;
    (parent as MyGame).add(bullet);
  }

  double get shootInterval =>
      rapidFireTimer > 0 ? rapidFireShootInterval : normalShootInterval;

  void resetPowerups() {
    rapidFireTimer = 0.0;
    shieldTimer = 0.0;
    shootTimer = 0.0;
    stopHudControls();
    weaponLevel = 1;
    damageUpgrade = 0;
    fireRateMultiplier = 1.0;
    bulletSpeedUpgradeMultiplier = 1.0;
    shieldDurationBonus = 0.0;
    hasDoubleShot = false;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (shieldTimer <= 0) return;

    final center = Offset(size.x / 2, size.y / 2);
    final pulse = 0.5 + 0.5 * sin(shieldTimer * pi * 4);
    final radius = size.x * (0.66 + pulse * 0.04);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.cyanAccent.withAlpha(55)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.cyanAccent.withAlpha(210)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}

class ShieldPowerup extends PositionComponent with CollisionCallbacks {
  static const double itemSize = 34.0;
  late Vector2 gameSize;
  static const double fallSpeed = 150.0;

  ShieldPowerup() : super(size: Vector2.all(itemSize)) {
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
      (parent as MyGame).collectShieldPowerup();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(
      center,
      size.x * 0.44,
      Paint()
        ..color = Colors.cyanAccent.withAlpha(70)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      size.x * 0.42,
      Paint()
        ..color = Colors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final shieldPath = Path()
      ..moveTo(size.x * 0.5, size.y * 0.18)
      ..quadraticBezierTo(
        size.x * 0.76,
        size.y * 0.28,
        size.x * 0.76,
        size.y * 0.42,
      )
      ..quadraticBezierTo(
        size.x * 0.74,
        size.y * 0.68,
        size.x * 0.5,
        size.y * 0.84,
      )
      ..quadraticBezierTo(
        size.x * 0.26,
        size.y * 0.68,
        size.x * 0.24,
        size.y * 0.42,
      )
      ..quadraticBezierTo(
        size.x * 0.24,
        size.y * 0.28,
        size.x * 0.5,
        size.y * 0.18,
      )
      ..close();
    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = Colors.white.withAlpha(225)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
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
  static const double laserWidth = 6.0;
  static const double laserHeight = 22.0;
  static const double speed = 400.0;
  late Vector2 direction;
  int damage = 1;
  Color color = Colors.cyan;
  double speedMultiplier = 1.0;
  double sizeBonus = 0.0;
  int style = 0;

  static Vector2 laserSizeFor({
    required int damage,
    required double sizeBonus,
    required int style,
  }) {
    return Vector2(laserWidth, laserHeight);
  }

  @override
  Future<void> onLoad() async {
    size = laserSizeFor(damage: damage, sizeBonus: sizeBonus, style: style);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direction * speed * speedMultiplier * dt;
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
      other.health -= damage;
      removeFromParent(); // Remove bullet
      if (other.health <= 0) {
        final defeatedEnemyPosition = other.position.clone();
        final defeatedEnemyWasBoss = other.isBoss;
        // Enemy dies
        other.removeFromParent();
        (parent as MyGame).enemies.remove(other);
        final game = parent as MyGame;
        game.score += other.scoreReward; // Add score
        game.matchCoins += other.coinReward; // Add coins for this match
        game.registerEnemyDestroyedForMission();
        game.updateScore();
        game.updateMatchCoins();

        // Check for extra life every 150 score
        if (game.score > 0 && game.score % 150 == 0) {
          game.spawnHeartPowerup();
        }

        // Check for rapid-fire powerup every 300 score
        if (game.score > 0 && game.score % 300 == 0) {
          game.spawnWeaponPowerup();
        }

        if (defeatedEnemyWasBoss) {
          game.spawnShieldPowerup(defeatedEnemyPosition);
        }

        // Check if level complete
        if (game.enemies.isEmpty) {
          game.completeLevel(defeatedBoss: defeatedEnemyWasBoss);
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
    final glowPaint = Paint()
      ..color = color.withAlpha(90)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final mainPaint = Paint()..color = color;
    final corePaint = Paint()..color = Colors.white.withAlpha(230);
    final hotPaint = Paint()..color = Colors.white;

    void drawBeam({
      required double width,
      required double coreWidth,
      Color? accent,
      double radius = 5,
    }) {
      final centerX = size.x / 2;
      final glowRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, size.y / 2),
          width: width * 1.9,
          height: size.y,
        ),
        Radius.circular(radius),
      );
      final beamRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, size.y / 2),
          width: width,
          height: size.y,
        ),
        Radius.circular(radius),
      );
      final coreRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, size.y / 2),
          width: coreWidth,
          height: size.y * 0.78,
        ),
        Radius.circular(radius),
      );
      final accentPaint = Paint()
        ..color = accent ?? Colors.white.withAlpha(230);

      canvas.drawRRect(glowRect, glowPaint);
      canvas.drawRRect(beamRect, mainPaint);
      canvas.drawRRect(coreRect, accent == null ? corePaint : accentPaint);
      canvas.drawCircle(Offset(centerX, 2), width * 0.28, hotPaint);
    }

    switch (style) {
      case 1:
        drawBeam(width: size.x * 0.72, coreWidth: size.x * 0.28);
      case 2:
        final path = Path()
          ..moveTo(size.x / 2, 0)
          ..lineTo(size.x * 0.85, size.y * 0.22)
          ..lineTo(size.x * 0.64, size.y)
          ..lineTo(size.x * 0.36, size.y)
          ..lineTo(size.x * 0.15, size.y * 0.22)
          ..close();
        canvas.drawPath(path, glowPaint);
        canvas.drawPath(path, mainPaint);
        final core = Path()
          ..moveTo(size.x / 2, size.y * 0.08)
          ..lineTo(size.x * 0.6, size.y * 0.34)
          ..lineTo(size.x / 2, size.y)
          ..lineTo(size.x * 0.4, size.y * 0.34)
          ..close();
        canvas.drawPath(core, corePaint);
      case 3:
        drawBeam(width: size.x * 0.74, coreWidth: size.x * 0.28);
        canvas.drawLine(
          Offset(size.x * 0.12, size.y * 0.24),
          Offset(size.x * 0.12, size.y * 0.86),
          Paint()
            ..color = Colors.orangeAccent
            ..strokeWidth = 1,
        );
        canvas.drawLine(
          Offset(size.x * 0.88, size.y * 0.24),
          Offset(size.x * 0.88, size.y * 0.86),
          Paint()
            ..color = Colors.orangeAccent
            ..strokeWidth = 1,
        );
      case 4:
        drawBeam(
          width: size.x * 0.7,
          coreWidth: size.x * 0.25,
          accent: Colors.purple.shade100,
        );
        canvas.drawCircle(
          Offset(size.x * 0.24, size.y * 0.4),
          size.x * 0.08,
          mainPaint,
        );
        canvas.drawCircle(
          Offset(size.x * 0.76, size.y * 0.62),
          size.x * 0.08,
          mainPaint,
        );
      case 5:
        drawBeam(width: size.x * 0.7, coreWidth: size.x * 0.22);
        canvas.drawLine(
          Offset(size.x * 0.2, size.y * 0.15),
          Offset(size.x * 0.8, size.y * 0.85),
          Paint()
            ..color = Colors.greenAccent.withAlpha(180)
            ..strokeWidth = 1,
        );
      case 6:
        drawBeam(width: size.x * 0.68, coreWidth: size.x * 0.22);
        final sidePaint = Paint()
          ..color = Colors.deepOrangeAccent
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(size.x * 0.16, size.y * 0.2),
          Offset(size.x * 0.32, size.y * 0.9),
          sidePaint,
        );
        canvas.drawLine(
          Offset(size.x * 0.84, size.y * 0.2),
          Offset(size.x * 0.68, size.y * 0.9),
          sidePaint,
        );
      case 7:
        drawBeam(width: size.x * 0.72, coreWidth: size.x * 0.24);
        canvas.drawCircle(
          Offset(size.x / 2, size.y * 0.34),
          size.x * 0.2,
          glowPaint,
        );
        canvas.drawCircle(
          Offset(size.x / 2, size.y * 0.34),
          size.x * 0.12,
          mainPaint,
        );
      default:
        drawBeam(width: size.x * 0.7, coreWidth: size.x * 0.24);
    }
  }
}

class Enemy extends SpriteComponent {
  static const double enemySize = 40.0;
  static const double bossSize = 120.0;
  final Random movementRandom = Random();
  late Vector2 gameSize;
  late Player player;
  double shootTimer = 0.0;
  late double shootInterval;
  late double moveSpeed;
  double direction = 1.0; // 1 for right, -1 for left
  double randomDirectionTimer = 0.0;
  double randomSpeedMultiplier = 1.0;
  double targetY = 0.0;
  double entrySpeed = 180.0;
  bool isEntering = true;
  late int health; // New: health system
  late int maxHealth; // New: max health system
  late int level;
  int bossLevel = 0;

  bool get isBoss => bossLevel > 0;
  bool get isSecondBoss => bossLevel == 2;
  bool get isThirdBoss => bossLevel == 3;
  String get spriteAsset => switch (bossLevel) {
    1 => 'boss1.png',
    2 => 'boss2.png',
    3 => 'boss3.png',
    4 => 'boss4.png',
    5 => 'boss5.png',
    6 => 'boss6.png',
    7 => 'boss7.png',
    8 => 'boss8.png',
    9 => 'boss9.png',
    10 => 'boss10.png',
    _ => 'ship2.png',
  };
  int get bossMaxHealth => switch (bossLevel) {
    10 => 6000,
    9 => 4800,
    8 => 3600,
    7 => 2500,
    6 => 1800,
    5 => 1200,
    4 => 800,
    3 => 500,
    2 => 300,
    1 => 150,
    _ => level,
  };
  int get scoreReward => switch (bossLevel) {
    10 => 2200,
    9 => 1700,
    8 => 1300,
    7 => 1050,
    6 => 900,
    5 => 650,
    4 => 450,
    3 => 300,
    2 => 180,
    1 => 100,
    _ => 10,
  };
  int get coinReward => switch (bossLevel) {
    10 => 300,
    9 => 230,
    8 => 180,
    7 => 145,
    6 => 120,
    5 => 85,
    4 => 60,
    3 => 40,
    2 => 25,
    1 => 15,
    _ => 1,
  };
  int get bulletDamage => isBoss ? bossLevel : 1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await Sprite.load(spriteAsset);
    size = Vector2.all(isBoss ? bossSize : enemySize);
    add(CircleHitbox());

    // Calcula dificuldade a cada 10 níveis
    int difficultyTier = level ~/ 10;

    if (isBoss) {
      moveSpeed = switch (bossLevel) {
        10 => 240.0,
        9 => 225.0,
        8 => 210.0,
        7 => 195.0,
        6 => 180.0,
        5 => 165.0,
        4 => 150.0,
        3 => 135.0,
        2 => 115.0,
        _ => 90.0,
      };
      shootInterval = switch (bossLevel) {
        10 => 0.14,
        9 => 0.17,
        8 => 0.19,
        7 => 0.21,
        6 => 0.24,
        5 => 0.27,
        4 => 0.30,
        3 => 0.34,
        2 => 0.42,
        _ => 0.55,
      };
      return;
    }

    // Mais rápido a cada 10 níveis (começa em 50)
    moveSpeed = 50.0 + (difficultyTier * 20.0);
    pickRandomMovement();
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

    if (isEntering) {
      final nextY = position.y + entrySpeed * dt;
      if (nextY >= targetY - 1) {
        position.y = targetY;
        isEntering = false;
      } else {
        position.y = nextY;
        return;
      }
    }

    if (!isBoss) {
      randomDirectionTimer -= dt;
      if (randomDirectionTimer <= 0) {
        pickRandomMovement();
      }
    }

    shootTimer += dt;
    if (shootTimer >= shootInterval) {
      shootTimer = 0.0;
      shoot();
    }
    // Move left and right
    position.x += moveSpeed * randomSpeedMultiplier * direction * dt;
    if (position.x <= 0 || position.x >= gameSize.x - size.x) {
      direction = -direction;
      randomDirectionTimer = min(randomDirectionTimer, 0.35);
    }
    // Clamp to prevent sticking
    position.x = position.x.clamp(0.0, gameSize.x - size.x);
  }

  void pickRandomMovement() {
    direction = movementRandom.nextBool() ? 1.0 : -1.0;
    randomSpeedMultiplier = 0.65 + movementRandom.nextDouble() * 0.7;
    randomDirectionTimer = 0.55 + movementRandom.nextDouble() * 1.45;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!isBoss) return;

    final barWidth = size.x;
    const barHeight = 8.0;
    const barOffset = -14.0;
    final healthPercent = health / maxHealth;

    canvas.drawRect(
      Rect.fromLTWH(0, barOffset, barWidth, barHeight),
      Paint()..color = Colors.black87,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, barOffset, barWidth * healthPercent, barHeight),
      Paint()
        ..color = switch (bossLevel) {
          10 => Colors.cyanAccent,
          9 => Colors.blueAccent,
          8 => Colors.pinkAccent,
          7 => Colors.limeAccent,
          6 => Colors.white,
          5 => Colors.greenAccent,
          4 => Colors.amberAccent,
          3 => Colors.deepOrangeAccent,
          2 => Colors.purpleAccent,
          _ => Colors.redAccent,
        },
    );
    canvas.drawRect(
      Rect.fromLTWH(0, barOffset, barWidth, barHeight),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void shoot() {
    final bullet = Bullet();
    bullet.position = position.clone() + Vector2(size.x / 2, size.y * 0.8);
    bullet.difficultyTier = level ~/ 10; // Repassa a dificuldade para a bala
    bullet.damage = bulletDamage;

    // Calculate base direction towards player
    Vector2 toPlayer = player.position - bullet.position;
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
  int damage = 1;

  @override
  Future<void> onLoad() async {
    size = Vector2.all(damage > 1 ? bulletSize * 1.4 : bulletSize);
    add(CircleHitbox());

    // A bala fica mais rápida a cada 10 níveis
    speed = 250.0 + (difficultyTier * 50.0) + (damage > 1 ? 80.0 : 0.0);
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
      other.takeDamage(damage: damage);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()..color = damage > 1 ? Colors.redAccent : Colors.yellow,
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

      particles.add(
        _ExplosionParticle(
          velocity: Vector2(cos(angle), sin(angle)) * speed,
          color: color,
          size: particleSize,
        ),
      );
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
        shadows: [
          Shadow(blurRadius: 4.0, color: Colors.black, offset: Offset(2, 2)),
        ],
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
      (parent as MyGame).collectWeaponPowerup();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final textPaint = TextPaint(
      style: const TextStyle(
        fontSize: 30,
        shadows: [
          Shadow(blurRadius: 4.0, color: Colors.black, offset: Offset(2, 2)),
        ],
      ),
    );
    textPaint.render(canvas, '⚡', Vector2.zero());
  }
}
