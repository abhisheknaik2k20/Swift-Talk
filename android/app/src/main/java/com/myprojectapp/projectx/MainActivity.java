package com.myprojectapp.projectx;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import android.media.AudioManager;
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import android.hardware.Camera;
import android.view.WindowManager;
import androidx.annotation.NonNull;

public class MainActivity extends FlutterFragmentActivity {
    private static final String MICROPHONE_CHANNEL = "samples.flutter.dev/microphone";
    private static final String SCREEN_CHANNEL = "app.channel.shared.data";
    
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        // Configure microphone channel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), MICROPHONE_CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("muteMicrophone")) {
                                AudioManager audioManager = (AudioManager) getSystemService(AUDIO_SERVICE);
                                audioManager.setMicrophoneMute(true);
                                result.success(null);
                            } else if (call.method.equals("unmuteMicrophone")) {
                                AudioManager audioManager = (AudioManager) getSystemService(AUDIO_SERVICE);
                                audioManager.setMicrophoneMute(false);
                                result.success(null);
                            } else {
                                result.notImplemented();
                            }
                        }
                );
        
        // Configure screen channel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), SCREEN_CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("keepScreenOn")) {
                                boolean enable = call.argument("enable");
                                keepScreenOn(enable);
                                result.success(null);
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }
    
    private void keepScreenOn(boolean enable) {
        runOnUiThread(() -> {
            if (enable) {
                getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
            } else {
                getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
            }
        });
    }
}