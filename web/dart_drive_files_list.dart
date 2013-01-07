import 'dart:html';
import 'package:js/js.dart' as js;
import 'dart:json';

/**
 * Sample google drive class.
 */
class Drive {
  js.Proxy _drive;
  bool get _isLoaded => _drive != null;

  /**
   * Load the gapi.client.drive api.
   */
  Future<bool> load() {
    var completer = new Completer();
    js.scoped(() {
      js.context.gapi.client.load('drive', 'v2', new js.Callback.once(() {
        _drive = js.context.gapi.client.drive;
        js.retain(_drive);
        completer.complete(true);
      }));
    });
    return completer.future;
  }

  /**
   * Check if gapi.client.drive is loaded, if not
   * load before executing.
   */
  void _loadederExecute(Function function) {
    if (_isLoaded) {
      function();
    } else {
      load().then((s) {
        if (s == true) {
          function();
        } else {
          throw "loadedExecute failed";
        }
      });
    }
  }

  /**
   * List files with gapi.drive.files.list()
   */
  Future<Map> list() {
    var completer = new Completer();
    _loadederExecute(() {
      js.scoped(() {
        var request = _drive.files.list();
        request.execute(new js.Callback.once((js.Proxy jsonResp, var rawResp) {
          Map m = JSON.parse(js.context.JSON.stringify(jsonResp));
          completer.complete(m);
        }));
      });
    });
    return completer.future;
  }
}

/**
 * Sample google api client loader.
 */
class GoogleApiClientLoader {
  static const String _CLIENT_ID = '299615367852.apps.googleusercontent.com';
  static const String _SCOPE = 'https://www.googleapis.com/auth/drive';
  static const String _handleClientLoadName = "handleClientLoad";

  static void _loadScript() {
    /**
     * Create and load script element.
     */
    ScriptElement script = new ScriptElement();
    script.src = "http://apis.google.com/js/client.js?onload=$_handleClientLoadName";
    script.type = "text/javascript";
    document.body.children.add(script);
  }

  static void _createScopedCallbacks(var completer) {
    js.scoped((){
      /**
       * handleAuthResult is called from javascript when
       * the function to call once the login process is complete.
       */
      js.context.handleAuthResult = new js.Callback.many((js.Proxy authResult) {
        Map dartAuthResult = JSON.parse(js.context.JSON.stringify(authResult));
        completer.complete(dartAuthResult);
      });

      /**
       * This javascript method is called when the client.js script
       * is loaded.
       */
      js.context.handleClientLoad =  new js.Callback.many(() {
        js.context.window.setTimeout(js.context.checkAuth, 1);
      });

      /**
       * Authorization check if the client allows this
       * application to access its google drive.
       */
      js.context.checkAuth = new js.Callback.many(() {
        js.context.gapi.auth.authorize(
            js.map({
              'client_id': _CLIENT_ID,
              'scope': _SCOPE,
              'immediate': true
            }),
            js.context.handleAuthResult);
      });

    });
  }

  /**
   * Load the google client api, future returns
   * map results.
   */
  static Future<Map> load() {
    var completer = new Completer();
    _createScopedCallbacks(completer);
    _loadScript();
    return completer.future;
  }
}

void main() {
  Drive drive = new Drive();
  GoogleApiClientLoader.load().then((result) {
    drive.list().then((Map files) {
      // https://developers.google.com/drive/v2/reference/files/list
      files['items'].forEach((i) {
        var li = new LIElement();
        AnchorElement a = new AnchorElement();
        a.href = i['alternateLink'];
        a.target = '_blank';
        a.text = i['title'];
        li.children.add(a);
        UListElement ul = query('#listmenu');
        ul.children.add(li);
      });
    });
  });
}
