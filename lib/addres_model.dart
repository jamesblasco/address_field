class Address {
  final String line1, line2, city, state, postalCode, country, text;

  const Address({
    this.line1 = '',
    this.line2 = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.country = '',
    String? text,
  }) : this.text = text ?? '$line1, $postalCode $city, $state, $country';

  const Address.empty()
      : this.line1 = '',
        this.line2 = '',
        this.city = '',
        this.state = '',
        this.postalCode = '',
        this.country = '',
        this.text = '';

  bool get isEmpty {
    return line1.isEmpty &&
        line2.isEmpty &&
        city.isEmpty &&
        state.isEmpty &&
        postalCode.isEmpty &&
        country.isEmpty;
  }

  Map<String, String> toJson() => {
        'address': line1,
        'address2': line2,
        'city': city,
        'state': state,
        'postcode': postalCode,
        'country': country,
      };

  @override
  String toString() => '$line1, $line2, $city, $state, $postalCode, $country';
}