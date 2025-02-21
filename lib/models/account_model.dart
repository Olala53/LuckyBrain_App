import 'package:hive/hive.dart';

part 'account_model.g.dart';

@HiveType(typeId: 0)
class Account extends HiveObject {
  Account({
    required this.name,
    required this.surname,
    required this.birthdate,
  });

  @HiveField(0)
  final String name;

  @HiveField(1)
  final String surname;

  @HiveField(2)
  final String birthdate;
}
