enum PhotoActionApp {
  systemPhotos,
  googlePhotos,
  files,
  gallery,
}

extension PhotoActionAppX on PhotoActionApp {
  String get label {
    switch (this) {
      case PhotoActionApp.systemPhotos:
        return 'System Photos';
      case PhotoActionApp.googlePhotos:
        return 'Google Photos';
      case PhotoActionApp.files:
        return 'Files';
      case PhotoActionApp.gallery:
        return 'Gallery';
    }
  }

  String get value {
    switch (this) {
      case PhotoActionApp.systemPhotos:
        return 'system_photos';
      case PhotoActionApp.googlePhotos:
        return 'google_photos';
      case PhotoActionApp.files:
        return 'files';
      case PhotoActionApp.gallery:
        return 'gallery';
    }
  }

  static PhotoActionApp fromValue(String value) {
    return PhotoActionApp.values.firstWhere(
      (app) => app.value == value,
      orElse: () => PhotoActionApp.systemPhotos,
    );
  }
}
