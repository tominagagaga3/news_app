import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF6F6F6),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    ),
      home: const NewsListPage(),
    );
  }
}

class Article {
  final String title;
  final String? description;
  final String? imageUrl;
  final String? url;
  final String? sourceName;

  Article({
    required this.title,
    this.description,
    this.imageUrl,
    this.url,
    this.sourceName,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: (json["title"] ?? "") as String,
      description: json["description"] as String?,
      imageUrl: json["urlToImage"] as String?,
      url: json["url"] as String?,
      sourceName: (json["source"]?["name"]) as String?,
    );
  }
}

class NewsApi {
  static Future<List<Article>> fetchTopHeadlines() async {
final uri = Uri(
  path: "/api/news",
  queryParameters: {
    "category": "technology",
    "language": "en", 
    "pageSize": "20",
    "page": "1",
  },
);

  final res = await http.get(uri);
  debugPrint("STATUS: ${res.statusCode}");
  debugPrint("BODY (head): ${res.body.substring(0, res.body.length > 300 ? 300 : res.body.length)}");

  if (res.statusCode != 200) {
    throw Exception("HTTP ${res.statusCode}: ${res.body}");
  }

  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (data["status"] != "ok") {
    throw Exception("API error: ${data["message"]}");
  }

  final articlesJson = (data["articles"] as List).cast<Map<String, dynamic>>();
  return articlesJson.map(Article.fromJson).toList();
}
}

class NewsListPage extends StatefulWidget {
  const NewsListPage({super.key});

  @override
  State<NewsListPage> createState() => _NewsListPageState();
}

class _NewsListPageState extends State<NewsListPage> {
  late Future<List<Article>> _future;

  @override
  void initState() {
    super.initState();
    _future = NewsApi.fetchTopHeadlines();
  }

    Widget _articleTile(BuildContext context, Article a) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final link = a.url;
        if (link == null) return;

        final uri = Uri.parse(link);

        final ok = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('リンクを開けませんでした')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
          color: Colors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (a.imageUrl != null && a.imageUrl!.isNotEmpty)
                  ? Image.network(
                      a.imageUrl!,
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 92,
                        height: 92,
                        alignment: Alignment.center,
                        color: Colors.black12,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      width: 92,
                      height: 92,
                      alignment: Alignment.center,
                      color: Colors.black12,
                      child: const Icon(Icons.article),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if ((a.sourceName ?? "").isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.black12,
                          ),
                          child: Text(
                            a.sourceName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const Spacer(),
                      const Icon(Icons.open_in_new,
                          size: 18, color: Colors.black54),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 210, 235, 255),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF4A90E2),
                Color.fromARGB(255, 118, 189, 221),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Tech News",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<Article>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "エラー:\n${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final articles = snapshot.data ?? [];
          if (articles.isEmpty) {
            return const Center(child: Text("記事がありません"));
          }

          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, i) {
              final a = articles[i];
              return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _articleTile(context, a),
    );
  },
);
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 35, 115, 190),
        onPressed: () {
          setState(() {
            _future = NewsApi.fetchTopHeadlines();
          });
        },
       child: const Icon(
        Icons.refresh,
        color: Colors.white,
      ),
      ),
    );
  }
}

