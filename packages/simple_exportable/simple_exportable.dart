import 'dart:mirrors';

class Exportable {
	static bool isExportableClass(VariableMirror variableMirror) {
		if (variableMirror.type is ClassMirror) {
			var classMirror = variableMirror.type as ClassMirror;
			if (classMirror.superclass.reflectedType == Exportable) {
				return true;
			}
		}
		return false;
	}

	static Object getInstatiatedTypeForJson(Type type, Map json) {
		var result = reflectClass(type).newInstance(const Symbol(''), []).reflectee;
		InstanceMirror thisMirror = reflect(result);
		for (DeclarationMirror declarationMirror in thisMirror.type.declarations.values) {
			if (declarationMirror is VariableMirror) {
				var name = MirrorSystem.getName(declarationMirror.simpleName);
				;
				var matchedKeys = json.keys.where((String key)=>key.toLowerCase() == name.toLowerCase());
				if (matchedKeys.length > 0) {
					var value = json[matchedKeys.elementAt(0)];
					if (isExportableClass(declarationMirror)) {
						thisMirror.setField(declarationMirror.simpleName, getInstatiatedTypeForJson(declarationMirror.type.reflectedType, value));
					} else {
						if (declarationMirror.type.reflectedType == DateTime) thisMirror.setField(declarationMirror.simpleName, DateTime.parse(value as String).toLocal()); else thisMirror.setField(declarationMirror.simpleName, value);
					}
				}
			}
		}
		return result;
	}

	static Map getMapFromObject(Object object) {
		Map result = {};
		InstanceMirror thisMirror = reflect(object);
		for (DeclarationMirror declarationMirror in thisMirror.type.declarations.values) {
			if (declarationMirror is VariableMirror) {
				var name = MirrorSystem.getName(declarationMirror.simpleName);
				var value = thisMirror.getField(declarationMirror.simpleName).reflectee;
				result[name] = isExportableClass(declarationMirror) ? getMapFromObject(value) : value;
			}
		}

		return result;
	}


}
