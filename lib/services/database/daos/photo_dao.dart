import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'photo_dao.g.dart';

@DriftAccessor(tables: [PhotosTable])
class PhotoDao extends DatabaseAccessor<AppDatabase> with _$PhotoDaoMixin {
  PhotoDao(super.db);

  Future<List<PhotosTableData>> getAllPhotos() => select(photosTable).get();

  Future<PhotosTableData> getPhotoById(int id) {
    return (select(photosTable)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<int> insertPhoto(PhotosTableCompanion photo) =>
      into(photosTable).insert(photo);

  Future<bool> updatePhoto(PhotosTableCompanion photo) =>
      update(photosTable).replace(photo);

  Future<int> deletePhoto(int id) {
    return (delete(photosTable)..where((t) => t.id.equals(id))).go();
  }
}
