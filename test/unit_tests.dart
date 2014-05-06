import 'dart:convert';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:simple_exportable/simple_exportable.dart';

class FlatClass extends Exportable {
  int id;
  String name;
}

class LayerdClass extends Exportable{
  FlatClass flatClass;
  String name;
}

class LayerdClasses extends Exportable{
  List<FlatClass> flatClasses;
  String name;
}

void main() {
  useHtmlConfiguration();

  test('for flat object fills properties', () {
    var json = JSON.decode('''{"id":1,"name":"John"}''');
    FlatClass result = Exportable.getInstatiatedTypeForJson(FlatClass, json);

    expect(result.id, 1);
    expect(result.name, "John");
  });

  test('for list of flat objects fills properties', () {
    var json = JSON.decode('''[{"id":1,"name":"John"},{"id":2,"name":"Fred"}]''');
    List<FlatClass> result = Exportable.getInstatiatedTypeForJson(FlatClass, json);

    expect(result[0].id, 1);
    expect(result[0].name, "John");
    
    expect(result[1].id, 2);
    expect(result[1].name, "Fred");
  });
  
  test('for object with sub class fills properties', () {
      var json = JSON.decode('''{"flatClass": {"id":1,"name":"John"}, "name": "John"}''');
      LayerdClass result = Exportable.getInstatiatedTypeForJson(LayerdClass, json);

      expect(result.name, "John");
      
      expect(result.flatClass.id, 1);
      expect(result.flatClass.name, "John");
    });
  
  test('for object with list of sub class fills properties', () {
        var json = JSON.decode('''{"flatClasses": [{"id":1,"name":"John"},{"id":2,"name":"Fred"}], "name": "John"}''');
        LayerdClasses result = Exportable.getInstatiatedTypeForJson(LayerdClasses, json);

        expect(result.name, "John");
        
        expect(result.flatClasses[0].id, 1);
        expect(result.flatClasses[0].name, "John");
        
        expect(result.flatClasses[1].id, 2);
                expect(result.flatClasses[1].name, "Fred");
      });
  
  test('for object with null sub object filles properties', () {
          var json = JSON.decode('''{"flatClass": null, "name": "the name"}''');
          LayerdClass result = Exportable.getInstatiatedTypeForJson(LayerdClass, json);

          expect(result.name, "the name");
          
          expect(result.flatClass, null);
        });
}
