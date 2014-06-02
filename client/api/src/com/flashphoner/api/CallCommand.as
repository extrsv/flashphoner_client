/*
Copyright (c) 2011 Flashphoner
All rights reserved. This Code and the accompanying materials
are made available under the terms of the GNU Public License v2.0
which accompanies this distribution, and is available at
http://www.gnu.org/licenses/old-licenses/gpl-2.0.html

Contributors:
    Flashphoner - initial API and implementation

This code and accompanying materials also available under LGPL and MPL license for Flashphoner buyers. Other license versions by negatiation. Write us support@flashphoner.com with any questions.
*/
package com.flashphoner.api
{
		
	import com.adobe.cairngorm.commands.ICommand;
	import com.adobe.cairngorm.control.CairngormEvent;
	import com.flashphoner.Logger;
	import com.flashphoner.api.data.ModelLocator;
	import com.flashphoner.api.data.PhoneConfig;
	import com.flashphoner.api.management.VideoControl;
	
	import flash.events.*;
	import flash.utils.*;
	
	internal class CallCommand implements ICommand
	{		
		private var hangupTimer:Timer;
		
		public function CallCommand()
		{
		}	
		
		private function getStreamName(modelLocator:ModelLocator, call:Call) : String
		{
			return "INCOMING_"+modelLocator.login+"_"+call.id;			
		}
				
		public function execute( event : CairngormEvent ) : void
		{	
			Logger.info("PhoneCommand.execute() event.type "+event.type);
			
			var call:Call = (event as CallEvent).call;
			var flashAPI:Flash_API = call.flash_API;
			var modelLocator:ModelLocator = flashAPI.modelLocator;
			
			if (event.type==CallEvent.TALK){
				Logger.info("MainEvent.TALK "+call.id);
				SoundControl.stopRingSound();				

				call.startTimer();
				call.publish();
				flashAPI.phoneServerProxy.phoneSpeaker.play(getStreamName(modelLocator, call), true);
			}
			
			if (event.type==CallEvent.HOLD){
				call.unpublish();
			}
			 
			if (event.type == CallEvent.SESSION_PROGRESS){
				Logger.info("MainEvent.SESSION_PROGRESS");
		 		SoundControl.stopRingSound();
				flashAPI.phoneServerProxy.phoneSpeaker.play(getStreamName(modelLocator, call), true);
		 	}
			
			if (event.type==CallEvent.IN){
				SoundControl.playRingSound();
				flashAPI.phoneServerProxy.phoneSpeaker.play(getStreamName(modelLocator, call), false);
			}
			
			if (event.type ==CallEvent.OUT){
				//check if we already received session progress, if so no need to play ring sound
				if (!call.sessionProgressReceived) {
					SoundControl.playRingSound();
					flashAPI.phoneServerProxy.phoneSpeaker.play(getStreamName(modelLocator, call), false);
				} else {
					Logger.info("Received ring request while in session progress, ignoring");
				}
			}
			
			if (event.type == CallEvent.BUSY){
				SoundControl.playBusySound();		
				SoundControl.stopRingSound();														
			}
			if (event.type == CallEvent.FINISH){
				SoundControl.playFinishSound();		
				SoundControl.stopRingSound();														
				
				call.stopTimer();
				call.unpublish();
				flashAPI.removeCall(call.id);
				flashAPI.phoneServerProxy.phoneSpeaker.stop(call.id);
			}				
			
		}
	}
}
