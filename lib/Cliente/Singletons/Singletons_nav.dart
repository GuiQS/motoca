import 'package:flutter/cupertino.dart';

class SingletonNav {
  static SingletonNav _instance = SingletonNav._();
  var context;

  SingletonNav._();

  static SingletonNav get instance => _instance;

  BuildContext getContext() {
    return context;
  }

  void setContext(BuildContext context) {
    this.context = context;
  }
}
