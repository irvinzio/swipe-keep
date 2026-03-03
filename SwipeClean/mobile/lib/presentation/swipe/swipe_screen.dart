import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../domain/usecases/auth_usecases.dart';

class SwipeScreen extends StatefulWidget {
  final AuthUseCases authUseCases;

  const SwipeScreen({super.key, required this.authUseCases});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  final List<AssetEntity> _assets = [];
  final List<_HistoryAction> _history = [];
  bool _loading = true;
  int _processed = 0;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      await openAppSettings();
      setState(() => _loading = false);
      return;
    }

    final paths = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (paths.isNotEmpty) {
      final photos = await paths.first.getAssetListPaged(page: 0, size: 200);
      photos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
      _assets
        ..clear()
        ..addAll(photos);
    }

    setState(() => _loading = false);
  }

  Future<bool> _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) async {
    final asset = _assets[previousIndex];
    if (direction == CardSwiperDirection.left) {
      await asset.delete();
      _history.add(_HistoryAction(asset: asset, action: SwipeAction.delete));
    } else if (direction == CardSwiperDirection.right) {
      final keptAlbum = await _getOrCreateKeptAlbum();
      if (keptAlbum != null) {
        await PhotoManager.editor.copyAssetToPath(asset: asset, pathEntity: keptAlbum);
      }
      _history.add(_HistoryAction(asset: asset, action: SwipeAction.keep));
    } else {
      return false;
    }

    setState(() => _processed++);
    return true;
  }

  Future<AssetPathEntity?> _getOrCreateKeptAlbum() async {
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image, hasAll: false);
    for (final album in albums) {
      if (album.name == 'SwipeClean - Kept') return album;
    }
    if (Platform.isAndroid) {
      return PhotoManager.editor.android.createAlbum('SwipeClean - Kept');
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return PhotoManager.editor.darwin.createAlbum('SwipeClean - Kept');
    }
    return null;
  }

  Future<void> _undo() async {
    if (_history.isEmpty) return;
    _history.removeLast();
    _swiperController.undo();
    setState(() {
      if (_processed > 0) _processed--;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_assets.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('SwipeClean')),
        body: const Center(child: Text('No photos available.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('SwipeClean ($_processed/${_assets.length})'),
        actions: [
          IconButton(onPressed: _undo, icon: const Icon(Icons.undo)),
        ],
      ),
      body: CardSwiper(
        controller: _swiperController,
        cardsCount: _assets.length,
        onSwipe: _onSwipe,
        cardBuilder: (context, index, h, v) {
          return FutureBuilder<Uint8List?>(
            future: _assets[index].thumbnailDataWithSize(const ThumbnailSize(600, 600)),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(snapshot.data!, fit: BoxFit.cover),
              );
            },
          );
        },
      ),
    );
  }
}

enum SwipeAction { keep, delete }

class _HistoryAction {
  final AssetEntity asset;
  final SwipeAction action;

  _HistoryAction({required this.asset, required this.action});
}
