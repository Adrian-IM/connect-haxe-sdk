package connect.models;

import connect.Util;
import haxe.ds.StringMap;


class Model {
    private var fieldClassNames(default, null): StringMap<String>;


    public function toObject(): Dynamic {
        var obj = {};
        var fields = Type.getInstanceFields(Type.getClass(this));
        for (field in fields) {
            var value = Reflect.getProperty(this, field);
            if (field != 'fieldClassNames' && value != null) {
                switch (Type.typeof(value)) {
                    case TClass(String):
                        if (value.toString() != '') {
                            Reflect.setField(obj, Util.toSnakeCase(field), value.toString());
                        }
                    case TClass(class_):
                        var className = Type.getClassName(class_);
                        if (className.indexOf('connect.Collection') == 0) {
                            var col = cast(value, Collection<Dynamic>);
                            var arr = new Array<Dynamic>();
                            for (elem in col) {
                                var elemClassName = Type.getClassName(Type.getClass(elem));
                                if (elemClassName.indexOf('connect.models.') == 0) {
                                    arr.push(elem.toObject());
                                } else {
                                    arr.push(elem);
                                }                                
                            }
                            if (arr.length > 0) {
                                Reflect.setField(obj, Util.toSnakeCase(field), arr);
                            }
                        } else if (className.indexOf('connect.models.') == 0) {
                            var model = cast(value, Model).toObject();
                            if (Reflect.fields(model).length != 0) {
                                Reflect.setField(obj, Util.toSnakeCase(field), model);
                            }
                        } else {
                            Reflect.setField(obj, Util.toSnakeCase(field), value);
                        }
                    case TFunction:
                        // Skip
                    default:
                        Reflect.setField(obj, Util.toSnakeCase(field), value);
                }
            }
        }
        return obj;
    }


    public function toString(): String {
        return haxe.Json.stringify(this.toObject());
    }


    public function getFieldClassName(field: String): String {
        if (this.fieldClassNames != null && this.fieldClassNames.exists(field)) {
            var className = this.fieldClassNames.get(field);
            var exceptions = ['String'];
            if (exceptions.indexOf(className) == -1) {
                className = 'connect.models.' + className;
            }
            return className;
        } else {
            return null;
        }
    }


    public static function parse<T>(modelClass: Class<T>, obj: Dynamic): T {
        var model = Type.createInstance(modelClass, []);
        var castedModel = cast(model, Model);
        var fields = Type.getInstanceFields(modelClass);
        for (field in fields) {
            var snakeField = Util.toSnakeCase(field);
            if (Reflect.hasField(obj, snakeField)) {
                var val: Dynamic = Reflect.field(obj, snakeField);
                //trace('Injecting "${field}" in ' + Type.getClassName(modelClass));
                switch (Type.typeof(val)) {
                    case TClass(Array):
                        var className = castedModel.getFieldClassName(field);
                        if (className == null) {
                            var camelField = 'connect.models.' + Util.toCamelCase(field, true);
                            className = Util.toSingular(camelField);
                        }
                        var classObj = Type.resolveClass(className);
                        Reflect.setProperty(model, field, parseArray(classObj, val));
                    case TObject:
                        var className = castedModel.getFieldClassName(field);
                        if (className == null) {
                            className = 'connect.models.' + Util.toCamelCase(field, true);
                        }
                        var classObj = Type.resolveClass(className);
                        if (classObj != null) {
                            Reflect.setProperty(model, field, parse(classObj, val));
                        } else {
                            throw 'Cannot find class "${className}"';
                        }
                    default:
                        Reflect.setProperty(model, field, val);
                }
            }
        }
        return model;
    }


    public static function parseArray<T>(modelClass: Class<T>, array: Array<Dynamic>): Collection<T> {
        var result = new Collection<T>();
        for (obj in array) {
            result.push(parse(modelClass, obj));
        }
        return result;
    }


    @:dox(hide)
    public function _setFieldClassNames(map: StringMap<String>): Void {
        if (this.fieldClassNames == null) {
            this.fieldClassNames = map;
        }
    }


    public function new() {}
}
