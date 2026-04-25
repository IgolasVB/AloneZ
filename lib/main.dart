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
                    ],
                  ),
                    ),
                  ],
                );
              },
              'FreeCoinsMenu': (BuildContext context, MyGame game) {
                return StatefulBuilder(
                  builder: (context, setState) {
                    return Center(
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
                          const Text(
                            'Anuncios em breve.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('INDISPONIVEL', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              game.overlays.remove('FreeCoinsMenu');
                              game.overlays.add('StartMenu');
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('VOLTAR', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              'ShopMenu': (BuildContext context, MyGame game) {
                return StatefulBuilder(
                  builder: (context, setState) {
                    return SingleChildScrollView(
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
                                shadows: [Shadow(blurRadius: 10, color: Colors.black)],
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
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: () {
                                game.overlays.remove('ShopMenu');
                                game.overlays.add('StartMenu');
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('VOLTAR', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
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
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          game.backToMenu();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('MENU', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          game.overlays.remove('PauseMenu');
                          game.overlays.add('ConfirmBackToMenu');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('MENU', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                          shadows: [Shadow(blurRadius: 10, color: Colors.black)],
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
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('CONFIRMAR', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          game.overlays.remove('ConfirmBackToMenu');
                          game.overlays.add('PauseMenu');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('CANCELAR', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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

  const CoinCounter({
    super.key,
    required this.value,
    this.fontSize = 24,
  });

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
              BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(2, 2)),
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
    final borderColor = primary ? const Color(0xFFFF4FBF) : const Color(0xFF5EDCFF);
    final backgroundColor = primary ? const Color(0xCC5A063C) : const Color(0xCC061B36);
    final iconColor = primary ? Colors.white : const Color(0xFF78E6FF);
    final glowColor = primary ? const Color(0xA6FF4FBF) : const Color(0xA65EDCFF);

    return Container(
      width: 320,
      height: primary ? 66 : 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: glowColor, blurRadius: 14, spreadRadius: 1),
          const BoxShadow(color: Colors.black87, blurRadius: 10, offset: Offset(3, 4)),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: primary ? 30 : 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
              ),
            ),
          ],
        ),
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
        border: Border.all(color: owned ? Colors.amber : Colors.cyan, width: owned ? 3 : 2),
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
                  BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(2, 2)),
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
          Image.asset(
            imagePath,
            width: 90,
            height: 90,
            fit: BoxFit.contain,
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
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
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
        Positioned.fill(
          child: Container(color: const Color(0xCC020712)),
        ),
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
                      BoxShadow(color: Colors.black87, blurRadius: 14, offset: Offset(3, 4)),
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
                ElevatedButton(
                  onPressed: onBack,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 15),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    'VOLTAR',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
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
        border: Border.all(
          color: borderColor,
          width: selected ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          if (selected)
            const BoxShadow(color: Color(0x99FFC107), blurRadius: 16, spreadRadius: 1),
          const BoxShadow(color: Colors.black87, blurRadius: 12, offset: Offset(3, 4)),
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
              selected ? 'USANDO' : unlocked ? 'EQUIPAR' : 'BLOQUEADA',
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
  static const int ship1Price = 50;
  static const int ship3Price = 100;
  static const int ship4Price = 150;
  static const int ship5Price = 200;
  static const int ship6Price = 250;
  static const int ship7Price = 300;
  static const int ship8Price = 350;

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
    ownsShip1 = prefs.getBool('ownsShip1') ?? false;
    ownsShip3 = prefs.getBool('ownsShip3') ?? false;
    ownsShip4 = prefs.getBool('ownsShip4') ?? false;
    ownsShip5 = prefs.getBool('ownsShip5') ?? false;
    ownsShip6 = prefs.getBool('ownsShip6') ?? false;
    ownsShip7 = prefs.getBool('ownsShip7') ?? false;
    ownsShip8 = prefs.getBool('ownsShip8') ?? false;
    selectedShipAsset = prefs.getString('selectedShipAsset') ?? 'ship.png';
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

  void updateCoins() {
    prefs.setInt('coins', coins);
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

  void restart() {
    isGameOver = false;
    score = 0;
    matchCoins = 0;
    matchCoinsSaved = false;
    currentLevel = 1;
    player.lives = 3;
    player.hitCount = 0;
    player.weaponLevel = 1;
    player.shootInterval = 1.0;
    updateScore();
    updateMatchCoins();
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
    children.whereType<HeartPowerup>().forEach((heart) => heart.removeFromParent());
    children.whereType<WeaponPowerup>().forEach((powerup) => powerup.removeFromParent());
    
    enemies.clear();
    spawnLevel();
    overlays.add('PauseButton');
    resumeEngine();
  }

  void backToMenu() {
    isGameOver = false;
    score = 0;
    matchCoins = 0;
    matchCoinsSaved = false;
    currentLevel = 1;
    player.lives = 3;
    player.hitCount = 0;
    player.weaponLevel = 1;
    player.shootInterval = 1.0;
    updateScore();
    updateLevel();
    updateLives();
    updateCoins();
    updateMatchCoins();

    player.position = Vector2(
      size.x / 2 - Player.playerSize / 2,
      size.y - Player.playerSize - 20,
    );

    children.whereType<Enemy>().forEach((enemy) => enemy.removeFromParent());
    children.whereType<Bullet>().forEach((bullet) => bullet.removeFromParent());
    children.whereType<PlayerBullet>().forEach((bullet) => bullet.removeFromParent());
    children.whereType<Explosion>().forEach((explosion) => explosion.removeFromParent());
    children.whereType<HeartPowerup>().forEach((heart) => heart.removeFromParent());
    children.whereType<WeaponPowerup>().forEach((powerup) => powerup.removeFromParent());

    enemies.clear();
    spawnLevel();

    overlays.remove('PauseMenu');
    overlays.remove('ConfirmBackToMenu');
    overlays.remove('PauseButton');
    overlays.remove('GameOver');
    overlays.add('StartMenu');
    pauseEngine();
  }
}

class Player extends SpriteComponent with CollisionCallbacks {
  static const double speed = 200.0;
  static const double playerSize = 50.0;

  String shipAsset = 'ship.png';
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
        game.matchCoins += 1; // Add one coin for this match per defeated enemy
        game.updateScore();
        game.updateMatchCoins();
        
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
