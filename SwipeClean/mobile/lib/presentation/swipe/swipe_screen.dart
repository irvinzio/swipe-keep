import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../core/storage/photo_app_preference_storage.dart';
import '../../domain/entities/photo_action_app.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'photo_app_picker_dialog.dart';

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
  final PhotoAppPreferenceStorage _preferenceStorage = PhotoAppPreferenceStorage();

  bool _loading = true;
  int _processed = 0;
  PhotoActionApp _selectedPhotoApp = PhotoActionApp.systemPhotos;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadPhotoAppPreference();
    await _loadPhotos();

    if (!mounted) return;

    final hasShownPrompt = await _preferenceStorage.hasShownPrompt();
    if (!hasShownPrompt) {
      await _openPhotoAppPicker(isFirstLoginPrompt: true);
    }
  }

  Future<void> _loadPhotoAppPreference() async {
    final preferred = await _preferenceStorage.readPreferredApp();
    if (preferred != null) {
      setState(() => _selectedPhotoApp = preferred);
    }
  }

  Future<void> _openPhotoAppPicker({bool isFirstLoginPrompt = false}) async {
    final selected = await showDialog<PhotoActionApp>(
      context: context,
      barrierDismissible: !isFirstLoginPrompt,
      builder: (_) => PhotoAppPickerDialog(initialValue: _selectedPhotoApp),
    );

    if (selected != null) {
      await _preferenceStorage.savePreferredApp(selected);
      await _preferenceStorage.markPromptAsShown();
      if (!mounted) return;
      setState(() => _selectedPhotoApp = selected);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo action app updated: ${selected.label}')),
      );
      return;
    }

    if (isFirstLoginPrompt) {
      await _preferenceStorage.savePreferredApp(_selectedPhotoApp);
      await _preferenceStorage.markPromptAsShown();
    }
  }

  Future<void> _loadPhotos() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      await openAppSettings();
      if (!mounted) return;
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

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<bool> _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) async {
    final asset = _assets[previousIndex];
    if (direction == CardSwiperDirection.left) {
      await asset.delete();
      _history.add(_HistoryAction(asset: asset, action: SwipeAction.delete));
      _showActionMessage('Deleted using ${_selectedPhotoApp.label} preference');
    } else if (direction == CardSwiperDirection.right) {
      final keptAlbum = await _getOrCreateKeptAlbum();
      if (keptAlbum != null) {
        await PhotoManager.editor.copyAssetToPath(asset: asset, pathEntity: keptAlbum);
      }
      _history.add(_HistoryAction(asset: asset, action: SwipeAction.keep));
      _showActionMessage('Kept using ${_selectedPhotoApp.label} preference');
    } else {
      return false;
    }

    setState(() => _processed++);
    return true;
  }

  void _showActionMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(duration: const Duration(milliseconds: 900), content: Text(text)),
    );
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
          IconButton(
            tooltip: 'Change photo action app',
            onPressed: _openPhotoAppPicker,
            icon: const Icon(Icons.settings),
          ),
          IconButton(onPressed: _undo, icon: const Icon(Icons.undo)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Photo action app: ${_selectedPhotoApp.label}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
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
