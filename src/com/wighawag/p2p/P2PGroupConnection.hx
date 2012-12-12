package com.wighawag.p2p;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.NetStatusEvent;
import flash.net.GroupSpecifier;
import flash.net.NetConnection;
import flash.net.NetGroup;
import msignal.Signal;


class P2PGroupConnection {
	
	private var localNc:NetConnection;
	private var group:NetGroup;	
	private var connected:Bool = false;
	private var groupPin:String;
    public var onMessageReceived(default,null) : Signal2<MessageWrap, Dynamic>;
	public var onConnect(default, null) : Signal0;	
	public var onConnectionClosed(default, null) : Signal0;	

	public function new(groupPin : String){
		this.groupPin = groupPin;
		onConnect = new Signal0();
		onConnectionClosed = new Signal0();
        onMessageReceived = new Signal2();
	}
	
	public function connect():Void{
		localNc = new NetConnection();
		localNc.addEventListener(NetStatusEvent.NET_STATUS, netStatus);
		localNc.connect("rtmfp:");
	}
	
	public function close():Void{
		localNc.close();
		connected = false;
	}
	
	private function netStatus(event:NetStatusEvent):Void{
		Report.anInfo("Controller", event.info.code);
		switch(event.info.code){
			case "NetConnection.Connect.Success":
				setupGroup();
				
			
			case "NetGroup.Connect.Success":
				connected = true;
				onConnect.dispatch();
				
			
			case "NetConnection.Connect.Closed":
				connected = false;
				onConnectionClosed.dispatch();
				
			
			case "NetGroup.SendTo.Notify":
				onMessageReceived.dispatch(MessageWrap.parse(event.info.message),event.info);
        }
	}
	
	private function setupGroup():Void{
		var groupspec:GroupSpecifier = new GroupSpecifier("LocalDeviceControllers/PIN" + groupPin);
		groupspec.serverChannelEnabled = true;
		groupspec.multicastEnabled = true;
		groupspec.ipMulticastMemberUpdatesEnabled = true;
		groupspec.routingEnabled = true;
		groupspec.postingEnabled = true;
		groupspec.addIPMulticastAddress("225.225.0.1:30303");

		group = new NetGroup(localNc, groupspec.groupspecWithAuthorizations());
		group.addEventListener(NetStatusEvent.NET_STATUS,netStatus);

	}
	
	public function sendData(data:Dynamic, messageType : String):Void{
		if(connected){
            var wrap = new MessageWrap(data, messageType, haxe.Timer.stamp() / 1000);
			group.sendToAllNeighbors(wrap);
		}          
	}
	
}
