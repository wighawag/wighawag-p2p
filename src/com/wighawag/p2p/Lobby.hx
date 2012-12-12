package com.wighawag.p2p;

import promhx.Promise;
import haxe.Timer;

enum WaitingState{
    Listen;
    Request;
    Provide;
}


class Lobby {

    public static var Request : String = "Request";
    public static var Provide : String = "Provide";
    public static var Accept : String = "Accept";

    private var lobbyGroup : P2PGroupConnection;
    private var privateGroup : P2PGroupConnection;
    private var id : String;
    private var promise : Promise<P2PGroupConnection>;
    private var state : WaitingState;

    private var repeater : Timer;

    public function new(publicGroup : P2PGroupConnection) {
        this.lobbyGroup = publicGroup;
        state = null;
        id = "private" + Math.random() + Timer.stamp();
    }

    // TODO separate waitForRequest from request so you can not use them both
    public function waitForRequest() : Promise<P2PGroupConnection>{
        state = WaitingState.Listen;
        if(promise != null){
            return promise;
        }
        promise = new Promise();
        lobbyGroup.onMessageReceived.add(onMessageReceived);
        return promise;
    }


    public function request() : Promise<P2PGroupConnection>{
        state = WaitingState.Request;
        if(promise != null){
            return promise;
        }
        promise = new Promise();
        lobbyGroup.onMessageReceived.add(onMessageReceived);
        repeater = new Timer(1000);
        repeater.run = sendRequest;
        sendRequest();
        return promise;
    }

    private function sendRequest() : Void{
        lobbyGroup.sendData({id : id}, Request);
    }

    private function sendAccept() : Void{
        lobbyGroup.sendData({id : id}, Accept);
    }

    private function onMessageReceived(wrap : MessageWrap, info : Dynamic) : Void{
        Report.anInfo("Public", wrap.messageType);
        switch(state){
            case WaitingState.Listen:
                if(wrap.messageType == Request){
                    lobbyGroup.sendData({id:wrap.message.id}, Provide);
                    state = WaitingState.Provide;
                }
            case WaitingState.Provide:
                if (wrap.messageType == Accept){
                    lobbyGroup.close();
                    privateGroup = new P2PGroupConnection("Lobby" + wrap.message.id);
                    privateGroup.onConnect.add(privateGroupConnected);
                    privateGroup.connect();
                }
            case WaitingState.Request:
                if (wrap.messageType == Provide){
                    repeater.stop();
                    sendAccept(); // TODO check but this should be enouhj
                    lobbyGroup.close();
                    privateGroup = new P2PGroupConnection("Lobby" + id);
                    privateGroup.onConnect.add(privateGroupConnected);
                    privateGroup.connect();
                }
        }
    }

    private function privateGroupConnected() : Void{
        promise.resolve(privateGroup);
    }

    public function disconnect() : Void{
        state = null;
        lobbyGroup.close();
    }
}


