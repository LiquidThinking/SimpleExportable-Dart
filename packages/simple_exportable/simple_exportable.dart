import 'dart:mirrors';

class Exportable {
  static bool _isExportableClass(Type type) {
    return reflectClass(type).superclass.reflectedType == Exportable;
  }

  static Type _getActualVariableType(VariableMirror variableMirror) {
    if (variableMirror.type.qualifiedName == reflectType(List).qualifiedName) {
      return variableMirror.type.typeArguments[0].reflectedType;
    }
    return variableMirror.type.reflectedType;
  }

  static bool _isJsonSupported(value) {
    if (value == null || value is bool || value is num || value is String || value is List || value is Map) {
      return true;
    }
    return false;
  }

  static dynamic _importSimpleValue(Type type, value) {
    if (type == DateTime && value is String) {
      return DateTime.parse(value).toLocal();
    } else if (_isJsonSupported(value)) {
      return value;
    }
    return null;
  }

  static Object getInstatiatedTypeForJson(Type type, dynamic json) {
    if (json is List) {
      var result = [];
      json.forEach((e) => result.add(getInstatiatedTypeForJson(type, e)));
      return result;
    } else {

      var result = reflectClass(type).newInstance(const Symbol(''), []).reflectee;
      InstanceMirror thisMirror = reflect(result);
      for (DeclarationMirror declarationMirror in thisMirror.type.declarations.values) {
        if (declarationMirror is VariableMirror) {
          var name = MirrorSystem.getName(declarationMirror.simpleName);

          var actualVariableType = _getActualVariableType(declarationMirror);

          var matchedKeys = json.keys.where((String key) => key.toLowerCase() == name.toLowerCase());
          if (matchedKeys.length > 0) {
            var value = json[matchedKeys.elementAt(0)];
            if (_isExportableClass(actualVariableType)) {
              thisMirror.setField(declarationMirror.simpleName, getInstatiatedTypeForJson(actualVariableType, value));
            } else {
              thisMirror.setField(declarationMirror.simpleName, _importSimpleValue(declarationMirror.type.reflectedType, value));
            }
          }
        }
      }
      return result;
    }
  }

  static Map getMapFromObject(Object object) {
    Map result = {};
    InstanceMirror thisMirror = reflect(object);
    for (DeclarationMirror declarationMirror in thisMirror.type.declarations.values) {
      if (declarationMirror is VariableMirror) {
        var name = MirrorSystem.getName(declarationMirror.simpleName);
        var value = thisMirror.getField(declarationMirror.simpleName).reflectee;
        result[name] = _isExportableClass(declarationMirror.type.reflectedType) ? getMapFromObject(value) : value;
      }
    }

    return result;
  }
}
