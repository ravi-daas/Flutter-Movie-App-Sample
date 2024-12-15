import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
    return Scaffold(
      body: Center(
        child: Image.network(
            'https://yt3.googleusercontent.com/g_bEA4DiQjWzCdRluwELXUOZ4zWelOaz_sFb61X6S2swcVTuGevoD1v-MDFZ0WS44IZ4zjNPEg=s900-c-k-c0x00ffffff-no-rj'),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List movies = [];

  @override
  void initState() {
    super.initState();
    // fetchMovies();
  }

  Future<List<Map<String, dynamic>>> fetchMovies() async {
    final response =
        await http.get(Uri.parse('https://api.tvmaze.com/search/shows?q=all'));
    if (response.statusCode == 200) {
      // print('61 inside if status 200');

      List<dynamic> moviesData = jsonDecode(response.body);

      List<Map<String, dynamic>> moviesList = [];

      for (var record in moviesData) {
        final image = record['show']['image'];
        Map<String, dynamic> movieRecord = {
          'name': record['show']['name'],
          'language': record['show']['language'],
          'rating': record['show']['rating']['average'],
          'summary': record['show']['summary'],
        };

        // Add the 'Image' key only if 'image' is not null
        if (image != null) {
          movieRecord['image'] = image['medium'];
        }

        // print(movieRecord);

        // Add the record to the list
        moviesList.add(movieRecord);
      }
      return moviesList;
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
          ),
        ],
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchMovies(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator();
          } else if (snapshot.hasError) {
            String errorMsg = snapshot.error.toString();
            if (errorMsg == 'Nothing') {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Text(
                        'No data returned from the server(ERP). Why does this happen?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Possible reasons:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'No Classes on ERP\n',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Try:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '1) Check ERP\n'
                        '2) Restart the app\n'
                        '3) If the problem persists, let us know by going to the App Menu > Report a Problem',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return const Center(
                child: Text(
                    'Error: Some Error occurred while Fetching, please Restart the App.'),
              );
            }
          } else {
            List<Map<String, dynamic>> movies = snapshot.data!;

            return ListView.builder(
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                return SizedBox(
                  height: 120, // Set a fixed height for each ListTile
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      leading: movie['image'] != null
                          ? Image.network(
                              movie['image'], // Movie image URL
                              width: 60,
                              fit: BoxFit.cover,
                            )
                          : const SizedBox(
                              width: 60,
                              child: Icon(Icons.image,
                                  size: 60), // Placeholder image
                            ),
                      title: Text(
                        movie['name'] ?? 'No Title', // Movie title
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, // Truncate long titles
                      ),
                      subtitle: Text(
                        movie['summary'] != null
                            ? movie['summary'].replaceAll(
                                RegExp(r'<[^>]*>'), '') // Clean HTML tags
                            : 'No summary available',
                        maxLines: 3, // Limit summary to 3 lines
                        overflow:
                            TextOverflow.ellipsis, // Truncate if it overflows
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsScreen(
                                movie: movie), // Navigate to Details Screen
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        ],
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchScreen()),
            );
          }
        },
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List searchResults = [];
  TextEditingController searchController = TextEditingController();

  Future<void> searchMovies(String query) async {
    final response = await http
        .get(Uri.parse('https://api.tvmaze.com/search/shows?q=$query'));
    if (response.statusCode == 200) {
      setState(() {
        searchResults = json.decode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          decoration: InputDecoration(hintText: 'Search Movies...'),
          onSubmitted: (value) {
            searchMovies(value);
          },
        ),
      ),
      body: searchResults.isEmpty
          ? Center(child: Text('Search for movies'))
          : ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final movie = searchResults[index]['show'];
                return SizedBox(
                  height: 120, // Set a fixed height for each ListTile
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      leading: movie['image'] != null
                          ? Image.network(
                              movie['image']['medium'], // Movie image URL
                              width: 60,
                              fit: BoxFit.cover,
                            )
                          : const SizedBox(
                              width: 60,
                              child: Icon(Icons.image,
                                  size: 60), // Placeholder image
                            ),
                      title: Text(
                        movie['name'] ?? 'No Title', // Movie title
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, // Truncate long titles
                      ),
                      subtitle: Text(
                        movie['summary'] != null
                            ? movie['summary'].replaceAll(
                                RegExp(r'<[^>]*>'), '') // Clean HTML tags
                            : 'No summary available',
                        maxLines: 3, // Limit summary to 3 lines
                        overflow:
                            TextOverflow.ellipsis, // Truncate if it overflows
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsScreen(
                                movie: movie), // Navigate to Details Screen
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  final Map movie;

  DetailsScreen({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(movie['name'] ?? 'Movie Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            movie['image'] != null
                ? Image.network(movie['image'])
                : Container(height: 200, color: Colors.grey),
            SizedBox(height: 16),
            Text('Title: ${movie['name']}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('summary:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(movie['summary']?.replaceAll(RegExp('<[^>]*>'), '') ??
                'No Summary'),
          ],
        ),
      ),
    );
  }
}
