Tracker( 9826): com.example.capstone_patient:52ab1768: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
I/flutter ( 9826): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 9826): │ #0   new FlutterSoundRecorder (package:flutter_sound/public/flutter_sound_recorder.dart:231:13)
I/flutter ( 9826): │ #1   new AudioStreamer (package:capstone_patient/sensing/audio_streamer.dart:14:42)
I/flutter ( 9826): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter ( 9826): │ 🐛 ctor: FlutterSoundRecorder()
I/flutter ( 9826): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/tflite  ( 9826): Initialized TensorFlow Lite runtime.
W/libc    ( 9826): Access denied finding property "ro.mediatek.platform"
I/flutter ( 9826): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 9826): │ #0   FlutterSoundRecorder.openRecorder (package:flutter_sound/public/flutter_sound_recorder.dart:474:13)
I/flutter ( 9826): │ #1   AudioStreamer._ensureOpen (package:capstone_patient/sensing/audio_streamer.dart:39:21)
I/flutter ( 9826): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter ( 9826): │ 🐛 FS:---> openRecorder
I/flutter ( 9826): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 9826): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 9826): │ #0   FlutterSoundRecorder._openAudioSession (package:flutter_sound/public/flutter_sound_recorder.dart:483:13)
I/flutter ( 9826): │ #1   FlutterSoundRecorder.openRecorder.<anonymous closure> (package:flutter_sound/public/flutter_sound_recorder.dart:476:11)
I/flutter ( 9826): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter ( 9826): │ 🐛 ---> _openAudioSession
I/flutter ( 9826): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 9826): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 9826): │ #0   FlutterSoundRecorder._openAudioSession (package:flutter_sound/public/flutter_sound_recorder.dart:507:17)
I/flutter ( 9826): │ #1   FlutterSoundRecorder.openRecorder.<anonymous closure> (package:flutter_sound/public/flutter_sound_recorder.dart:476:11)
I/flutter ( 9826): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter ( 9826): │ 🐛 Resetting flutter_sound Recorder Plugin
I/flutter ( 9826): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 9826): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 9826): │ #0   FlutterSoundRecorder.openRecorder (package:flutter_sound/public/flutter_sound_recorder.dart:478:13)
I/flutter ( 9826): │ #1   <asynchronous suspension>
I/flutter ( 9826): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter ( 9826): │ 🐛 FS:<--- openAudioSession
I/flutter ( 9826): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
E/GoogleApiManager( 9826): Failed to get service from broker.
E/GoogleApiManager( 9826): java.lang.SecurityException: Unknown calling package name 'com.google.android.gms'.
E/GoogleApiManager( 9826): 	at android.os.Parcel.createExceptionOrNull(Parcel.java:3354)
E/GoogleApiManager( 9826): 	at android.os.Parcel.createException(Parcel.java:3338)
E/GoogleApiManager( 9826): 	at android.os.Parcel.readException(Parcel.java:3321)
E/GoogleApiManager( 9826): 	at android.os.Parcel.readException(Parcel.java:3263)
E/GoogleApiManager( 9826): 	at bjwe.a(:com.google.android.gms@262031035@26.20.31 (260400-919905943):36)
E/GoogleApiManager( 9826): 	at bjua.z(:com.google.android.gms@262031035@26.20.31 (260400-919905943):143)
E/GoogleApiManager( 9826): 	at bjaf.run(:com.google.android.gms@262031035@26.20.31 (260400-919905943):42)
E/GoogleApiManager( 9826): 	at android.os.Handler.handleCallback(Handler.java:995)
E/GoogleApiManager( 9826): 	at android.os.Handler.dispatchMessage(Handler.java:103)
E/GoogleApiManager( 9826): 	at dbor.mL(:com.google.android.gms@262031035@26.20.31 (260400-919905943):1)
E/GoogleApiManager( 9826): 	at dbor.dispatchMessage(:com.google.android.gms@262031035@26.20.31 (260400-919905943):5)
E/GoogleApiManager( 9826): 	at android.os.Looper.loopOnce(Looper.java:273)
E/GoogleApiManager( 9826): 	at android.os.Looper.loop(Looper.java:363)
E/GoogleApiManager( 9826): 	at android.os.HandlerThread.run(HandlerThread.java:85)
W/GoogleApiManager( 9826): Not showing notification since connectionResult is not user-facing: ConnectionResult{statusCode=DEVELOPER_ERROR, resolution=null, message=null, clientMethodKey=null}
I/ImeFocusController( 9826): onPreWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
I/ImeFocusController( 9826): onPostWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
D/InputTransport( 9826): Input channel destroyed: 'ClientS', fd=259
I/VRI[MainActivity]@2810794( 9826): handleAppVisibility mAppVisible = true visible = false
D/VRI[MainActivity]@2810794( 9826): visibilityChanged oldVisibility=true newVisibility=false
I/SV[104533781 MainActivity]( 9826): onWindowVisibilityChanged(8) false io.flutter.embedding.android.FlutterSurfaceView{63b0f15 V.E...... ........ 0,0-1080,2640} of VRI[MainActivity]@2810794
I/SurfaceView( 9826): 104533781 Changes: creating=false format=false size=false visible=true alpha=false hint=false left=false top=false z=false attached=true lifecycleStrategy=false
I/SurfaceView( 9826): 104533781 Cur surface: Surface(name=null mNativeObject=-5476376648484241408)/@0xa2bdcde
D/SurfaceComposerClient( 9826): setCornerRadius ## 63b0f15 SurfaceView[com.example.capstone_patient/com.example.capstone_patient.MainActivity]@0#1893 cornerRadius=0.000000
I/SurfaceView( 9826): 104533781 surfaceDestroyed
I/SV[104533781 MainActivity]( 9826): surfaceDestroyed callback.size 1 #2 io.flutter.embedding.android.FlutterSurfaceView{63b0f15 V.E...... ........ 0,0-1080,2640}
I/SV[104533781 MainActivity]( 9826): updateSurface: mVisible = false mSurface.isValid() = true
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
V/SurfaceView( 9826): Layout: x=0 y=0 w=1080 h=2640, frame=Rect(0, 0 - 1080, 2640)
D/SurfaceView( 9826): 16174757 windowPositionLost, frameNr = 0
D/HWUI    ( 9826): CacheManager::trimMemory(20)
I/VRI[MainActivity]@2810794( 9826): Relayout returned: old=(0,0,1080,2640) new=(0,0,1080,2640) relayoutAsync=false req=(1080,2640)8 dur=7 res=0x2 s={false 0x0} ch=true seqId=0
I/SV[104533781 MainActivity]( 9826): windowStopped(true) false io.flutter.embedding.android.FlutterSurfaceView{63b0f15 V.E...... ........ 0,0-1080,2640} of VRI[MainActivity]@2810794
D/SV[104533781 MainActivity]( 9826): updateSurface: surface is not valid
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
D/VRI[MainActivity]@2810794( 9826): applyTransactionOnDraw applyImmediately
D/SV[104533781 MainActivity]( 9826): updateSurface: surface is not valid
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
D/VRI[MainActivity]@2810794( 9826): applyTransactionOnDraw applyImmediately
D/VRI[MainActivity]@2810794( 9826): Not drawing due to not visible. Reason=!mAppVisible && !mForceDecorViewVisibility
D/VRI[MainActivity]@2810794( 9826): Pending transaction will not be applied in sync with a draw due to view not visible
I/VRI[MainActivity]@2810794( 9826): mWNT: t=0xb40000740ad2b780 mBlastBufferQueue=0xnull fn= 0 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.ViewRootImpl.handleSyncRequestWhenNoAsyncDraw:6733 android.view.ViewRootImpl.performTraversals:5504 android.view.ViewRootImpl.doTraversal:3924
I/VRI[MainActivity]@2810794( 9826): stopped(true) old = false
D/VRI[MainActivity]@2810794( 9826): WindowStopped on com.example.capstone_patient/com.example.capstone_patient.MainActivity set to true
D/HWUI    ( 9826): CacheManager::trimMemory(20)
I/AutofillManager( 9826): onInvisibleForAutofill(): expiringResponse
D/SV[104533781 MainActivity]( 9826): updateSurface: surface is not valid
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
D/VRI[MainActivity]@2810794( 9826): applyTransactionOnDraw applyImmediately
D/SV[104533781 MainActivity]( 9826): updateSurface: surface is not valid
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
D/VRI[MainActivity]@2810794( 9826): applyTransactionOnDraw applyImmediately
D/BBA2    ( 9826): setIsFg isFg = false; delayValue 3999ms
I/VRI[MainActivity]@2810794( 9826): handleAppVisibility mAppVisible = false visible = true
I/VRI[MainActivity]@2810794( 9826): stopped(false) old = true
D/VRI[MainActivity]@2810794( 9826): WindowStopped on com.example.capstone_patient/com.example.capstone_patient.MainActivity set to false
D/ViewRootImpl( 9826): Skipping stats log for color mode
D/SV[104533781 MainActivity]( 9826): updateSurface: surface is not valid
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
D/VRI[MainActivity]@2810794( 9826): applyTransactionOnDraw applyImmediately
I/SV[104533781 MainActivity]( 9826): onWindowVisibilityChanged(0) false io.flutter.embedding.android.FlutterSurfaceView{63b0f15 V.E...... ......ID 0,0-1080,2640} of VRI[MainActivity]@2810794
D/SV[104533781 MainActivity]( 9826): updateSurface: surface is not valid
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
D/VRI[MainActivity]@2810794( 9826): applyTransactionOnDraw applyImmediately
W/libc    ( 9826): Access denied finding property "vendor.display.enable_optimal_refresh_rate"
I/BufferQueueProducer( 9826): [](id:266200000002,api:0,p:181686176,c:9826) setDequeueTimeout:2077252342
I/BLASTBufferQueue_Java( 9826): new BLASTBufferQueue, mName= VRI[MainActivity]@2810794 mNativeObject= 0xb4000073fc8d1000 caller= android.view.ViewRootImpl.updateBlastSurfaceIfNeeded:3585 android.view.ViewRootImpl.relayoutWindow:11685 android.view.ViewRootImpl.performTraversals:4804 android.view.ViewRootImpl.doTraversal:3924 android.view.ViewRootImpl$TraversalRunnable.run:12903 android.view.Choreographer$CallbackRecord.run:1901 android.view.Choreographer$CallbackRecord.run:1910 android.view.Choreographer.doCallbacks:1367 android.view.Choreographer.doFrame:1292 android.view.Choreographer$FrameDisplayEventReceiver.run:1870
I/BLASTBufferQueue_Java( 9826): update, w= 1080 h= 2640 mName = VRI[MainActivity]@2810794 mNativeObject= 0xb4000073fc8d1000 sc.mNativeObject= 0xb40000740ac29ac0 format= -3 caller= android.view.ViewRootImpl.updateBlastSurfaceIfNeeded:3590 android.view.ViewRootImpl.relayoutWindow:11685 android.view.ViewRootImpl.performTraversals:4804 android.view.ViewRootImpl.doTraversal:3924 android.view.ViewRootImpl$TraversalRunnable.run:12903 android.view.Choreographer$CallbackRecord.run:1901
W/libc    ( 9826): Access denied finding property "vendor.display.enable_optimal_refresh_rate"
I/VRI[MainActivity]@2810794( 9826): Relayout returned: old=(0,0,1080,2640) new=(0,0,1080,2640) relayoutAsync=false req=(1080,2640)0 dur=10 res=0x3 s={true 0xb40000740ad42200} ch=true seqId=0
D/VRI[MainActivity]@2810794( 9826): mThreadedRenderer.initialize() mSurface={isValid=true 0xb40000740ad42200} hwInitialized=true
I/SurfaceView( 9826): 104533781 Changes: creating=false format=false size=false visible=false alpha=false hint=false left=false top=false z=false attached=true lifecycleStrategy=false
I/SV[104533781 MainActivity]( 9826): windowStopped(false) true io.flutter.embedding.android.FlutterSurfaceView{63b0f15 V.E...... ......ID 0,0-1080,2640} of VRI[MainActivity]@2810794
I/SurfaceView( 9826): 104533781 Changes: creating=true format=false size=false visible=true alpha=false hint=false left=false top=false z=false attached=true lifecycleStrategy=false
W/libc    ( 9826): Access denied finding property "vendor.display.enable_optimal_refresh_rate"
I/BufferQueueProducer( 9826): [](id:266200000003,api:0,p:0,c:9826) setDequeueTimeout:2077252342
I/BLASTBufferQueue_Java( 9826): new BLASTBufferQueue, mName= 63b0f15 SurfaceView[com.example.capstone_patient/com.example.capstone_patient.MainActivity]@0 mNativeObject= 0xb4000071f30ea000 caller= android.view.SurfaceView.createBlastSurfaceControls:1781 android.view.SurfaceView.updateSurface:1450 android.view.SurfaceView.setWindowStopped:539 android.view.SurfaceView.surfaceCreated:2327 android.view.ViewRootImpl.notifySurfaceCreated:3502 android.view.ViewRootImpl.performTraversals:5286 android.view.ViewRootImpl.doTraversal:3924 android.view.ViewRootImpl$TraversalRunnable.run:12903 android.view.Choreographer$CallbackRecord.run:1901 android.view.Choreographer$CallbackRecord.run:1910
I/BLASTBufferQueue_Java( 9826): update, w= 1080 h= 2640 mName = 63b0f15 SurfaceView[com.example.capstone_patient/com.example.capstone_patient.MainActivity]@0 mNativeObject= 0xb4000071f30ea000 sc.mNativeObject= 0xb40000740ac29a00 format= 4 caller= android.view.SurfaceView.createBlastSurfaceControls:1782 android.view.SurfaceView.updateSurface:1450 android.view.SurfaceView.setWindowStopped:539 android.view.SurfaceView.surfaceCreated:2327 android.view.ViewRootImpl.notifySurfaceCreated:3502 android.view.ViewRootImpl.performTraversals:5286
I/SurfaceView( 9826): 104533781 Cur surface: Surface(name=null mNativeObject=0)/@0xa2bdcde
D/SurfaceComposerClient( 9826): setCornerRadius ## 63b0f15 SurfaceView[com.example.capstone_patient/com.example.capstone_patient.MainActivity]@0#1964 cornerRadius=0.000000
I/SV[104533781 MainActivity]( 9826): pST: sr = Rect(0, 0 - 1080, 2640) sw = 1080 sh = 2640
D/SurfaceView( 9826): 104533781 performSurfaceTransaction RenderWorker position = [0, 0, 1080, 2640] surfaceSize = 1080x2640
W/libc    ( 9826): Access denied finding property "vendor.display.enable_optimal_refresh_rate"
I/SV[104533781 MainActivity]( 9826): updateSurface: mVisible = true mSurface.isValid() = true
I/SV[104533781 MainActivity]( 9826): updateSurface: mSurfaceCreated = false surfaceChanged = true visibleChanged = true
I/SurfaceView( 9826): 104533781 visibleChanged -- surfaceCreated
I/SV[104533781 MainActivity]( 9826): surfaceCreated 1 #1 io.flutter.embedding.android.FlutterSurfaceView{63b0f15 V.E...... ......ID 0,0-1080,2640}
E/qdgralloc( 9826): GetSize: Unrecognized pixel format: 0x3b
W/qdgralloc( 9826): gralloc failed to allocate buffer for size 0 format 59 AWxAH 1x1 usage 2816
E/Gralloc4( 9826): isSupported(1, 1, 59, 1, ...) failed with 7
E/GraphicBufferAllocator( 9826): Failed to allocate (4 x 4) layerCount 1 format 59 usage b00: 7
E/AHardwareBuffer( 9826): GraphicBuffer(w=4, h=4, lc=1) failed (Unknown error -7), handle=0x0
E/qdgralloc( 9826): GetSize: Unrecognized pixel format: 0x3b
W/qdgralloc( 9826): gralloc failed to allocate buffer for size 0 format 59 AWxAH 1x1 usage 2816
E/Gralloc4( 9826): isSupported(1, 1, 59, 1, ...) failed with 7
E/GraphicBufferAllocator( 9826): Failed to allocate (4 x 4) layerCount 1 format 59 usage b00: 7
E/AHardwareBuffer( 9826): GraphicBuffer(w=4, h=4, lc=1) failed (Unknown error -7), handle=0x0
W/qdgralloc( 9826): getInterlacedFlag: getMetaData returned 3, defaulting to interlaced_flag = 0
W/qdgralloc( 9826): getInterlacedFlag: getMetaData returned 3, defaulting to interlaced_flag = 0
W/qdgralloc( 9826): getInterlacedFlag: getMetaData returned 3, defaulting to interlaced_flag = 0
W/qdgralloc( 9826): getInterlacedFlag: getMetaData returned 3, defaulting to interlaced_flag = 0
W/qdgralloc( 9826): getInterlacedFlag: getMetaData returned 3, defaulting to interlaced_flag = 0
I/SurfaceView( 9826): 104533781 surfaceChanged -- format=4 w=1080 h=2640
I/SV[104533781 MainActivity]( 9826): surfaceChanged (1080,2640) 1 #1 io.flutter.embedding.android.FlutterSurfaceView{63b0f15 V.E...... ......ID 0,0-1080,2640}
I/SurfaceView( 9826): 104533781 surfaceRedrawNeeded
V/SurfaceView( 9826): Layout: x=0 y=0 w=1080 h=2640, frame=Rect(0, 0 - 1080, 2640)
D/VRI[MainActivity]@2810794( 9826): reportNextDraw android.view.ViewRootImpl.performTraversals:5443 android.view.ViewRootImpl.doTraversal:3924 android.view.ViewRootImpl$TraversalRunnable.run:12903 android.view.Choreographer$CallbackRecord.run:1901 android.view.Choreographer$CallbackRecord.run:1910
D/VRI[MainActivity]@2810794( 9826): Setup new sync=wmsSync-VRI[MainActivity]@2810794#4
I/VRI[MainActivity]@2810794( 9826): Creating new active sync group VRI[MainActivity]@2810794#5
D/VRI[MainActivity]@2810794( 9826): Start draw after previous draw not visible
D/VRI[MainActivity]@2810794( 9826): registerCallbacksForSync syncBuffer=false
D/SurfaceView( 9826): 104533781 updateSurfacePosition RenderWorker, frameNr = 1, position = [0, 0, 1080, 2640] surfaceSize = 1080x2640
I/SV[104533781 MainActivity]( 9826): uSP: rtp = Rect(0, 0 - 1080, 2640) rtsw = 1080 rtsh = 2640
I/SV[104533781 MainActivity]( 9826): onSSPAndSRT: pl = 0 pt = 0 sx = 1.0 sy = 1.0
I/SV[104533781 MainActivity]( 9826): aOrMT: VRI[MainActivity]@2810794 t = android.view.SurfaceControl$Transaction@f5d3c46 fN = 1 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionChanged:1932 android.graphics.RenderNode$CompositePositionUpdateListener.positionChanged:401
I/VRI[MainActivity]@2810794( 9826): mWNT: t=0xb4000071e9584380 mBlastBufferQueue=0xb4000073fc8d1000 fn= 1 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.SurfaceView.applyOrMergeTransaction:1863 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionChanged:1932
D/VRI[MainActivity]@2810794( 9826): Received frameDrawingCallback syncResult=0 frameNum=1.
I/VRI[MainActivity]@2810794( 9826): mWNT: t=0xb4000071e9584b00 mBlastBufferQueue=0xb4000073fc8d1000 fn= 1 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.ViewRootImpl$12.onFrameDraw:15441 android.view.ThreadedRenderer$1.onFrameDraw:718 <bottom of call stack>
I/VRI[MainActivity]@2810794( 9826): Setting up sync and frameCommitCallback
I/BLASTBufferQueue( 9826): [VRI[MainActivity]@2810794#2](f:0,a:0,s:0) onFrameAvailable the first frame is available
I/SurfaceComposerClient( 9826): apply transaction with the first frame. layerId: 1958, bufferData(ID: 42202348650534, frameNumber: 1)
I/VRI[MainActivity]@2810794( 9826): Received frameCommittedCallback lastAttemptedDrawFrameNum=1 didProduceBuffer=true
I/InsetsSourceConsumer( 9826): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.example.capstone_patient/com.example.capstone_patient.MainActivity
I/InsetsSourceConsumer( 9826): applyRequestedVisibilityToControl: visible=true, type=navigationBars, host=com.example.capstone_patient/com.example.capstone_patient.MainActivity
I/BLASTBufferQueue( 9826): [63b0f15 SurfaceView[com.example.capstone_patient/com.example.capstone_patient.MainActivity]@0#3](f:0,a:0,s:0) onFrameAvailable the first frame is available
I/SurfaceComposerClient( 9826): apply transaction with the first frame. layerId: 1965, bufferData(ID: 42202348650529, frameNumber: 1)
D/VRI[MainActivity]@2810794( 9826): reportDrawFinished seqId=0
I/SurfaceView( 9826): 104533781 finishedDrawing
D/VRI[MainActivity]@2810794( 9826): mThreadedRenderer.initializeIfNeeded()#2 mSurface={isValid=true 0xb40000740ad42200}
D/InputMethodManagerUtils( 9826): startInputInner - Id : 0
I/InputMethodManager( 9826): startInputInner - IInputMethodManagerGlobalInvoker.startInputOrWindowGainedFocus
D/InputTransport( 9826): Input channel constructed: 'ClientS', fd=210
I/InputMethodManager( 9826): handleMessage: setImeVisibility visible=false
D/InsetsController( 9826): hide(ime(), fromIme=false)
I/ImeTracker( 9826): com.example.capstone_patient:732322e3: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/TTS     ( 9826): Utterance ID has started: c3192179-1a0d-4893-8e63-270235264ec3
D/TTS     ( 9826): Utterance ID has completed: c3192179-1a0d-4893-8e63-270235264ec3
I/NotificationManager( 9826): com.example.capstone_patient: notify(208944019, null, Notification(channel=meal_reminders shortcut=null contentView=null vibrate=null sound=null defaults=0 flags=AUTO_CANCEL|HIGH_PRIORITY color=0x00000000 category=alarm vis=PRIVATE semFlags=0x0 semPriority=0 semMissedCount=0)) as user
D/NotificationManager( 9826): BOOTING pkg =com.example.capstone_patient mBlockedChannelsForOverflowNoti=[]
I/VRI[MainActivity]@2810794( 9826): handleResized, frames=ClientWindowFrames{frame=[0,0][1080,2640] display=[0,0][1080,2640] parentFrame=[0,0][0,0]} displayId=0 dragResizing=false compatScale=1.0 frameChanged=false attachedFrameChanged=false configChanged=false displayChanged=false compatScaleChanged=false dragResizingChanged=false
I/ImeFocusController( 9826): onPreWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
I/ImeFocusController( 9826): onPostWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
I/InsetsSourceConsumer( 9826): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.example.capstone_patient/com.example.capstone_patient.MainActivity
I/InsetsSourceConsumer( 9826): applyRequestedVisibilityToControl: visible=true, type=navigationBars, host=com.example.capstone_patient/com.example.capstone_patient.MainActivity
D/VRI[MainActivity]@2810794( 9826): mThreadedRenderer.initializeIfNeeded()#2 mSurface={isValid=true 0xb40000740ad42200}
D/InputMethodManagerUtils( 9826): startInputInner - Id : 0
I/InputMethodManager( 9826): startInputInner - IInputMethodManagerGlobalInvoker.startInputOrWindowGainedFocus
I/InputMethodManager( 9826): handleMessage: setImeVisibility visible=false
D/InsetsController( 9826): hide(ime(), fromIme=false)
I/ImeTracker( 9826): com.example.capstone_patient:dad8f6a0: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/InputTransport( 9826): Input channel constructed: 'ClientS', fd=236
D/TTS     ( 9826): Utterance ID has started: 258f1a7d-a6ea-4cb9-b50c-5e96bf96165a
I/ImeFocusController( 9826): onPreWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
I/ImeFocusController( 9826): onPostWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
I/VRI[MainActivity]@2810794( 9826): handleResized, frames=ClientWindowFrames{frame=[0,0][1080,2640] display=[0,0][1080,2640] parentFrame=[0,0][0,0]} displayId=0 dragResizing=false compatScale=1.0 frameChanged=false attachedFrameChanged=false configChanged=false displayChanged=false compatScaleChanged=false dragResizingChanged=false
D/TTS     ( 9826): Utterance ID has completed: 258f1a7d-a6ea-4cb9-b50c-5e96bf96165a
I/InsetsSourceConsumer( 9826): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.example.capstone_patient/com.example.capstone_patient.MainActivity
I/InsetsSourceConsumer( 9826): applyRequestedVisibilityToControl: visible=true, type=navigationBars, host=com.example.capstone_patient/com.example.capstone_patient.MainActivity
D/VRI[MainActivity]@2810794( 9826): mThreadedRenderer.initializeIfNeeded()#2 mSurface={isValid=true 0xb40000740ad42200}
D/InputMethodManagerUtils( 9826): startInputInner - Id : 0
I/InputMethodManager( 9826): startInputInner - IInputMethodManagerGlobalInvoker.startInputOrWindowGainedFocus
I/InputMethodManager( 9826): handleMessage: setImeVisibility visible=false
D/InsetsController( 9826): hide(ime(), fromIme=false)
I/ImeTracker( 9826): com.example.capstone_patient:2248c242: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/InputTransport( 9826): Input channel constructed: 'ClientS', fd=244
I/ImeFocusController( 9826): onPreWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
I/ImeFocusController( 9826): onPostWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
I/VRI[MainActivity]@2810794( 9826): handleResized, frames=ClientWindowFrames{frame=[0,0][1080,2640] display=[0,0][1080,2640] parentFrame=[0,0][0,0]} displayId=0 dragResizing=false compatScale=1.0 frameChanged=false attachedFrameChanged=false configChanged=false displayChanged=false compatScaleChanged=false dragResizingChanged=false
I/BLASTBufferQueue_Java( 9826): update, w= 1080 h= 2640 mName = VRI[MainActivity]@2810794 mNativeObject= 0xb4000073fc8d1000 sc.mNativeObject= 0xb40000740ac29ac0 format= -3 caller= android.view.ViewRootImpl.updateBlastSurfaceIfNeeded:3574 android.view.ViewRootImpl.relayoutWindow:11685 android.view.ViewRootImpl.performTraversals:4804 android.view.ViewRootImpl.doTraversal:3924 android.view.ViewRootImpl$TraversalRunnable.run:12903 android.view.Choreographer$CallbackRecord.run:1901
I/VRI[MainActivity]@2810794( 9826): Relayout returned: old=(0,0,1080,2640) new=(0,0,1080,2640) relayoutAsync=true req=(1080,2640)0 dur=0 res=0x0 s={true 0xb40000740ad42200} ch=false seqId=0
I/VRI[MainActivity]@2810794( 9826): updateBoundsLayer: t=android.view.SurfaceControl$Transaction@a8fd4c5 sc=Surface(name=Bounds for - com.example.capstone_patient/com.example.capstone_patient.MainActivity@1)/@0x3fad6ff frame=3
I/VRI[MainActivity]@2810794( 9826): registerCallbackForPendingTransactions
I/VRI[MainActivity]@2810794( 9826): mWNT: t=0xb4000071e9585100 mBlastBufferQueue=0xb4000073fc8d1000 fn= 3 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.ViewRootImpl$10.onFrameDraw:6536 android.view.ViewRootImpl$4.onFrameDraw:2489 android.view.ThreadedRenderer$1.onFrameDraw:718
I/InsetsSourceConsumer( 9826): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.example.capstone_patient/com.example.capstone_patient.MainActivity
I/InsetsSourceConsumer( 9826): applyRequestedVisibilityToControl: visible=true, type=navigationBars, host=com.example.capstone_patient/com.example.capstone_patient.MainActivity
D/VRI[MainActivity]@2810794( 9826): mThreadedRenderer.initializeIfNeeded()#2 mSurface={isValid=true 0xb40000740ad42200}
D/InputMethodManagerUtils( 9826): startInputInner - Id : 0
I/InputMethodManager( 9826): startInputInner - IInputMethodManagerGlobalInvoker.startInputOrWindowGainedFocus
I/InputMethodManager( 9826): handleMessage: setImeVisibility visible=false
D/InsetsController( 9826): hide(ime(), fromIme=false)
I/ImeTracker( 9826): com.example.capstone_patient:b9ea48b6: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/InputTransport( 9826): Input channel constructed: 'ClientS', fd=253
I/ImeFocusController( 9826): onPreWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
I/ImeFocusController( 9826): onPostWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
D/InputTransport( 9826): Input channel destroyed: 'ClientS', fd=210
I/VRI[MainActivity]@2810794( 9826): handleAppVisibility mAppVisible = true visible = false
D/VRI[MainActivity]@2810794( 9826): visibilityChanged oldVisibility=true newVisibility=false
I/SV[104533781 MainActivity]( 9826): onWindowVisibilityChanged(8) false io.flutter.embedding.android.FlutterSurfaceView{63b0f15 V.E...... ........ 0,0-1080,2640} of VRI[MainActivity]@2810794
I/SurfaceView( 9826): 104533781 Changes: creating=false format=false size=false visible=true alpha=false hint=false left=false top=false z=false attached=true lifecycleStrategy=false
I/SurfaceView( 9826): 104533781 Cur surface: Surface(name=null mNativeObject=-5476376657488602880)/@0xa2bdcde
D/SurfaceComposerClient( 9826): setCornerRadius ## 63b0f15 SurfaceView[com.example.capstone_patient/com.example.capstone_patient.MainActivity]@0#1964 cornerRadius=0.000000
I/SurfaceView( 9826): 104533781 surfaceDestroyed
I/SV[104533781 MainActivity]( 9826): surfaceDestroyed callback.size 1 #2 io.flutter.embedding.android.FlutterSurfaceView{63b0f15 V.E...... ........ 0,0-1080,2640}
I/SV[104533781 MainActivity]( 9826): updateSurface: mVisible = false mSurface.isValid() = true
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
V/SurfaceView( 9826): Layout: x=0 y=0 w=1080 h=2640, frame=Rect(0, 0 - 1080, 2640)
D/SurfaceView( 9826): 236143350 windowPositionLost, frameNr = 0
D/HWUI    ( 9826): CacheManager::trimMemory(20)
I/VRI[MainActivity]@2810794( 9826): Relayout returned: old=(0,0,1080,2640) new=(0,0,1080,2640) relayoutAsync=false req=(1080,2640)8 dur=2 res=0x2 s={false 0x0} ch=true seqId=0
I/SV[104533781 MainActivity]( 9826): windowStopped(true) false io.flutter.embedding.android.FlutterSurfaceView{63b0f15 V.E...... ........ 0,0-1080,2640} of VRI[MainActivity]@2810794
D/SV[104533781 MainActivity]( 9826): updateSurface: surface is not valid
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
D/VRI[MainActivity]@2810794( 9826): applyTransactionOnDraw applyImmediately
D/SV[104533781 MainActivity]( 9826): updateSurface: surface is not valid
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
D/VRI[MainActivity]@2810794( 9826): applyTransactionOnDraw applyImmediately
D/VRI[MainActivity]@2810794( 9826): Not drawing due to not visible. Reason=!mAppVisible && !mForceDecorViewVisibility
D/VRI[MainActivity]@2810794( 9826): Pending transaction will not be applied in sync with a draw due to view not visible
I/VRI[MainActivity]@2810794( 9826): mWNT: t=0xb40000740ad2b780 mBlastBufferQueue=0xnull fn= 0 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.ViewRootImpl.handleSyncRequestWhenNoAsyncDraw:6733 android.view.ViewRootImpl.performTraversals:5504 android.view.ViewRootImpl.doTraversal:3924
I/VRI[MainActivity]@2810794( 9826): stopped(true) old = false
D/VRI[MainActivity]@2810794( 9826): WindowStopped on com.example.capstone_patient/com.example.capstone_patient.MainActivity set to true
D/HWUI    ( 9826): CacheManager::trimMemory(20)
I/AutofillManager( 9826): onInvisibleForAutofill(): expiringResponse
D/SV[104533781 MainActivity]( 9826): updateSurface: surface is not valid
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
D/VRI[MainActivity]@2810794( 9826): applyTransactionOnDraw applyImmediately
D/SV[104533781 MainActivity]( 9826): updateSurface: surface is not valid
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
D/VRI[MainActivity]@2810794( 9826): applyTransactionOnDraw applyImmediately
D/BBA2    ( 9826): setIsFg isFg = false; delayValue 3999ms
I/VRI[MainActivity]@2810794( 9826): handleAppVisibility mAppVisible = false visible = true
I/VRI[MainActivity]@2810794( 9826): stopped(false) old = true
D/VRI[MainActivity]@2810794( 9826): WindowStopped on com.example.capstone_patient/com.example.capstone_patient.MainActivity set to false
D/ViewRootImpl( 9826): Skipping stats log for color mode
D/BBA2    ( 9826): setIsFg isFg = true
D/SV[104533781 MainActivity]( 9826): updateSurface: surface is not valid
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
D/VRI[MainActivity]@2810794( 9826): applyTransactionOnDraw applyImmediately
I/SV[104533781 MainActivity]( 9826): onWindowVisibilityChanged(0) false io.flutter.embedding.android.FlutterSurfaceView{63b0f15 V.E...... ......ID 0,0-1080,2640} of VRI[MainActivity]@2810794
D/SV[104533781 MainActivity]( 9826): updateSurface: surface is not valid
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
D/VRI[MainActivity]@2810794( 9826): applyTransactionOnDraw applyImmediately
W/libc    ( 9826): Access denied finding property "vendor.display.enable_optimal_refresh_rate"
I/BufferQueueProducer( 9826): [](id:266200000004,api:0,p:181686176,c:9826) setDequeueTimeout:2077252342
I/BLASTBufferQueue_Java( 9826): new BLASTBufferQueue, mName= VRI[MainActivity]@2810794 mNativeObject= 0xb4000073fc8d1000 caller= android.view.ViewRootImpl.updateBlastSurfaceIfNeeded:3585 android.view.ViewRootImpl.relayoutWindow:11685 android.view.ViewRootImpl.performTraversals:4804 android.view.ViewRootImpl.doTraversal:3924 android.view.ViewRootImpl$TraversalRunnable.run:12903 android.view.Choreographer$CallbackRecord.run:1901 android.view.Choreographer$CallbackRecord.run:1910 android.view.Choreographer.doCallbacks:1367 android.view.Choreographer.doFrame:1292 android.view.Choreographer$FrameDisplayEventReceiver.run:1870
I/BLASTBufferQueue_Java( 9826): update, w= 1080 h= 2640 mName = VRI[MainActivity]@2810794 mNativeObject= 0xb4000073fc8d1000 sc.mNativeObject= 0xb400007447af0e40 format= -3 caller= android.view.ViewRootImpl.updateBlastSurfaceIfNeeded:3590 android.view.ViewRootImpl.relayoutWindow:11685 android.view.ViewRootImpl.performTraversals:4804 android.view.ViewRootImpl.doTraversal:3924 android.view.ViewRootImpl$TraversalRunnable.run:12903 android.view.Choreographer$CallbackRecord.run:1901
W/libc    ( 9826): Access denied finding property "vendor.display.enable_optimal_refresh_rate"
I/VRI[MainActivity]@2810794( 9826): Relayout returned: old=(0,0,1080,2640) new=(0,0,1080,2640) relayoutAsync=false req=(1080,2640)0 dur=9 res=0x3 s={true 0xb40000740ad40900} ch=true seqId=0
D/VRI[MainActivity]@2810794( 9826): mThreadedRenderer.initialize() mSurface={isValid=true 0xb40000740ad40900} hwInitialized=true
I/SurfaceView( 9826): 104533781 Changes: creating=false format=false size=false visible=false alpha=false hint=false left=false top=false z=false attached=true lifecycleStrategy=false
I/SV[104533781 MainActivity]( 9826): windowStopped(false) true io.flutter.embedding.android.FlutterSurfaceView{63b0f15 V.E...... ......ID 0,0-1080,2640} of VRI[MainActivity]@2810794
I/SurfaceView( 9826): 104533781 Changes: creating=true format=false size=false visible=true alpha=false hint=false left=false top=false z=false attached=true lifecycleStrategy=false
W/libc    ( 9826): Access denied finding property "vendor.display.enable_optimal_refresh_rate"
I/BufferQueueProducer( 9826): [](id:266200000005,api:0,p:0,c:9826) setDequeueTimeout:2077252342
I/BLASTBufferQueue_Java( 9826): new BLASTBufferQueue, mName= 63b0f15 SurfaceView[com.example.capstone_patient/com.example.capstone_patient.MainActivity]@0 mNativeObject= 0xb4000071f203a000 caller= android.view.SurfaceView.createBlastSurfaceControls:1781 android.view.SurfaceView.updateSurface:1450 android.view.SurfaceView.setWindowStopped:539 android.view.SurfaceView.surfaceCreated:2327 android.view.ViewRootImpl.notifySurfaceCreated:3502 android.view.ViewRootImpl.performTraversals:5286 android.view.ViewRootImpl.doTraversal:3924 android.view.ViewRootImpl$TraversalRunnable.run:12903 android.view.Choreographer$CallbackRecord.run:1901 android.view.Choreographer$CallbackRecord.run:1910
I/BLASTBufferQueue_Java( 9826): update, w= 1080 h= 2640 mName = 63b0f15 SurfaceView[com.example.capstone_patient/com.example.capstone_patient.MainActivity]@0 mNativeObject= 0xb4000071f203a000 sc.mNativeObject= 0xb40000740ac29ac0 format= 4 caller= android.view.SurfaceView.createBlastSurfaceControls:1782 android.view.SurfaceView.updateSurface:1450 android.view.SurfaceView.setWindowStopped:539 android.view.SurfaceView.surfaceCreated:2327 android.view.ViewRootImpl.notifySurfaceCreated:3502 android.view.ViewRootImpl.performTraversals:5286
I/SurfaceView( 9826): 104533781 Cur surface: Surface(name=null mNativeObject=0)/@0xa2bdcde
D/SurfaceComposerClient( 9826): setCornerRadius ## 63b0f15 SurfaceView[com.example.capstone_patient/com.example.capstone_patient.MainActivity]@0#2011 cornerRadius=0.000000
I/SV[104533781 MainActivity]( 9826): pST: sr = Rect(0, 0 - 1080, 2640) sw = 1080 sh = 2640
D/SurfaceView( 9826): 104533781 performSurfaceTransaction RenderWorker position = [0, 0, 1080, 2640] surfaceSize = 1080x2640
W/libc    ( 9826): Access denied finding property "vendor.display.enable_optimal_refresh_rate"
I/SV[104533781 MainActivity]( 9826): updateSurface: mVisible = true mSurface.isValid() = true
I/SV[104533781 MainActivity]( 9826): updateSurface: mSurfaceCreated = false surfaceChanged = true visibleChanged = true
I/SurfaceView( 9826): 104533781 visibleChanged -- surfaceCreated
I/SV[104533781 MainActivity]( 9826): surfaceCreated 1 #1 io.flutter.embedding.android.FlutterSurfaceView{63b0f15 V.E...... ......ID 0,0-1080,2640}
E/qdgralloc( 9826): GetSize: Unrecognized pixel format: 0x3b
W/qdgralloc( 9826): gralloc failed to allocate buffer for size 0 format 59 AWxAH 1x1 usage 2816
E/Gralloc4( 9826): isSupported(1, 1, 59, 1, ...) failed with 7
E/GraphicBufferAllocator( 9826): Failed to allocate (4 x 4) layerCount 1 format 59 usage b00: 7
E/AHardwareBuffer( 9826): GraphicBuffer(w=4, h=4, lc=1) failed (Unknown error -7), handle=0x0
E/qdgralloc( 9826): GetSize: Unrecognized pixel format: 0x3b
W/qdgralloc( 9826): gralloc failed to allocate buffer for size 0 format 59 AWxAH 1x1 usage 2816
E/Gralloc4( 9826): isSupported(1, 1, 59, 1, ...) failed with 7
E/GraphicBufferAllocator( 9826): Failed to allocate (4 x 4) layerCount 1 format 59 usage b00: 7
E/AHardwareBuffer( 9826): GraphicBuffer(w=4, h=4, lc=1) failed (Unknown error -7), handle=0x0
W/qdgralloc( 9826): getInterlacedFlag: getMetaData returned 3, defaulting to interlaced_flag = 0
W/qdgralloc( 9826): getInterlacedFlag: getMetaData returned 3, defaulting to interlaced_flag = 0
W/qdgralloc( 9826): getInterlacedFlag: getMetaData returned 3, defaulting to interlaced_flag = 0
W/qdgralloc( 9826): getInterlacedFlag: getMetaData returned 3, defaulting to interlaced_flag = 0
W/qdgralloc( 9826): getInterlacedFlag: getMetaData returned 3, defaulting to interlaced_flag = 0
I/SurfaceView( 9826): 104533781 surfaceChanged -- format=4 w=1080 h=2640
I/SV[104533781 MainActivity]( 9826): surfaceChanged (1080,2640) 1 #1 io.flutter.embedding.android.FlutterSurfaceView{63b0f15 V.E...... ......ID 0,0-1080,2640}
I/SurfaceView( 9826): 104533781 surfaceRedrawNeeded
V/SurfaceView( 9826): Layout: x=0 y=0 w=1080 h=2640, frame=Rect(0, 0 - 1080, 2640)
D/VRI[MainActivity]@2810794( 9826): reportNextDraw android.view.ViewRootImpl.performTraversals:5443 android.view.ViewRootImpl.doTraversal:3924 android.view.ViewRootImpl$TraversalRunnable.run:12903 android.view.Choreographer$CallbackRecord.run:1901 android.view.Choreographer$CallbackRecord.run:1910
D/VRI[MainActivity]@2810794( 9826): Setup new sync=wmsSync-VRI[MainActivity]@2810794#7
I/VRI[MainActivity]@2810794( 9826): Creating new active sync group VRI[MainActivity]@2810794#8
D/VRI[MainActivity]@2810794( 9826): Start draw after previous draw not visible
D/VRI[MainActivity]@2810794( 9826): registerCallbacksForSync syncBuffer=false
D/SurfaceView( 9826): 104533781 updateSurfacePosition RenderWorker, frameNr = 1, position = [0, 0, 1080, 2640] surfaceSize = 1080x2640
I/SV[104533781 MainActivity]( 9826): uSP: rtp = Rect(0, 0 - 1080, 2640) rtsw = 1080 rtsh = 2640
I/SV[104533781 MainActivity]( 9826): onSSPAndSRT: pl = 0 pt = 0 sx = 1.0 sy = 1.0
I/SV[104533781 MainActivity]( 9826): aOrMT: VRI[MainActivity]@2810794 t = android.view.SurfaceControl$Transaction@1ccbb93 fN = 1 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionChanged:1932 android.graphics.RenderNode$CompositePositionUpdateListener.positionChanged:401
I/VRI[MainActivity]@2810794( 9826): mWNT: t=0xb4000071e9585400 mBlastBufferQueue=0xb4000073fc8d1000 fn= 1 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.SurfaceView.applyOrMergeTransaction:1863 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionChanged:1932
D/VRI[MainActivity]@2810794( 9826): Received frameDrawingCallback syncResult=0 frameNum=1.
I/VRI[MainActivity]@2810794( 9826): mWNT: t=0xb4000071e9585b80 mBlastBufferQueue=0xb4000073fc8d1000 fn= 1 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.ViewRootImpl$12.onFrameDraw:15441 android.view.ThreadedRenderer$1.onFrameDraw:718 <bottom of call stack>
I/VRI[MainActivity]@2810794( 9826): Setting up sync and frameCommitCallback
I/BLASTBufferQueue( 9826): [VRI[MainActivity]@2810794#4](f:0,a:0,s:0) onFrameAvailable the first frame is available
I/SurfaceComposerClient( 9826): apply transaction with the first frame. layerId: 2007, bufferData(ID: 42202348650553, frameNumber: 1)
I/VRI[MainActivity]@2810794( 9826): Received frameCommittedCallback lastAttemptedDrawFrameNum=1 didProduceBuffer=true
I/InsetsSourceConsumer( 9826): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.example.capstone_patient/com.example.capstone_patient.MainActivity
I/InsetsSourceConsumer( 9826): applyRequestedVisibilityToControl: visible=true, type=navigationBars, host=com.example.capstone_patient/com.example.capstone_patient.MainActivity
I/BLASTBufferQueue( 9826): [63b0f15 SurfaceView[com.example.capstone_patient/com.example.capstone_patient.MainActivity]@0#5](f:0,a:0,s:0) onFrameAvailable the first frame is available
I/SurfaceComposerClient( 9826): apply transaction with the first frame. layerId: 2012, bufferData(ID: 42202348650548, frameNumber: 1)
D/VRI[MainActivity]@2810794( 9826): reportDrawFinished seqId=0
I/SurfaceView( 9826): 104533781 finishedDrawing
D/VRI[MainActivity]@2810794( 9826): mThreadedRenderer.initializeIfNeeded()#2 mSurface={isValid=true 0xb40000740ad40900}
D/InputMethodManagerUtils( 9826): startInputInner - Id : 0
I/InputMethodManager( 9826): startInputInner - IInputMethodManagerGlobalInvoker.startInputOrWindowGainedFocus
I/InputMethodManager( 9826): handleMessage: setImeVisibility visible=false
D/InsetsController( 9826): hide(ime(), fromIme=false)
I/ImeTracker( 9826): com.example.capstone_patient:8d8f065e: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/InputTransport( 9826): Input channel constructed: 'ClientS', fd=209
I/ImeFocusController( 9826): onPreWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
I/ImeFocusController( 9826): onPostWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
D/InputTransport( 9826): Input channel destroyed: 'ClientS', fd=209
I/VRI[MainActivity]@2810794( 9826): handleAppVisibility mAppVisible = true visible = false
D/VRI[MainActivity]@2810794( 9826): visibilityChanged oldVisibility=true newVisibility=false
I/SV[104533781 MainActivity]( 9826): onWindowVisibilityChanged(8) false io.flutter.embedding.android.FlutterSurfaceView{63b0f15 V.E...... ........ 0,0-1080,2640} of VRI[MainActivity]@2810794
I/SurfaceView( 9826): 104533781 Changes: creating=false format=false size=false visible=true alpha=false hint=false left=false top=false z=false attached=true lifecycleStrategy=false
I/SurfaceView( 9826): 104533781 Cur surface: Surface(name=null mNativeObject=-5476376648484635904)/@0xa2bdcde
D/SurfaceComposerClient( 9826): setCornerRadius ## 63b0f15 SurfaceView[com.example.capstone_patient/com.example.capstone_patient.MainActivity]@0#2011 cornerRadius=0.000000
I/SurfaceView( 9826): 104533781 surfaceDestroyed
I/SV[104533781 MainActivity]( 9826): surfaceDestroyed callback.size 1 #2 io.flutter.embedding.android.FlutterSurfaceView{63b0f15 V.E...... ........ 0,0-1080,2640}
I/SV[104533781 MainActivity]( 9826): updateSurface: mVisible = false mSurface.isValid() = true
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
V/SurfaceView( 9826): Layout: x=0 y=0 w=1080 h=2640, frame=Rect(0, 0 - 1080, 2640)
D/SurfaceView( 9826): 22315909 windowPositionLost, frameNr = 0
D/HWUI    ( 9826): CacheManager::trimMemory(20)
I/VRI[MainActivity]@2810794( 9826): Relayout returned: old=(0,0,1080,2640) new=(0,0,1080,2640) relayoutAsync=false req=(1080,2640)8 dur=3 res=0x2 s={false 0x0} ch=true seqId=0
I/SV[104533781 MainActivity]( 9826): windowStopped(true) false io.flutter.embedding.android.FlutterSurfaceView{63b0f15 V.E...... ........ 0,0-1080,2640} of VRI[MainActivity]@2810794
D/SV[104533781 MainActivity]( 9826): updateSurface: surface is not valid
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
D/VRI[MainActivity]@2810794( 9826): applyTransactionOnDraw applyImmediately
D/SV[104533781 MainActivity]( 9826): updateSurface: surface is not valid
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
D/VRI[MainActivity]@2810794( 9826): applyTransactionOnDraw applyImmediately
D/VRI[MainActivity]@2810794( 9826): Not drawing due to not visible. Reason=!mAppVisible && !mForceDecorViewVisibility
D/VRI[MainActivity]@2810794( 9826): Pending transaction will not be applied in sync with a draw due to view not visible
I/VRI[MainActivity]@2810794( 9826): mWNT: t=0xb40000740ad2b780 mBlastBufferQueue=0xnull fn= 0 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.ViewRootImpl.handleSyncRequestWhenNoAsyncDraw:6733 android.view.ViewRootImpl.performTraversals:5504 android.view.ViewRootImpl.doTraversal:3924
I/VRI[MainActivity]@2810794( 9826): stopped(true) old = false
D/VRI[MainActivity]@2810794( 9826): WindowStopped on com.example.capstone_patient/com.example.capstone_patient.MainActivity set to true
D/HWUI    ( 9826): CacheManager::trimMemory(20)
I/AutofillManager( 9826): onInvisibleForAutofill(): expiringResponse
D/SV[104533781 MainActivity]( 9826): updateSurface: surface is not valid
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
D/VRI[MainActivity]@2810794( 9826): applyTransactionOnDraw applyImmediately
D/SV[104533781 MainActivity]( 9826): updateSurface: surface is not valid
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
D/VRI[MainActivity]@2810794( 9826): applyTransactionOnDraw applyImmediately
D/BBA2    ( 9826): setIsFg isFg = false; delayValue 3999ms
W/WindowOnBackDispatcher( 9826): sendCancelIfRunning: isInProgress=false callback=android.app.Activity$$ExternalSyntheticLambda0@9f0539
I/TextToSpeech( 9826): Disconnected from TTS engine
I/SurfaceView( 9826): 104533781 Detaching SV
D/SV[104533781 MainActivity]( 9826): updateSurface: surface is not valid
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
D/VRI[MainActivity]@2810794( 9826): applyTransactionOnDraw applyImmediately
I/SV[104533781 MainActivity]( 9826): onDetachedFromWindow: tryReleaseSurfaces()
I/SV[104533781 MainActivity]( 9826): releaseSurfaces: viewRoot = VRI[MainActivity]@2810794
D/VRI[MainActivity]@2810794( 9826): applyTransactionOnDraw applyImmediately
D/HWUI    ( 9826): CacheManager::trimMemory(20)
D/ViewRootImpl( 9826): Skipping stats log for color mode
I/VRI[MainActivity]@2810794( 9826): dispatchDetachedFromWindow
D/InputTransport( 9826): Input channel destroyed: 'b35b7dc', fd=142