class SupportContacts {
  static const email = 'sscienceworld2027@gmail.com';
  static const whatsappPhone = '+90 5389567265';
  static const whatsappUrl = 'https://wa.me/905389567265';
  static const instagramUrl =
      'https://www.instagram.com/science._.world2027?cplk=MXRrdDV0MmlmaWkxZg==';

  static Uri emailUri({required String subject, String body = ''}) {
    return Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        if (body.isNotEmpty) 'body': body,
      },
    );
  }
}
