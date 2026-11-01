import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'card_dao.g.dart';

@DriftAccessor(tables: [CardsTable])
class CardDao extends DatabaseAccessor<AppDatabase> with _$CardDaoMixin {
  CardDao(super.db);

  Future<List<CardsTableData>> getAllCards() => select(cardsTable).get();

  Future<CardsTableData> getCardById(int id) {
    return (select(cardsTable)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<int> insertCard(CardsTableCompanion card) =>
      into(cardsTable).insert(card);

  Future<bool> updateCard(CardsTableCompanion card) =>
      update(cardsTable).replace(card);

  Future<int> deleteCard(int id) {
    return (delete(cardsTable)..where((t) => t.id.equals(id))).go();
  }
}
