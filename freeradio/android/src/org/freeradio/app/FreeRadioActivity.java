package org.freeradio.app;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;

import org.qtproject.qt.android.bindings.QtActivity;

public final class FreeRadioActivity extends QtActivity {
    private static volatile Context applicationContext;

    public static native void dispatchNativeCommand(String command);

    @Override
    public void onCreate(Bundle state) {
        super.onCreate(state);
        applicationContext = getApplicationContext();
        if (Build.VERSION.SDK_INT >= 33
                && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)
                        != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[] { Manifest.permission.POST_NOTIFICATIONS }, 1001);
        }
    }

    public static void updatePlaybackState(boolean playing, String station, String track) {
        Context context = applicationContext;
        if (context == null) {
            return;
        }
        Intent intent = new Intent(context, PlaybackService.class)
                .setAction(PlaybackService.ACTION_UPDATE)
                .putExtra(PlaybackService.EXTRA_PLAYING, playing)
                .putExtra(PlaybackService.EXTRA_STATION, station)
                .putExtra(PlaybackService.EXTRA_TRACK, track);
        if (Build.VERSION.SDK_INT >= 26) {
            context.startForegroundService(intent);
        } else {
            context.startService(intent);
        }
    }

    public static void stopPlaybackService() {
        Context context = applicationContext;
        if (context != null) {
            context.stopService(new Intent(context, PlaybackService.class));
        }
    }

    static void sendCommandToNative(String command) {
        try {
            dispatchNativeCommand(command);
        } catch (UnsatisfiedLinkError ignored) {
            // A stale notification can outlive native startup. Qt reconnects after launch.
        }
    }
}
