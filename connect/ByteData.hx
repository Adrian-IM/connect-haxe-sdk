package connect;

import connect.models.Contract;
import haxe.io.Bytes;


/**
    This object represents a buffer of bytes. Just as the contents of a text file can be
    represented by a string, the contents of binary files can be represented by a ByteData object. 
**/
class ByteData {
    /** Loads the contents of the file at the specified path as a ByteData object. **/
    public static function load(path: String): ByteData {
        return new ByteData(sys.io.File.getBytes(path));
    }


    @:dox(hide)
    public function _getBytes(): Bytes {
        return bytes;
    }


    private final bytes: Bytes;


    private function new(bytes: Bytes) {
        this.bytes = bytes;
    }
}
