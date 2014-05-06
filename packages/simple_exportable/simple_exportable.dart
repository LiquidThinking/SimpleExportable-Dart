import 'dart:mirrors';

class Exportable {
  static ClassMirror _getActualTypeFromVariableMirror(VariableMirror type) {
    if (reflectClass(List) == type.type) {
      return type.type.typeArguments[0];
    }
    return type.type;
  }

  static Type _getActualType(Type type) {
    ClassMirror reflectedType = reflectClass(type);
    if (reflectedType is List) {
      return reflectedType.typeArguments[0].reflectedType;
    }
    return reflectedType.reflectedType;
  }

  static bool _isExportableClass(VariableMirror variableMirror) {
    
    var actualType = _getActualTypeFromVariableMirror(variableMirror);
    if (actualType is ClassMirror) {
      if (actualType.superclass.reflectedType == Exportable) {
        return true;
      }
    }
    return false;
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

    if (reflectClass(type) == reflectClass(List) || json is List) {
      return json.map((e) => getInstatiatedTypeForJson(_getActualType(type), e));
    } else {
      var result = reflectClass(type).newInstance(const Symbol(''), []).reflectee;
      InstanceMirror thisMirror = reflect(result);
      for (DeclarationMirror declarationMirror in thisMirror.type.declarations.values) {
        if (declarationMirror is VariableMirror) {
          var name = MirrorSystem.getName(declarationMirror.simpleName);
          ;
          var matchedKeys = json.keys.where((String key) => key.toLowerCase() == name.toLowerCase());
          if (matchedKeys.length > 0) {
            var value = json[matchedKeys.elementAt(0)];

            if (_isExportableClass(declarationMirror)) {
              thisMirror.setField(declarationMirror.simpleName, getInstatiatedTypeForJson(declarationMirror.type.reflectedType, value));
            } else if (_isJsonSupported(value)) {
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
        result[name] = _isExportableClass(declarationMirror) ? getMapFromObject(value) : value;
      }
    }

    return result;
  }


}
