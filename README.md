# MovieNight

Are you ready for your next movie night? Browse movies, see details about them, and save them to a watch list to make sure your next movie night goes with a bang!

## Description:

This project utilises Flutter, and the Open Movie Database (OMDb) REST API to search for, and display movies. The user can search for a movie title via the search bar on the main screen of the application, which performs an HTTP GET request to the OMDb REST API. The user can see further details about the movies they find, and save them to, and subsequently remove them from a Favourites list.

As the application was developed on Linux, it was developed for Linux, however it can be run in a Chrome browser as well.

## Installation:

### Prerequisites:

- Flutter SDK ^3.5.4
- an OMDb API key (this can be obtained at [this link](https://www.omdbapi.com/apikey.aspx):)

### Local running:

Clone the repository to your machine:

```
$ git clone https://github.com/ArachnaDude/shape_movienight.git
$ cd shape_movienight
```

The project uses the following external packages:

- `http` - This package handles http requests
- `provider` - This package contributes to state management
- `flutter_dotenv` - This package provides environment variable functionality to obscure sensitive data.

Install these packages by running:

```
$ flutter pub get
```

In order to protect sensitive data such as API keys, they can be hidden in `.env` files. In order to set up your `.env` file to run this project locally, make sure you're in the root of the project, and run the following commands:

```
$ touch .env
$ echo OMDB_API_KEY=<YOUR KEY HERE> > .env
```

Substite in your own API key to the marked area before executing this command.

You are now ready to run the project locally.

## Usage:

Start the project by clicking the `run and debug` button in VSCode, or by running:

```
$ flutter run
```

in your terminal.

## Observations and improvements:

This has been a challenging project to accomplish in a relatively short period of time. Getting to grips with concepts like the OOP-centric nature of Flutter, its strong, static typing, and new conventions in naming, such as using underscores to signify deliberately unused parameters in functions, has been a steep learning curve.

Given a longer period of time to become acquinted with Flutter and by extension Dart, there are a number of improvenemts that could be made to this project. These include:

- **Introducing pagination**: If the API returns a large number of results, the application can become unstable.

- **Abstracting components**: As the application grows in complexity, abstracting components and processes to their own files would be advantageous in keeping the complexity more managable.

- **More Advanced Error handling**: While functional, the error handling from the API side of things is basic, currently being split into "status code 200" and "everything else".
