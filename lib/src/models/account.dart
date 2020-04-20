class Account {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final int projectId;

  Account(this.id, this.firstName, this.lastName, this.email, this.password, this.projectId);

  factory Account.fromDatabase(List<dynamic> data) {
    return Account(data[0] as int, data[1] as String, data[2] as String, data[3] as String, data[4] as String, data[5] as int);
  }

  @override
  String toString() => 'Account{ $id, $firstName, $lastName, $email, $password, $projectId }';
}
