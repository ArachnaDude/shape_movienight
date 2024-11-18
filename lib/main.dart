import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:http/http.dart" as http;
import "dart:convert";

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(
    // have to wrap the entire application in change notifier provider
    // in order for the context to be accessible by everything else
    ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "MovieNight",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // home param sets the page we see when the app starts
      home: const MovieList(title: "MovieNight"),
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

class Movie {
  final String title;
  final String year;
  final String posterUrl;

  Movie({required this.title, required this.year, required this.posterUrl});
}

class MovieSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final Function onClear;

  const MovieSearchBar({
    super.key,
    required this.onSearch,
    required this.onClear,
  });

  @override
  _MovieSearchBarState createState() => _MovieSearchBarState();
}

class _MovieSearchBarState extends State<MovieSearchBar> {
  final TextEditingController _controller = TextEditingController();

  void handleSubmit(String query) {
    query = query.trim(); // Ensure no extra spaces
    if (query.isNotEmpty) {
      widget.onSearch(query); // Call the parent's onSearch function
    }
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      hintText: 'Search for a movie...',
      leading: const Icon(Icons.search),
      controller: _controller,
      onSubmitted: handleSubmit,
    );
  }
}

class MovieSearchResults extends StatelessWidget {
  final bool isLoading;
  final List<Movie> movieList;

  const MovieSearchResults({
    super.key,
    required this.isLoading,
    required this.movieList,
  });

  @override
  Widget build(BuildContext context) {
    // Show loading indicator
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show "Search for a movie" if no movies are found
    if (movieList.isEmpty) {
      return const Center(
        child: Text("Search for a movie"),
      );
    }

    // Show the list of movie cards if movies are found
    return Expanded(
      child: ListView.builder(
        itemCount: movieList.length,
        itemBuilder: (context, index) {
          var movie = movieList[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Image.network(
                movie.posterUrl,
                width: 50,
                height: 75,
                fit: BoxFit.cover,
              ),
              title: Text(movie.title),
              subtitle: Text(movie.year),
              onTap: () {
                // Handle card tap (e.g., show movie details)
                print("Tapped on ${movie.title}");
              },
            ),
          );
        },
      ),
    );
  }
}

class _MovieListState extends State<MovieList> {
  int selectedIndex = 0;
  String searchQuery = "";
  bool isLoading = false;
  List<Movie> movieList = [];

  Future<void> fetchMovies(String query) async {
    if (query.isEmpty) {
      setState(() {
        movieList = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url =
        "http://www.omdbapi.com/?apikey=${dotenv.env['OMDB_API_KEY']}&type=movie&s=$query";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["Response"] == "True") {
        movieList = (data["Search"] as List)
            .map((movie) => Movie(
                  title: movie["Title"],
                  year: movie["Year"],
                  posterUrl: movie["Poster"],
                ))
            .toList();
      } else {
        movieList = [];
      }
    } else {
      movieList = [];
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget movieListPage = Column(
      children: [
        MovieSearchBar(
          onSearch: fetchMovies,
          onClear: () {
            setState(() {
              searchQuery = "";
              movieList = [];
            });
          },
        ),
        MovieSearchResults(
          isLoading: isLoading,
          movieList: movieList,
        ),
      ],
    );

    // Define the page layout for the Favourites page
    Widget favouritesPage = const FavouritesPage();

    Widget page;

    // Switch between Movie List page and Favourites page
    switch (selectedIndex) {
      case 0:
        page = movieListPage;
        break;
      case 1:
        page = favouritesPage;
        break;
      default:
        throw UnimplementedError("No widget for $selectedIndex");
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: const [],
      ),
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
                  label: Text("My Watch List"),
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

    if (appState.favouriteMovies.isEmpty) {
      return const Center(
        child: Text(
          "It's looking pretty empty here...\nTry adding movies from the Movie List page to build your watch list.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView(
      children: const [
        Padding(
          padding: EdgeInsets.all(20),
        ),
      ],
    );
  }
}
