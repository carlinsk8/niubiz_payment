/// A model class representing the configuration for Niubiz.
///
/// This class holds the necessary information to configure the Niubiz payment
/// gateway, including user credentials, merchant details, and environment settings.
class NiubizConfigModel {
  /// The username for authentication.
  final String? userName;

  /// The password for authentication.
  final String? password;

  /// The merchant ID associated with the Niubiz account.
  final String? merchantId;

  /// A flag indicating whether the configuration is for the production environment.
  ///
  /// Defaults to `false`, indicating a non-production (e.g., testing) environment.
  final bool? isProduction;

  /// The title of the brand.
  final String? titleBrand;

  /// The first name of the user.
  final String? name;

  /// The last name of the user.
  final String? lastName;

  /// The email address of the user.
  final String? email;

  /// Creates a new instance of [NiubizConfigModel].
  ///
  /// All parameters are optional. If not provided, `isProduction` defaults to `false`.
  NiubizConfigModel({
    this.userName,
    this.password,
    this.merchantId,
    this.isProduction = false,
    this.titleBrand,
    this.name,
    this.lastName,
    this.email,
  });

  /// Converts the [NiubizConfigModel] instance to a map.
  ///
  /// Returns a map representation of the instance, with keys corresponding to
  /// the field names and values corresponding to the field values.
  Map<String, dynamic> toMap() {
    return {
      "userName": userName,
      "password": password,
      "merchantId": merchantId,
      "isProduction": isProduction,
      "titleBrand": titleBrand,
      "name": name,
      "lastName": lastName,
      "email": email,
    };
  }
}

