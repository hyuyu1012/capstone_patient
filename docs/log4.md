I/flutter (22345): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (22345): │ #0   FlutterSoundRecorder.openRecorder (package:flutter_sound/public/flutter_sound_recorder.dart:474:13)
I/flutter (22345): │ #1   AudioStreamer._ensureOpen (package:capstone_patient/sensing/audio_streamer.dart:39:21)
I/flutter (22345): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (22345): │ 🐛 FS:---> openRecorder
I/flutter (22345): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (22345): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (22345): │ #0   FlutterSoundRecorder._openAudioSession (package:flutter_sound/public/flutter_sound_recorder.dart:483:13)
I/flutter (22345): │ #1   FlutterSoundRecorder.openRecorder.<anonymous closure> (package:flutter_sound/public/flutter_sound_recorder.dart:476:11)
I/flutter (22345): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (22345): │ 🐛 ---> _openAudioSession
I/flutter (22345): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (22345): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (22345): │ #0   FlutterSoundRecorder.openRecorder (package:flutter_sound/public/flutter_sound_recorder.dart:478:13)
I/flutter (22345): │ #1   <asynchronous suspension>
I/flutter (22345): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (22345): │ 🐛 FS:<--- openAudioSession
I/flutter (22345): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
E/flutter (22345): [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: MissingPluginException(No implementation found for method openRecorder on channel xyz.canardoux.flutter_sound_recorder)
E/flutter (22345): #0      MethodChannel._invokeMethod (package:flutter/src/services/platform_channel.dart:364:7)
E/flutter (22345): <asynchronous suspension>
E/flutter (22345): #1      FlutterSoundRecorder._openAudioSession (package:flutter_sound/public/flutter_sound_recorder.dart:513:7)
E/flutter (22345): <asynchronous suspension>
E/flutter (22345): #2      AudioStreamer._ensureOpen (package:capstone_patient/sensing/audio_streamer.dart:39:5)
E/flutter (22345): <asynchronous suspension>
E/flutter (22345): #3      AudioStreamer.start (package:capstone_patient/sensing/audio_streamer.dart:45:5)
E/flutter (22345): <asynchronous suspension>
E/flutter (22345): #4      MedSensingService._startMic (package:capstone_patient/sensing/med_sensing_service_io.dart:157:7)
E/flutter (22345): <asynchronous suspension>
E/flutter (22345):
I/NotificationManager(22345): com.example.capstone_patient: notify(2456, null, Notification(channel=sensing_fgs shortcut=null contentView=null vibrate=null sound=null defaults=0 flags=ONGOING_EVENT|ONLY_ALERT_ONCE color=0x00000000 vis=PUBLIC semFlags=0x0 semPriority=0 semMissedCount=0)) as user
D/NotificationManager(22345): BOOTING pkg =com.example.capstone_patient mBlockedChannelsForOverflowNoti=[]
I/ImeFocusController(22345): onPreWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
I/ImeFocusController(22345): onPostWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
I/VRI[MainActivity]@74665ff(22345): handleResized, frames=ClientWindowFrames{frame=[0,0][1080,2640] display=[0,0][1080,2640] parentFrame=[0,0][0,0]} displayId=0 dragResizing=false compatScale=1.0 frameChanged=false attachedFrameChanged=false configChanged=false displayChanged=false compatScaleChanged=false dragResizingChanged=false
D/VRI[MainActivity]@74665ff(22345): mThreadedRenderer.initializeIfNeeded()#2 mSurface={isValid=true 0xb40000740abae100}
D/InputMethodManagerUtils(22345): startInputInner - Id : 0
I/InputMethodManager(22345): startInputInner - IInputMethodManagerGlobalInvoker.startInputOrWindowGainedFocus
I/InsetsSourceConsumer(22345): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.example.capstone_patient/com.example.capstone_patient.MainActivity
I/InsetsSourceConsumer(22345): applyRequestedVisibilityToControl: visible=true, type=navigationBars, host=com.example.capstone_patient/com.example.capstone_patient.MainActivity
I/InputMethodManager(22345): handleMessage: setImeVisibility visible=false
D/InsetsController(22345): hide(ime(), fromIme=false)
I/ImeTracker(22345): com.example.capstone_patient:68d37a56: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/InputTransport(22345): Input channel constructed: 'ClientS', fd=170
I/VRI[MainActivity]@74665ff(22345): handleResized, frames=ClientWindowFrames{frame=[0,0][1080,2640] display=[0,0][1080,2640] parentFrame=[0,0][0,0]} displayId=0 dragResizing=false compatScale=1.0 frameChanged=false attachedFrameChanged=false configChanged=false displayChanged=false compatScaleChanged=false dragResizingChanged=false
I/ImeFocusController(22345): onPreWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
I/ImeFocusController(22345): onPostWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
I/BLASTBufferQueue_Java(22345): update, w= 1080 h= 2640 mName = VRI[MainActivity]@74665ff mNativeObject= 0xb4000071e7cd4000 sc.mNativeObject= 0xb4000071f2620540 format= -3 caller= android.view.ViewRootImpl.updateBlastSurfaceIfNeeded:3574 android.view.ViewRootImpl.relayoutWindow:11685 android.view.ViewRootImpl.performTraversals:4804 android.view.ViewRootImpl.doTraversal:3924 android.view.ViewRootImpl$TraversalRunnable.run:12903 android.view.Choreographer$CallbackRecord.run:1901
I/VRI[MainActivity]@74665ff(22345): Relayout returned: old=(0,0,1080,2640) new=(0,0,1080,2640) relayoutAsync=true req=(1080,2640)0 dur=1 res=0x0 s={true 0xb40000740abae100} ch=false seqId=0
I/VRI[MainActivity]@74665ff(22345): updateBoundsLayer: t=android.view.SurfaceControl$Transaction@e285e7e sc=Surface(name=Bounds for - com.example.capstone_patient/com.example.capstone_patient.MainActivity@0)/@0x76ecfdf frame=2
I/VRI[MainActivity]@74665ff(22345): registerCallbackForPendingTransactions
I/VRI[MainActivity]@74665ff(22345): mWNT: t=0xb4000071f2783e80 mBlastBufferQueue=0xb4000071e7cd4000 fn= 2 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.ViewRootImpl$10.onFrameDraw:6536 android.view.ViewRootImpl$4.onFrameDraw:2489 android.view.ThreadedRenderer$1.onFrameDraw:718
I/InsetsSourceConsumer(22345): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.example.capstone_patient/com.example.capstone_patient.MainActivity
I/InsetsSourceConsumer(22345): applyRequestedVisibilityToControl: visible=true, type=navigationBars, host=com.example.capstone_patient/com.example.capstone_patient.MainActivity
D/VRI[MainActivity]@74665ff(22345): mThreadedRenderer.initializeIfNeeded()#2 mSurface={isValid=true 0xb40000740abae100}
D/InputMethodManagerUtils(22345): startInputInner - Id : 0
I/InputMethodManager(22345): startInputInner - IInputMethodManagerGlobalInvoker.startInputOrWindowGainedFocus
I/InputMethodManager(22345): handleMessage: setImeVisibility visible=false
D/InsetsController(22345): hide(ime(), fromIme=false)
I/ImeTracker(22345): com.example.capstone_patient:9051cf5a: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/InputTransport(22345): Input channel constructed: 'ClientS', fd=205
I/VRI[MainActivity]@74665ff(22345): handleResized, frames=ClientWindowFrames{frame=[0,0][1080,2640] display=[0,0][1080,2640] parentFrame=[0,0][0,0]} displayId=0 dragResizing=false compatScale=1.0 frameChanged=false attachedFrameChanged=false configChanged=false displayChanged=false compatScaleChanged=false dragResizingChanged=false
I/ImeFocusController(22345): onPreWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
I/ImeFocusController(22345): onPostWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
I/BLASTBufferQueue_Java(22345): update, w= 1080 h= 2640 mName = VRI[MainActivity]@74665ff mNativeObject= 0xb4000071e7cd4000 sc.mNativeObject= 0xb4000071f2620540 format= -3 caller= android.view.ViewRootImpl.updateBlastSurfaceIfNeeded:3574 android.view.ViewRootImpl.relayoutWindow:11685 android.view.ViewRootImpl.performTraversals:4804 android.view.ViewRootImpl.doTraversal:3924 android.view.ViewRootImpl$TraversalRunnable.run:12903 android.view.Choreographer$CallbackRecord.run:1901
I/VRI[MainActivity]@74665ff(22345): Relayout returned: old=(0,0,1080,2640) new=(0,0,1080,2640) relayoutAsync=true req=(1080,2640)0 dur=0 res=0x0 s={true 0xb40000740abae100} ch=false seqId=0
I/VRI[MainActivity]@74665ff(22345): updateBoundsLayer: t=android.view.SurfaceControl$Transaction@e285e7e sc=Surface(name=Bounds for - com.example.capstone_patient/com.example.capstone_patient.MainActivity@0)/@0x76ecfdf frame=3
I/VRI[MainActivity]@74665ff(22345): registerCallbackForPendingTransactions
I/VRI[MainActivity]@74665ff(22345): mWNT: t=0xb4000071e97c3680 mBlastBufferQueue=0xb4000071e7cd4000 fn= 3 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.ViewRootImpl$10.onFrameDraw:6536 android.view.ViewRootImpl$4.onFrameDraw:2489 android.view.ThreadedRenderer$1.onFrameDraw:718
I/InsetsSourceConsumer(22345): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.example.capstone_patient/com.example.capstone_patient.MainActivity
I/InsetsSourceConsumer(22345): applyRequestedVisibilityToControl: visible=true, type=navigationBars, host=com.example.capstone_patient/com.example.capstone_patient.MainActivity
D/VRI[MainActivity]@74665ff(22345): mThreadedRenderer.initializeIfNeeded()#2 mSurface={isValid=true 0xb40000740abae100}
D/InputMethodManagerUtils(22345): startInputInner - Id : 0
I/InputMethodManager(22345): startInputInner - IInputMethodManagerGlobalInvoker.startInputOrWindowGainedFocus
I/InputMethodManager(22345): handleMessage: setImeVisibility visible=false
D/InsetsController(22345): hide(ime(), fromIme=false)
I/ImeTracker(22345): com.example.capstone_patient:6027f2a: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/InputTransport(22345): Input channel constructed: 'ClientS', fd=174
I/ImeFocusController(22345): onPreWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
I/ImeFocusController(22345): onPostWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
D/InputTransport(22345): Input channel destroyed: 'ClientS', fd=193
I/VRI[MainActivity]@74665ff(22345): handleAppVisibility mAppVisible = true visible = false
D/VRI[MainActivity]@74665ff(22345): visibilityChanged oldVisibility=true newVisibility=false
I/SV[39109000 MainActivity](22345): onWindowVisibilityChanged(8) false io.flutter.embedding.android.FlutterSurfaceView{254c188 V.E...... ........ 0,0-1080,2640} of VRI[MainActivity]@74665ff
I/SurfaceView(22345): 39109000 Changes: creating=false format=false size=false visible=true alpha=false hint=false left=false top=false z=false attached=true lifecycleStrategy=false
I/SurfaceView(22345): 39109000 Cur surface: Surface(name=null mNativeObject=-5476376648484703488)/@0x2a11382
D/SurfaceComposerClient(22345): setCornerRadius ## 254c188 SurfaceView[com.example.capstone_patient/com.example.capstone_patient.MainActivity]@0#2582 cornerRadius=0.000000
I/SurfaceView(22345): 39109000 surfaceDestroyed
I/SV[39109000 MainActivity](22345): surfaceDestroyed callback.size 1 #2 io.flutter.embedding.android.FlutterSurfaceView{254c188 V.E...... ........ 0,0-1080,2640}
I/SV[39109000 MainActivity](22345): updateSurface: mVisible = false mSurface.isValid() = true
I/SV[39109000 MainActivity](22345): releaseSurfaces: viewRoot = VRI[MainActivity]@74665ff
V/SurfaceView(22345): Layout: x=0 y=0 w=1080 h=2640, frame=Rect(0, 0 - 1080, 2640)
D/SurfaceView(22345): 239257117 windowPositionLost, frameNr = 0
D/HWUI    (22345): CacheManager::trimMemory(20)
I/VRI[MainActivity]@74665ff(22345): Relayout returned: old=(0,0,1080,2640) new=(0,0,1080,2640) relayoutAsync=false req=(1080,2640)8 dur=1 res=0x2 s={false 0x0} ch=true seqId=0
I/SV[39109000 MainActivity](22345): windowStopped(true) false io.flutter.embedding.android.FlutterSurfaceView{254c188 V.E...... ........ 0,0-1080,2640} of VRI[MainActivity]@74665ff
D/SV[39109000 MainActivity](22345): updateSurface: surface is not valid
I/SV[39109000 MainActivity](22345): releaseSurfaces: viewRoot = VRI[MainActivity]@74665ff
D/VRI[MainActivity]@74665ff(22345): applyTransactionOnDraw applyImmediately
D/SV[39109000 MainActivity](22345): updateSurface: surface is not valid
I/SV[39109000 MainActivity](22345): releaseSurfaces: viewRoot = VRI[MainActivity]@74665ff
D/VRI[MainActivity]@74665ff(22345): applyTransactionOnDraw applyImmediately
D/VRI[MainActivity]@74665ff(22345): Not drawing due to not visible. Reason=!mAppVisible && !mForceDecorViewVisibility
D/VRI[MainActivity]@74665ff(22345): Pending transaction will not be applied in sync with a draw due to view not visible
I/VRI[MainActivity]@74665ff(22345): mWNT: t=0xb40000740ab12b00 mBlastBufferQueue=0xnull fn= 0 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.ViewRootImpl.handleSyncRequestWhenNoAsyncDraw:6733 android.view.ViewRootImpl.performTraversals:5504 android.view.ViewRootImpl.doTraversal:3924
I/VRI[MainActivity]@74665ff(22345): stopped(true) old = false
D/VRI[MainActivity]@74665ff(22345): WindowStopped on com.example.capstone_patient/com.example.capstone_patient.MainActivity set to true
D/HWUI    (22345): CacheManager::trimMemory(20)
D/SV[39109000 MainActivity](22345): updateSurface: surface is not valid
I/SV[39109000 MainActivity](22345): releaseSurfaces: viewRoot = VRI[MainActivity]@74665ff
D/VRI[MainActivity]@74665ff(22345): applyTransactionOnDraw applyImmediately
D/SV[39109000 MainActivity](22345): updateSurface: surface is not valid
I/SV[39109000 MainActivity](22345): releaseSurfaces: viewRoot = VRI[MainActivity]@74665ff
D/VRI[MainActivity]@74665ff(22345): applyTransactionOnDraw applyImmediately
D/BBA2    (22345): setIsFg isFg = false; delayValue 3999ms
