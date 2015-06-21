package connection {
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.net.GroupSpecifier;
	import flash.net.NetConnection;
	import flash.net.NetGroup;
	import flash.utils.ByteArray;
	
	import mx.core.FlexGlobals;
	import mx.graphics.codec.PNGEncoder;
	
	public class P2Pconnection {
		
		private const SERVER_ADDRESS:String = "rtmfp://p2p.rtmfp.net/";
		private const DEVELOPER_KEY:String = "12695190ec5a53044665e959-dd3994a8d9e1";
		public var userNameStr:String
		public var connected:Boolean = false;
		public var groupNameStr:String;
		public var nc:NetConnection;
		public var estimatedPeopleCount:int;
		public var groupSpecifier:GroupSpecifier;
		public var netGroup:NetGroup;
		
		public function connect(groupName:String, userName:String):void {
			if(groupName.length < 1) {
				return;
			}
			groupNameStr = groupName;
			userNameStr = userName;
			nc = new NetConnection();
			nc.addEventListener(NetStatusEvent.NET_STATUS, netStatus);
			nc.connect(SERVER_ADDRESS+DEVELOPER_KEY);
		}
		
		public function disconnect():void {
			if(nc != null){
				nc.close();
			}
			connected = false;
			nc = new NetConnection();
			nc.addEventListener(NetStatusEvent.NET_STATUS, netStatus);
			FlexGlobals.topLevelApplication.homeView.sendChatMessage("You have left the group.");
			FlexGlobals.topLevelApplication.homeView.setNumberOfPeopleInGroup(0);
				
		}
	
		public function netStatus(e: NetStatusEvent): void {
			switch (e.info.code) {
				case "NetConnection.Connect.Success":
					FlexGlobals.topLevelApplication.homeView.sendChatMessage("Connected to server");
					initNetGroup();
					
					break;
				
				case "NetGroup.Connect.Success":
					FlexGlobals.topLevelApplication.homeView.sendChatMessage("Connected to group "+groupNameStr);
					estimatedPeopleCount=e.info.group.estimatedMemberCount;
					sendChatMessage("i have connected to the group.");
					
					FlexGlobals.topLevelApplication.homeView.setNumberOfPeopleInGroup(estimatedPeopleCount);
					connected = true;
					
					break;
				
				case "NetGroup.Posting.Notify":
					recieveMessage(e.info.message)
					break;
				case "NetGroup.Neighbor.Disconnect":
					estimatedPeopleCount = e.currentTarget.estimatedMemberCount
					FlexGlobals.topLevelApplication.homeView.sendChatMessage("Somebody left the group "+groupNameStr)
					FlexGlobals.topLevelApplication.homeView.setNumberOfPeopleInGroup(estimatedPeopleCount)
					break;
				case "NetGroup.Neighbor.Connect":
					estimatedPeopleCount = e.currentTarget.estimatedMemberCount
					FlexGlobals.topLevelApplication.homeView.sendChatMessage("Somebody joined the group "+groupNameStr)
					FlexGlobals.topLevelApplication.homeView.setNumberOfPeopleInGroup(estimatedPeopleCount)
					break;
				
				default:
					if (e.info.level == "error") {
						FlexGlobals.topLevelApplication.homeView.sendChatMessage("An error occured with the internet connection. If your connection is fine, please try again.")
					}
			}
		}
		
		
		
		public function initNetGroup(): void {
			if(groupNameStr.length > 0) {
				groupSpecifier = new GroupSpecifier(groupNameStr);
				groupSpecifier.postingEnabled = true;
				groupSpecifier.routingEnabled = true;
				groupSpecifier.serverChannelEnabled = true;
				//according to http://ptm.fi/?p=291 
				groupSpecifier.ipMulticastMemberUpdatesEnabled = true;
				groupSpecifier.addIPMulticastAddress("225.225.0.1:30000");
				//ptm end
				netGroup=new NetGroup(nc,groupSpecifier.groupspecWithoutAuthorizations());
				netGroup.addEventListener(NetStatusEvent.NET_STATUS, netStatus);
				
			}
		}
		
		public function sendChatMessage(text:String):void {
			if(connected) {
				var message: Object = new Object();
				message.type = "chat";
				message.user = userNameStr;
				message.text = text;
				message.time = new Date().time;
				netGroup.post(message);
				addLineToChat("You said: "+text)
			}
		}
		
		private function addLineToChat(line:String):void {
			FlexGlobals.topLevelApplication.homeView.recieve.text = line+"\n"+FlexGlobals.topLevelApplication.homeView.recieve.text;
		}
		
		public function sendLineMessage(lineThickness:Number, lineColor:Number, xes:Array, ys:Array): void {
			if(connected) {
				var message: Object = new Object();
				message.type = "line";
				message.user = userNameStr;
				message.lineThickness = lineThickness;
				message.lineColor = lineColor;
				message.xes = xes;
				message.ys = ys;
				message.time = new Date().time;
				netGroup.post(message);
			}
		}
		
		public function sendBitmapMessage(bitmap:BitmapData, x:Number, y:Number, width:Number, heigth:Number):void {
			if(connected) {
				
				var message: Object=new Object()
				
				message.type = "bitmap";
				message.user = userNameStr;
				var encoder:PNGEncoder = new PNGEncoder();
				
				message.bitmapdata=encoder.encode(bitmap);
				message.width=width;
				message.heigth=heigth;
				message.x=x;
				message.y=y;
				message.time = new Date().time;
				netGroup.post(message);
			}
		}
		
		public function sendClearMessage(): void {
			if(connected){
				var message: Object = new Object();
				message.type = "clear";
				message.user = userNameStr;
				message.time = new Date().time;
				netGroup.post(message);
			}
		}
	
		public function recieveMessage(o:Object):void {
			if(o.type == "chat"){
				addLineToChat(o.user+": "+o.text);
			}
			if(o.type == "line"){
				FlexGlobals.topLevelApplication.homeView.boardHolder.board.drawLine(o.lineThickness, o.lineColor, o.xes, o.ys);
				FlexGlobals.topLevelApplication.homeView.boardHolder.board.drawn += o.xes.length;
			}
			if(o.type == "clear"){
				FlexGlobals.topLevelApplication.homeView.boardHolder.board.resetBoard();
				addLineToChat(o.user+"reseted the board");
			} 
			if(o.type == "bitmap"){
				var recieved:ByteArray = o.bitmapdata
				var loader:Loader = new Loader();
				loader.loadBytes(recieved);
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderComplete);
				
				function loaderComplete(event:Event):void {
					var loaderInfo:LoaderInfo = LoaderInfo(event.target);
					var bitmapData:BitmapData = new BitmapData(loaderInfo.width, loaderInfo.height, true, 0x00FF0000);
					bitmapData.draw(loaderInfo.loader);
					
					var g:Graphics=FlexGlobals.topLevelApplication.homeView.boardHolder.board.line.graphics;
					
					g.lineStyle(0,0,0);
					g.moveTo(0,0);
					
					g.beginBitmapFill(bitmapData);
					g.drawRect(0,0,o.width,o.heigth);
					g.endFill(); 
					
					g.lineStyle(FlexGlobals.topLevelApplication.homeView.boardHolder.board.lineStyleThickness,
						FlexGlobals.topLevelApplication.homeView.boardHolder.board.lineStyleColor); //restore line color
					
				}	
			}
		}
	}
}