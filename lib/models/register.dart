
class Register {
  String firstName;
  String lastName;
  String email;
  String gender;
  String country;
  String password;
  String passwordConfirmation;
  bool publicEmail = false;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['firstName'] = this.firstName;
    data['lastName'] = this.lastName;
    data['email'] = this.email;
    data['gender'] = this.gender;
    data['password'] = this.password;
    data['password_confirmation'] = this.passwordConfirmation;
    data['public_email'] = this.publicEmail;
    data['email'] = this.email;
    return data;
  }
}
