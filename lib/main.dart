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

  void addFavourite(Movie movie) {
    if (!favouriteMovies.contains(movie)) {
      favouriteMovies.add(movie);
      notifyListeners();
    }
  }

  void removeFavourite(Movie movie) {
    favouriteMovies.remove(movie);
    notifyListeners();
  }
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
  final String imdbID;

  Movie({
    required this.title,
    required this.year,
    required this.posterUrl,
    required this.imdbID,
  });
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
    query = query.trim();
    if (query.isNotEmpty) {
      widget.onSearch(query);
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (movieList.isEmpty) {
      return const Center(
        child: Text("Search for a movie"),
      );
    }

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MovieDetailsPage(movie: movie),
                  ),
                );
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
                  imdbID: movie["imdbID"],
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

    Widget favouritesPage = const FavouritesPage();

    Widget page;

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

class MovieDetailsPage extends StatefulWidget {
  final Movie movie;

  const MovieDetailsPage({super.key, required this.movie});

  @override
  _MovieDetailsPageState createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  bool isLoading = true;
  String plot = '';
  String director = '';
  String actors = '';
  String imdbRating = '';
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    fetchMovieDetails(widget.movie.imdbID);
    checkIfFavorite();
  }

  // Check if the movie is already in the favorites list
  void checkIfFavorite() {
    var appState = context.read<MyAppState>();
    setState(() {
      isFavorite = appState.favouriteMovies.contains(widget.movie);
    });
  }

  Future<void> fetchMovieDetails(String imdbID) async {
    final url =
        "http://www.omdbapi.com/?apikey=${dotenv.env['OMDB_API_KEY']}&i=$imdbID";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        plot = data['Plot'] ?? 'No plot available';
        director = data['Director'] ?? 'No director available';
        actors = data['Actors'] ?? 'No actors available';
        imdbRating = data['imdbRating'] ?? 'No rating available';
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movie.title),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.network(
                      widget.movie.posterUrl,
                      width: 250,
                      height: 380,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.movie.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          var appState = context.read<MyAppState>();
                          setState(() {
                            if (isFavorite) {
                              appState.favouriteMovies.remove(widget.movie);
                            } else {
                              appState.favouriteMovies.add(widget.movie);
                            }

                            isFavorite = !isFavorite;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Release Year: ${widget.movie.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    plot,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Directed by $director",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Actors: $actors",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "IMDB rating: $imdbRating",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
    );
  }
}

class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var favouriteMovies = appState.favouriteMovies;

    if (favouriteMovies.isEmpty) {
      return const Center(
        child: Text(
          "It's looking pretty empty here...\nTry adding movies from the Movie List page to build your watch list.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      itemCount: favouriteMovies.length,
      itemBuilder: (context, index) {
        var movie = favouriteMovies[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: Image.network(
              movie.posterUrl,
              width: 50,
              height: 75,
              fit: BoxFit.cover,
            ),
            title: Text(movie.title),
            subtitle: Text(movie.year),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: () {
                appState.removeFavourite(movie);
              },
            ),
          ),
        );
      },
    );
  }
}
