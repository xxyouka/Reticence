import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'connection_dao.g.dart';

@DriftAccessor(tables: [ConnectionsTable])
class ConnectionDao extends DatabaseAccessor<AppDatabase>
    with _$ConnectionDaoMixin {
  ConnectionDao(super.db);

  Future<List<ConnectionsTableData>> getAllConnections() =>
      select(connectionsTable).get();

  Future<List<ConnectionsTableData>> getConnectionsForCard(int cardId) {
    return (select(connectionsTable)
          ..where(
              (t) => t.fromCardId.equals(cardId) | t.toCardId.equals(cardId)))
        .get();
  }

  Future<List<ConnectionsTableData>> getConnectionsForPhoto(int photoId) {
    return (select(connectionsTable)
          ..where((t) =>
              t.fromPhotoId.equals(photoId) | t.toPhotoId.equals(photoId)))
        .get();
  }

  Future<int> insertConnection(ConnectionsTableCompanion connection) =>
      into(connectionsTable).insert(connection);

  Future<bool> updateConnection(ConnectionsTableCompanion connection) =>
      update(connectionsTable).replace(connection);

  Future<int> deleteConnection(int id) {
    return (delete(connectionsTable)..where((t) => t.id.equals(id))).go();
  }
}
