import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:animate_do/animate_do.dart';
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
  late PageController _pageController;
  List<YoutubePlayerController>? _youtubeControllers;
  Store? _store;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
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
    _pageController.dispose();
    if (_youtubeControllers != null) {
      for (var controller in _youtubeControllers!) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _slideToNext() {
    if (_currentIndex < (_youtubeControllers?.length ?? 0)) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _slideToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_store == null || _youtubeControllers == null) {
      return Center(
        child: Spin(
          duration: Duration(seconds: 1),
          child: const CircularProgressIndicator(color: Colors.blue),
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
              child: Container(
                height: 250.0,
                margin: const EdgeInsets.symmetric(horizontal: 10.0),
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                    widget.onPageChanged(index);
                  },
                  itemCount: mediaUrls.length,
                  itemBuilder: (context, index) {
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
                                child: player,
                              ),
                            );
                          },
                        ),
                      );
                    } else {
                      return const SizedBox();
                    }
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
        // Navigation Buttons (Previous)
        Positioned(
          left: 10,
          top: 100,
          child: FadeInLeft(
            duration: Duration(milliseconds: 800),
            child: InkWell(
              onTap: _slideToPrevious,
              child: _buildNavButton(Icons.arrow_back_ios),
            ),
          ),
        ),
        // Navigation Buttons (Next)
        Positioned(
          right: 10,
          top: 100,
          child: FadeInRight(
            duration: Duration(milliseconds: 800),
            child: InkWell(
              onTap: _slideToNext,
              child: _buildNavButton(Icons.arrow_forward_ios),
            ),
          ),
        ),
      ],
    );
  }

  // Navigation button
  Widget _buildNavButton(IconData icon) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
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