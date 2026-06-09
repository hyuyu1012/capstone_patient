E/flutter (30216): #1      MethodChannel._invokeMethod (package:flutter/src/services/platform_channel.dart:366:18)
E/flutter (30216): <asynchronous suspension>
E/flutter (30216): #2      MethodChannelPermissionHandler.requestPermissions (package:permission_handler_platform_interface/src/method_channel/method_channel_permission_handler.dart:80:9)
E/flutter (30216): <asynchronous suspension>
E/flutter (30216): #3      PermissionActions.request (package:permission_handler/permission_handler.dart:109:10)
E/flutter (30216): <asynchronous suspension>
E/flutter (30216): #4      MedSensingService._ensureMicPermission (package:capstone_patient/sensing/med_sensing_service_io.dart:178:20)
E/flutter (30216): <asynchronous suspension>
E/flutter (30216): #5      MedSensingService._startMic (package:capstone_patient/sensing/med_sensing_service_io.dart:155:12)
E/flutter (30216): <asynchronous suspension>
E/flutter (30216):
D/VRI[MainActivity]@2810794(30216): mThreadedRenderer.initializeIfNeeded()#2 mSurface={isValid=true 0xb4000071fdc51200}
D/InputMethodManagerUtils(30216): startInputInner - Id : 0
I/InputMethodManager(30216): startInputInner - IInputMethodManagerGlobalInvoker.startInputOrWindowGainedFocus
D/InputTransport(30216): Input channel constructed: 'ClientS', fd=225
I/InputMethodManager(30216): handleMessage: setImeVisibility visible=false
D/InsetsController(30216): hide(ime(), fromIme=false)
I/ImeTracker(30216): com.example.capstone_patient:f46bef29: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
I/NotificationManager(30216): com.example.capstone_patient: notify(2456, null, Notification(channel=sensing_fgs shortcut=null contentView=null vibrate=null sound=null defaults=0 flags=ONGOING_EVENT|ONLY_ALERT_ONCE color=0x00000000 vis=PUBLIC semFlags=0x0 semPriority=0 semMissedCount=0)) as user
D/NotificationManager(30216): BOOTING pkg =com.example.capstone_patient mBlockedChannelsForOverflowNoti=[]
D/TTS     (30216): Utterance ID has started: 8046aa40-c283-4396-b3f7-313533808480
D/TTS     (30216): Utterance ID has completed: 8046aa40-c283-4396-b3f7-313533808480