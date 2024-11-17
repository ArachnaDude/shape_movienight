import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(
    ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MovieNight',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // home param sets the page we see when the app starts
      home: const MovieList(title: 'MovieNight'),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var favouriteMovies = [];
}

class MovieList extends StatefulWidget {
  const MovieList({super.key, required this.title});

  final String title;

  @override
  State<MovieList> createState() => _MovieListState();
}

class _MovieListState extends State<MovieList> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;

    switch (selectedIndex) {
      case 0:
        page = const Placeholder();
        break;
      case 1:
        page = const FavouritesPage();
        break;
      default:
        throw UnimplementedError('No widget for $selectedIndex');
    }

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: true,
              backgroundColor: const Color.fromARGB(255, 54, 53, 53),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.theaters),
                  label: Text("Movie List"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bookmark),
                  label: Text("Favourites"),
                ),
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  selectedIndex = index;
                });
              },
            ),
          ),
          Expanded(
            child: page,
          ),
        ],
      ),
    );
  }
}

class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    // If favouriteMovies is empty, show the message: "List is Empty"
    if (appState.favouriteMovies.isEmpty) {
      return const Center(
        child:
            Text("List is Empty"), // Showing a message when the list is empty
      );
    }

    // If favouriteMovies is not empty, show "Not Empty"
    return const Center(
      child: Text("Not Empty"), // This shows when the list is not empty
    );
  }
}
