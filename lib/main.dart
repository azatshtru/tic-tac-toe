import 'dart:ffi' as ffi;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const App());
}

typedef AddMove = Function(int index);

class Box extends StatelessWidget {
  const Box({required this.index, required this.value, required this.onChange, super.key});

  final int index;
  final String value;
  final AddMove onChange;

  @override
  Widget build(BuildContext context){
    return GestureDetector(
      onTap: () {
        onChange(index);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1.0),
          color: Colors.white,
        ),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraint) {
              switch(value){
                case 'X':
                  return Icon(
                    Icons.close_sharp,
                    size: constraint.biggest.height * 0.85,
                    color: Colors.grey[800],
                  );

                case 'O':
                  return Icon(
                    Icons.circle_outlined,
                    size: constraint.biggest.height * 0.78,
                    color: Colors.grey[800],
                  );

                default:
                  return const Text('');
              }
            }
          ),
        ),
      ),
    );
  }
}

class Board extends StatelessWidget {

  final List _boardState = List.filled(9, '');
  final AddMove onChange;
  final int strikethroughPosition;

  Board({required moves, required this.onChange, required this.strikethroughPosition, super.key}){
    for(int i = 0; i < moves.length; i++){
      _boardState[moves[i]] = i % 2 == 0 ? 'X' : 'O';
    }
  }

  @override
  Widget build(BuildContext context){
    return Center(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 2.0, color: Colors.black),
        ),
    
        width: MediaQuery.of(context).size.width * 0.87,
        height: MediaQuery.of(context).size.width * 0.87,
    
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3, (i) => Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3, (j) => Expanded(child: Box(index: i*3 + j, value: _boardState[i*3 + j], onChange: onChange,))
                    ),
                  ),
                ),
              ),
            ),

            if(strikethroughPosition > -1) Strikethrough(size: MediaQuery.of(context).size, position: strikethroughPosition,),
          ],
        ),
      ),
    );
  }
}

class Strikethrough extends StatelessWidget {
  const Strikethrough({required this.size, required this.position, super.key});

  final Size size;
  final int position;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: LinePainter(position: position),
    );
  }
}

class LinePainter extends CustomPainter{
  const LinePainter({required this.position});

  final int position;

  int get m => position ~/ 3;
  int get n => position % 3;

  final double c = 0.05;

  List get p => 
    m == 2 ? [m-2, n.toDouble(), m-1, (n-1).abs().toDouble()] :
    [
      (m*(2*n + 1)/6) - ((m-1).abs()*c), 
      ((m+1)%2*(2*n + 1)/6) - (m*c), 
      (m*(2*n - 5)/6) + ((m-1).abs()*c) + 1,
      ((m+1)%2*(2*n - 5)/6) + (m%2*c) + 1
    ];

  @override
  void paint(Canvas canvas, Size size){
    Paint linePaint = Paint() .. strokeWidth=14 .. color=Colors.redAccent.withOpacity(0.85);
    canvas.drawLine(
      Offset(p[0] * size.width, p[1] * size.height), 
      Offset(p[2] * size.width, p[3] * size.height), 
      linePaint
      );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate){
    return true;
  }
}

class Game extends StatefulWidget {
  const Game({required this.squares, required this.verbs, required this.adverbs, super.key});

  final List<int> squares;
  final List<String> verbs;
  final List<String> adverbs;

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> {
  final List moves = <int>[];

  int get currentMove => (moves.length-1) % 2;
  int get status => _calculateWinner();
  String get statusText => status == -1 ? 
    moves.length < 9 ? '${currentMove == 0 ? 'O' : 'X'}' "'s turn" : "tie." :
    '${currentMove == 0 ? 'X ' : 'O '}' '${widget.verbs[Random().nextInt(widget.verbs.length)]} ' '${widget.adverbs[status]}';

  int bsf(int x){
    int count = 0;
    while(x != 0){
      x = x << 1;
      count++;
    }
    return count;
  }

  int _calculateWinner(){
    int score = 0x0.toInt();
    for(int i = currentMove; i < moves.length; i += 2){
      score = score | widget.squares[moves[i]];
    }

    score = score & (score << 1) & (score >> 1);

    if(score != 0x0){
      return ((bsf(score) - 2)~/4)-(ffi.sizeOf<ffi.IntPtr>() == 8 ? ffi.sizeOf<ffi.IntPtr>() : 0);
    }
    return -1;
  }
  
  void addMove(int index){
    if(moves.contains(index) || moves.length >= 9 || status != -1){
      return;
    }
    setState(() {
      moves.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height*0.12),
        child: Center(
          child: Column(
            children: [
              Board(
                moves: moves,
                onChange: addMove,
                strikethroughPosition: status,
              ),
              SizedBox(width: double.infinity, height: MediaQuery.of(context).size.height*0.06,),
              Text(
                statusText,
                style: GoogleFonts.dmMono(
                  fontSize: 18,
                ),
              ),
              SizedBox(width: double.infinity, height: MediaQuery.of(context).size.height*0.06,),
              if (moves.length >= 9 || status != -1) FilledButton(
                onPressed: () {
                  setState(() {
                    moves.clear();
                  });
                },
                child: Text("play again!",
                  style: GoogleFonts.dmMono(
                    fontSize: 18,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: Material(
        child: Scaffold(
          appBar: AppBar(
            leading: const Icon(Icons.grid_3x3),
            title: Text(
              "tic_tac_toe",
              style: GoogleFonts.dmMono(),
            ),
          ),
          body: const Game(
            squares: [0x80080080, 0x40008000, 0x20000808, 0x08040000, 0x04004044, 0x02000400, 0x00820002, 0x00402000, 0x00200220],
            verbs: ['steals', 'wins', 'takes', 'conquers',],
            adverbs: ['the top row', 'the middle row', 'the bottom row', 'the left column', 'the central longitude!', 'the right column', 'the diagonal', 'the diagonal!'],
          ),
        ),
      ),
    );
  }
}