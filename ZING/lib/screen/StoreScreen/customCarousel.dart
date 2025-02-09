import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../Modal/CoustomUser.dart';
import '../../Service/StoreProvider.dart';

class CustomCarousel extends StatefulWidget {
  final Store store;
  final Function(int) onPageChanged;

  CustomCarousel({
    required this.store,
    required this.onPageChanged,
  });

  @override
  _CustomCarouselState createState() => _CustomCarouselState();
}

class _CustomCarouselState extends State<CustomCarousel> {
  int _currentIndex = 0;
  List<YoutubePlayerController>? _youtubeControllers;
  Store? _store;

  @override
  void initState() {
    super.initState();
    _fetchStoreData();
  }

  Future<void> _fetchStoreData() async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    Store? fetchedStore = await storeProvider.fetchStore(widget.store.id!);

    if (fetchedStore != null && fetchedStore.videos != null) {
      setState(() {
        _store = fetchedStore;
        _youtubeControllers = _store!.videos!.map((video) {
          final videoId = YoutubePlayer.convertUrlToId(video.url);
          return YoutubePlayerController(
            initialVideoId: videoId ?? '',
            flags: const YoutubePlayerFlags(autoPlay: false, showLiveFullscreenButton: false),
          );
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    if (_youtubeControllers != null) {
      for (var controller in _youtubeControllers!) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_store == null || _youtubeControllers == null) {
      return SafeArea(
        child: Center(
          child: Spin(
            duration: Duration(seconds: 1),
            child: const CircularProgressIndicator(color: Colors.blue),
          ),
        ),
      );
    }

    List<String> mediaUrls = [
      widget.store.imageUrl,
      ..._store!.videos!.map((video) => video.url),
    ];

    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.black87],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Column(
          children: [
            // Carousel
            FadeInUp(
              duration: Duration(milliseconds: 800),
              child: CarouselSlider.builder(
                itemCount: mediaUrls.length,
                itemBuilder: (context, index, realIndex) {
                  String url = mediaUrls[index];

                  if (index == 0) {
                    // First slide: Store image
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(15.0),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/images/loading.jpg',
                        image: url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    );
                  } else if (_youtubeControllers != null && index - 1 < _youtubeControllers!.length) {
                    return ZoomIn(
                      duration: Duration(milliseconds: 800),
                      child: YoutubePlayerBuilder(
                        player: YoutubePlayer(
                          controller: _youtubeControllers![index - 1],
                          showVideoProgressIndicator: true,
                          progressColors: const ProgressBarColors(
                            playedColor: Colors.red,
                            handleColor: Colors.redAccent,
                          ),
                          onReady: () {
                            // Automatically handle fullscreen when needed
                          },
                        ),
                        builder: (context, player) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  spreadRadius: 3,
                                  blurRadius: 7,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15.0),
                              child: Stack(
                                children: [
                                  player,
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  } else {
                    return const SizedBox();
                  }
                },
                options: CarouselOptions(
                  height: 250.0,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentIndex = index;
                    });
                    widget.onPageChanged(index);
                  },
                ),
              ),
            ),
            const SizedBox(height: 15),
            FadeIn(
              duration: Duration(milliseconds: 800),
              child: _buildPageIndicator(mediaUrls.length),
            ),
          ],
        ),
      ],
    );
  }

  // Page indicator
  Widget _buildPageIndicator(int itemCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        itemCount,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: _currentIndex == index ? 12.0 : 8.0,
          height: _currentIndex == index ? 12.0 : 8.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentIndex == index ? Colors.blueAccent : Colors.grey,
            boxShadow: [
              if (_currentIndex == index)
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.5),
                  spreadRadius: 3,
                  blurRadius: 7,
                ),
            ],
          ),
        ),
      ),
    );
  }
}