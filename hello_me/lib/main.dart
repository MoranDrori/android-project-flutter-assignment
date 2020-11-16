import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserRepository>(
        create: (_) => UserRepository.instance(),
        child: Consumer<UserRepository>(
            builder: (context, UserRepository user, _) {
          return MaterialApp(
            title: 'Startup Name Generator',
            theme: ThemeData(
              primaryColor: Colors.red,
            ),
            home: RandomWords(),
          );
        }));
  }
}

class RandomWords extends StatefulWidget {
  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final List<WordPair> _suggestions = <WordPair>[];
  final _saved = Set<WordPair>();
  final _deleted = Set<WordPair>();
  final TextStyle _biggerFont = const TextStyle(fontSize: 18);
  SnappingSheetController _controller = SnappingSheetController();
  File _image;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserRepository>(context);
//maybe sign out
    return Scaffold(
        appBar: AppBar(
          title: Text('Startup Name Generator'),
          actions: [
            IconButton(icon: Icon(Icons.list), onPressed: _pushSaved),
            user.status == Status.Authenticated
                ? IconButton(
                    icon: Icon(Icons.logout),
                    onPressed: () {
                      user.signOut();
                      _saved.clear();
                      _email='';
                      _password='';
                      _confirmPassword='';
                      user.url=null;
                    })
                : IconButton(icon: Icon(Icons.login), onPressed: _loginScreen)
          ],
        ),
        body: user.status == Status.Authenticated
            ? Builder(
                builder: (context) => SnappingSheet(
                      snappingSheetController: _controller,
                      snapPositions: [
                        SnapPosition(
                          positionPixel: 0.0,
                          snappingCurve: Curves.ease,
                        ),
                        SnapPosition(
                          positionPixel: 150,
                          snappingCurve: Curves.ease,
                        )
                      ],
                      sheetBelow: SnappingSheetContent(
                          child: ListView(children: [
                            Container(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child:  CircularProfileAvatar(
                                        null,
                                        child: user.url == null ? Icon(
                                          Icons.person,
                                          size: 30,
                                        ) : ClipRRect(
                                          borderRadius: BorderRadius.circular(50),
                                          child: Image.network(user.url,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.fitHeight,
                                          )
                                        ),
                                        borderColor: Colors.transparent,
                                        borderWidth: 3,
                                        elevation: 1,
                                        radius: 40,
                                      ),
                                      ),

                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          0, 10, 0, 0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(' $_email',
                                              style: TextStyle(
                                                fontSize: 22,
                                              )),
                                          ButtonBar(
                                            alignment: MainAxisAlignment.start,
                                            children: [
                                              FlatButton(
                                                child: Text('Change avatar',
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                                color: Colors.teal[800],
                                                minWidth: 120,
                                                height: 26,
                                                onPressed: () async {
                                                  FilePickerResult  _result = await FilePicker.platform.pickFiles();
                                                  File _imageTemp;
                                                  if(_result != null) {
                                                   _imageTemp = File(_result.files.single.path);
                                                  } else {
                                                    // User canceled the picker
                                                    final snackBar = SnackBar(
                                                      content: Text(
                                                          'No image selected'),
                                                    );
                                                    Scaffold.of(context)
                                                        .showSnackBar(snackBar);
                                                  }

                                                  await user._addPicture(_imageTemp);
                                                  await user._getURL();

                                                  setState(() {
                                                    _image = _imageTemp;

                                                  });


                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                          heightBehavior: SnappingSheetHeight.fit()),
                      sheetAbove:
                          SnappingSheetContent(child: _buildSuggestions()),
                      grabbingHeight: 50,
                      grabbing: Container(
                        child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text('Welcome back, $_email'),
                                        Icon(Icons.keyboard_arrow_up)
                                      ])),
                              onTap: () {
                                setState(() {
                                  if (_controller
                                          .currentSnapPosition.positionPixel ==
                                      0.0) {
                                    _controller.snapToPosition(
                                        _controller.snapPositions[1]);
                                  } else {
                                    _controller.snapToPosition(
                                        _controller.snapPositions[0]);
                                  }
                                });
                              },
                            )),
                        color: Colors.grey[400],
                      ),
                    ))
            : _buildSuggestions());
  }

  final _key = GlobalKey<ScaffoldState>();
  String _email;
  String _password;
  String _confirmPassword;
  TextEditingController _confirmPassController = TextEditingController();
  bool _validate=false;


  void _loginScreen() {
    _validate=false;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          final user = Provider.of<UserRepository>(context);
          return Scaffold(
            key: _key,
            appBar: AppBar(
              title: Text('Login'),
            ),
            body: Center(
              child: Column(
                children: <Widget>[
                  Text(' '),
                  Text('Welcome to the Startup Names Generator,',
                      textAlign: TextAlign.center),
                  Text('please log in below', textAlign: TextAlign.center),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 15, 16, 10),
                    child: TextField(
                      onChanged: (value) {
                        _email = value;
                      },
                      decoration: InputDecoration(labelText: 'Email'),
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 15),
                      child: TextField(
                        obscureText: true,
                        onChanged: (value) {
                          _password = value;
                        },
                        decoration: InputDecoration(labelText: 'Password'),
                      )),
                  user.status == Status.Authenticating
                      ? Center(child: CircularProgressIndicator())
                      : ButtonBar(
                          alignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Builder(
                              builder: (context) => FlatButton(
                                color: Colors.red,
                                textColor: Colors.white,
                                shape: StadiumBorder(),
                                minWidth: 300,
                                child: Text('Log in'),
                                onPressed: () async {
                                  if (!await user.signIn(_email, _password)) {
                                    final snackBar = SnackBar(
                                      content: Text(
                                          'There was an error logging into the app'),
                                    );
                                    _key.currentState.showSnackBar(snackBar);
                                  } else {
                                    Navigator.popUntil(
                                        _key.currentState.context,
                                        ModalRoute.withName('/'));
                                    await user._addDocUser();
                                    user._updateSavedDeletedListInLogin(
                                        _saved, _deleted);
                                    user._loadTheSaved(_saved, _suggestions);
                                    await user._getURL();
                                  }
                                },
                              ),
                            ),
                            Builder(
                              builder: (context) => FlatButton(
                                color: Colors.teal[700],
                                textColor: Colors.white,
                                shape: StadiumBorder(),
                                minWidth: 300,
                                child: Text('New user? Click to sign up'),
                                onPressed: () {
                                  showMaterialModalBottomSheet(
                                    context: context,
                                    builder: (context) => Padding(
                                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                      child: Container(
                                        height: 210,
                                        color: Colors.grey[100],
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(
                                                  0, 17, 0, 0),
                                              child: Text(
                                                'Please confirm your password below:',
                                                style: TextStyle(
                                                    color: Colors.grey[850]),
                                              ),
                                            ),
                                            Divider(
                                              color: Colors.grey[300],
                                              height: 20,
                                              thickness: 1,
                                              indent: 20,
                                              endIndent: 20,
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(
                                                  20, 0, 20, 10),
                                              child: TextField(
                                                controller: _confirmPassController,
                                                obscureText: true,
                                                onChanged: (value) {
                                                  _confirmPassword = value;
                                                },
                                                decoration: InputDecoration(
                                                    labelText: 'Password',
                                                    labelStyle:
                                                        TextStyle(fontSize: 14), errorText: _validate ? 'Passwords must match' : null,),
                                              ),
                                            ),
                                            ButtonBar(
                                              alignment: MainAxisAlignment.center,
                                              children: [
                                                FlatButton(
                                                    color: Colors.teal[700],
                                                    textColor: Colors.white,
                                                    minWidth: 80,
                                                    child: Text(
                                                        'Confirm'),
                                                    onPressed: () async {
                                                      //for keyboard disappear
                                                      FocusScope.of(context).requestFocus(FocusNode());
                                                      if(!await user._register(_email, _password, _confirmPassword)){
                                                         _validate = true;
                                                      } else {
                                                        _validate = false;
                                                        await user.signIn(_email, _password);
                                                        Navigator.popUntil(
                                                            _key.currentState.context,
                                                            ModalRoute.withName('/'));
                                                        await user._addDocUser();
                                                        user._updateSavedDeletedListInLogin(
                                                            _saved, _deleted);
                                                      }

                                                    })
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          final user = Provider.of<UserRepository>(context);
          return Scaffold(
            appBar: AppBar(
              title: Text('Saved Suggestions'),
            ),
            body: StatefulBuilder(
              builder: (context, setInnerState) => ListView(
                children: ListTile.divideTiles(
                  context: context,
                  tiles: _saved.map(
                    (WordPair pair) {
                      return ListTile(
                          title: Text(
                            pair.asPascalCase,
                            style: _biggerFont,
                          ),
                          trailing: Icon(
                            Icons.delete_outline_outlined,
                            color: Colors.red,
                          ),
                          onTap: () {
                            setInnerState(() {
                              _saved.remove(pair);
                              setState(() {});
                            });
                            if (user.status == Status.Authenticated) {
                              user._deleteUserSavedList(pair);
                            } else if (user.status == Status.Unauthenticated ||
                                user.status == Status.Uninitialized) {
                              _deleted.add(pair);
                            }
                          });
                    },
                  ),
                ).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_context, int i) {
          if (i.isOdd) {
            return Divider();
          }
          final int index = i ~/ 2;
          if (index >= _suggestions.length) {
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index]);
        });
  }

  Widget _buildRow(WordPair pair) {
    final user = Provider.of<UserRepository>(context);
    final alreadySaved = _saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
            if (user.status == Status.Authenticated) {
              user._deleteUserSavedList(pair);
            } else if (user.status == Status.Unauthenticated ||
                user.status == Status.Uninitialized) {
              if (!_deleted.contains(pair)) {
                _deleted.add(pair);
              }
            }
          } else {
            _saved.add(pair);
            if (user.status == Status.Authenticated) {
              user._addUserSavedList(pair);
            } else if (user.status == Status.Unauthenticated ||
                user.status == Status.Uninitialized) {
              if (_deleted.contains(pair)) {
                _deleted.remove(pair);
              }
            }
          }
        });
      },
    );
  }

}

enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class UserRepository with ChangeNotifier {
  FirebaseAuth _auth;
  User _user;
  Status _status = Status.Uninitialized;
  String url;

  UserRepository.instance() : _auth = FirebaseAuth.instance {
    _auth.authStateChanges().listen(_authStateChanges);
  }

  FirebaseStorage _storage = FirebaseStorage.instance;

  Status get status => _status;
  User get user => _user;

  Future<bool> _register(String email, String password, String confirmPass) async {
    if(password==null || confirmPass==null || password=='' || confirmPass==''){
      return false;
    }
    if(password!=confirmPass) {
      return false;
    }
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
        _status = Status.Authenticated;
        notifyListeners();
        return true;
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _status = Status.Authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future signOut() async {
    _auth.signOut();
    _status = Status.Unauthenticated;
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  Future<void> _authStateChanges(User firebaseUser) async {
    if (firebaseUser == null) {
      _status = Status.Unauthenticated; //not login
    } else {
      _user = firebaseUser;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }

  void _addUserSavedList(WordPair pair) {
    final User user = _auth.currentUser;
    final uid = user.uid;
    FirebaseFirestore.instance.collection('users').doc(uid.toString()).update({
      'SavedPairs': FieldValue.arrayUnion([pair.asPascalCase])
    });
  }

  void _deleteUserSavedList(WordPair pair) {
    final User user = _auth.currentUser;
    final uid = user.uid;
    FirebaseFirestore.instance.collection('users').doc(uid.toString()).update({
      'SavedPairs': FieldValue.arrayRemove([pair.asPascalCase])
    });
  }

  Future<void> _addDocUser() async {
    // Call the user's CollectionReference to add a new user
    final User user = _auth.currentUser;
    final uid = user.uid;

    var current = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid.toString())
        .get();
    if (!current.exists) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid.toString())
          .set({'SavedPairs': []});
    }
  }

  void _updateSavedDeletedListInLogin(
      Set<WordPair> saved, Set<WordPair> deleted) async {
    final User user = _auth.currentUser;
    final uid = user.uid;

    // await addUser();
    var pairIt = saved.iterator;
    while (pairIt.moveNext()) {
      _addUserSavedList(pairIt.current);
    }

    var pairIt1 = deleted.iterator;
    while (pairIt1.moveNext()) {
      _deleteUserSavedList(pairIt1.current);
    }
    deleted.clear();
  }

  void _loadTheSaved(Set<WordPair> saved, List<WordPair> suggestions) async {
    final User user = _auth.currentUser;
    final uid = user.uid;
    final dbRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid.toString())
        .get();
    var savedPairs = dbRef['SavedPairs'];

    List<dynamic> savedList = savedPairs;
    List<String> savedListString = savedList.cast<String>().toList();

    // bool flag = false;
    for (int i = 0; i < savedListString.length; i++) {
      var words = savedListString[i].split(new RegExp(r"(?<=[a-z])(?=[A-Z])"));
      // WordPair newWord = WordPair(words.first, words.last);
      WordPair pair = _ifExist(savedListString[i], suggestions);
      if (pair != null) {
        saved.add(pair);
      } else {
        saved.add(WordPair(words.first, words.last));
      }
    }
    notifyListeners();
  }

  WordPair _ifExist(String word, List<WordPair> suggestions) {
    for (int i = 0; i < suggestions.length; i++) {
      if (suggestions[i].asPascalCase == word) {
        return suggestions[i];
      }
    }
    return null;
  }



  Future<void> _addPicture(File image) async {
    final User user = _auth.currentUser;
    final uid = user.uid;
    String returnURL;

    Reference storageReference = _storage.ref().child("images/${DateTime.now()}");
    await storageReference.putFile(image);
    await storageReference.getDownloadURL().then((value) => returnURL = value);


    FirebaseFirestore.instance.collection('users').doc(uid.toString()).update({
      'image': returnURL
    });

  }


  Future<void> _getURL() async {
    final User user = _auth.currentUser;
    final uid = user.uid;
    final dbRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid.toString())
        .get();
    url = dbRef['image'].toString();
    notifyListeners();
  }

}

