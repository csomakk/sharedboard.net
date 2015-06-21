package CsUtils {
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.LocalConnection;

	public class CsUtils {
		
		public function collectGarbage():void{
			try {
				new LocalConnection().connect('foo');
				new LocalConnection().connect('foo');
			} catch (e:Error) {
				
			}
		}
		
		public function loadXML(url:String):XML{
			try{
				var stream:FileStream = new FileStream();
				stream.open(new File(url), FileMode.READ); //file megnyitás olvasásra
				var ret:XML = new XML(stream.readUTFBytes(stream.bytesAvailable)); //olvasás
				stream.close(); //file stream bezárása
				return ret;
			} catch(e:Error) {
				return new XML();
			}
			return new XML();
		}
		
		public function saveAsXML(xml:XML, url:String):void{
			var stream:FileStream = new FileStream(); // The FileStream 
			var outputString:String = '<?xml version="1.0" encoding="utf-8"?>\n'; //XML fejléc az elejére
			var file:File=new File(url);
			outputString += xml.toXMLString(); //hozzáfűzzük a paraméter XML-t
			outputString = outputString.replace(/\n/g, File.lineEnding); //és az EOF-ot is.
			stream = new FileStream();
			stream.open(file, FileMode.UPDATE);
			stream.writeUTFBytes(outputString); //elmentjük
			stream.close(); //bezárjuk
		}
	}
}