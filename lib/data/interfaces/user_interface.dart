class UserInterface {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final Function deleteAccount;

  UserInterface(this.uid, {this.displayName, this.email, this.photoURL, required this.deleteAccount});
}
