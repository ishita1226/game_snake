import 'dart:async';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:game_snake/blank_pixel.dart';
import 'package:game_snake/food_pixel.dart';
// import 'package:game_snake/highscore_tile.dart';
import 'package:game_snake/snake_pixel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum snake_Direction { UP, DOWN, LEFT, RIGHT }

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
}

class _HomePageState extends State<HomePage> {
  bool _initialized = false;
  late Future<void> _initializationFuture;

  int rowSize = 10;
  int totalNumberOfSquares = 100;

  bool gameHasStarted = false;
  final _nameController = TextEditingController();

  int currentScore = 0;

  List<int> snakePos = [0, 1, 2];

  //initial snake direction: right
  var currentDirection = snake_Direction.RIGHT;

  int foodPos = 55;

  List<String> highscore_DocIds = [];
  late final Future? letsGetDocIds;

  @override
  void initState() {
    getDocId();
    super.initState();
    _initializationFuture = initializeFirebase().then((_) {
      setState(() {
        _initialized = true;
      });
    });
  }

  Future<void> getDocId() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('highscores')
        .orderBy('score', descending: true)
        .limit(10)
        .get();

    setState(() {
      highscore_DocIds = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  void startGame() {
    gameHasStarted = true;
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        moveSnake();

        // eatFood();
        if (gameOver()) {
          timer.cancel();
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Game Over'),
                  content: Column(
                    children: [
                      Text('Your score is $currentScore'),
                      TextField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(hintText: 'Enter your name'),
                      )
                    ],
                  ),
                  actions: [
                    MaterialButton(
                      onPressed: () {
                        Navigator.pop(context);
                        submitScore();
                        newGame();
                      },
                      color: Colors.amber,
                      child: const Text('Submit'),
                    )
                  ],
                );
              });
        }
      });
    });
  }

  Future<void> submitScore() async {
    if (!_initialized) {
      await _initializationFuture;
    }

    try {
      await FirebaseFirestore.instance.collection('highScores').add({
        "name": _nameController.text,
        "score": currentScore,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error submitting score: $e');
    }
  }

  void newGame() {
    setState(() {
      snakePos = [0, 1, 2];
    });
    foodPos = 55;
    currentDirection = snake_Direction.RIGHT;
    gameHasStarted = false;
    currentScore = 0;
  }

  void eatFood() {
    currentScore++;
    while (snakePos.contains(foodPos)) {
      foodPos = Random().nextInt(totalNumberOfSquares);
    }
  }

  void moveSnake() {
    switch (currentDirection) {
      case snake_Direction.RIGHT:
        {
          if (snakePos.last % rowSize == 9) {
            snakePos.add(snakePos.last + 1 - rowSize);
          } else {
            snakePos.add(snakePos.last + 1);
          }
        }

        break;
      case snake_Direction.LEFT:
        {
          if (snakePos.last % rowSize == 0) {
            snakePos.add(snakePos.last - 1 + rowSize);
          } else {
            snakePos.add(snakePos.last - 1);
          }
        }

        break;
      case snake_Direction.DOWN:
        {
          if (snakePos.last + rowSize > totalNumberOfSquares) {
            snakePos.add(snakePos.last + rowSize - totalNumberOfSquares);
          } else {
            snakePos.add(snakePos.last + rowSize);
          }
        }

        break;
      case snake_Direction.UP:
        {
          if (snakePos.last < rowSize) {
            snakePos.add(snakePos.last - rowSize + totalNumberOfSquares);
          } else {
            snakePos.add(snakePos.last - rowSize);
          }
        }

        break;
      default:
    }

    if (snakePos.last == foodPos) {
      eatFood();
    } else {
      snakePos.removeAt(0);
    }
  }

  bool gameOver() {
    List<int> bodySnake = snakePos.sublist(0, snakePos.length - 1);
    if (bodySnake.contains(snakePos.last)) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return FutureBuilder(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Scaffold(
            backgroundColor: Colors.black,
            body: SizedBox(
              width: screenWidth > 450 ? 450 : screenWidth,
              child: Column(
                children: [
                  Expanded(
                      child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Current Score:'),
                          Text(
                            currentScore.toString(),
                            style: const TextStyle(fontSize: 36),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const SizedBox(height: 30), // Top padding
                            const Text(
                              'High Scores',
                              style: TextStyle(
                                // fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            StreamBuilder(
                              stream: FirebaseFirestore.instance
                                  .collection('highScores')
                                  .orderBy('score', descending: true)
                                  .limit(5) // Limited to top 5
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Column(
                                    children: List.generate(
                                      snapshot.data!.docs.length,
                                      (index) {
                                        final score =
                                            snapshot.data!.docs[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 3.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '${index + 1}. ${score['name']}',
                                                style: const TextStyle(
                                                    fontSize: 10),
                                              ),
                                              const SizedBox(width: 20),
                                              Text(
                                                score['score'].toString(),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            ),
                          ],
                        ),
                      )
                    ],
                  )),
                  //game grid
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        if (details.delta.dy > 0 &&
                            currentDirection != snake_Direction.UP) {
                          currentDirection = snake_Direction.DOWN;
                        } else if (details.delta.dy < 0 &&
                            currentDirection != snake_Direction.DOWN) {
                          // print('move up');
                          currentDirection = snake_Direction.UP;
                        }
                      },
                      onHorizontalDragUpdate: (details) {
                        if (details.delta.dx > 0 &&
                            currentDirection != snake_Direction.LEFT) {
                          // print('move right');
                          currentDirection = snake_Direction.RIGHT;
                        } else if (details.delta.dx < 0 &&
                            currentDirection != snake_Direction.RIGHT) {
                          // print('move left');
                          currentDirection = snake_Direction.LEFT;
                        }
                      },
                      child: GridView.builder(
                          itemCount: totalNumberOfSquares,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: rowSize),
                          itemBuilder: (context, index) {
                            if (snakePos.contains(index)) {
                              return const SnakePixel();
                            } else if (foodPos == index) {
                              return const FoodPixel();
                            } else {
                              return const BlankPixel();
                            }
                            // return Text(index.toString());
                          }),
                    ),
                  ),
                  //play button
                  Expanded(
                    child: Container(
                      child: Center(
                        child: MaterialButton(
                          color: gameHasStarted ? Colors.grey : Colors.amber,
                          onPressed: gameHasStarted ? () {} : startGame,
                          child: const Text('Play'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
