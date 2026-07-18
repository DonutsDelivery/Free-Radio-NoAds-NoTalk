package org.freeradio.app;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.AudioAttributes;
import android.media.AudioFocusRequest;
import android.media.AudioManager;
import android.media.MediaMetadata;
import android.media.session.MediaSession;
import android.media.session.PlaybackState;
import android.os.Build;
import android.os.IBinder;

public final class PlaybackService extends Service {
    static final String ACTION_UPDATE = "org.freeradio.app.UPDATE";
    static final String ACTION_PLAY = "org.freeradio.app.PLAY";
    static final String ACTION_PAUSE = "org.freeradio.app.PAUSE";
    static final String ACTION_STOP = "org.freeradio.app.STOP";
    static final String ACTION_NEXT = "org.freeradio.app.NEXT";
    static final String ACTION_PREVIOUS = "org.freeradio.app.PREVIOUS";
    static final String EXTRA_PLAYING = "playing";
    static final String EXTRA_STATION = "station";
    static final String EXTRA_TRACK = "track";

    private static final String CHANNEL_ID = "radio_playback";
    private static final int NOTIFICATION_ID = 7;

    private AudioManager audioManager;
    private AudioFocusRequest audioFocusRequest;
    private MediaSession mediaSession;
    private boolean playing;
    private boolean resumeOnFocusGain;
    private boolean noisyReceiverRegistered;
    private String station = "Free Radio";
    private String track = "";

    private final AudioManager.OnAudioFocusChangeListener focusListener = change -> {
        if (change == AudioManager.AUDIOFOCUS_GAIN) {
            if (resumeOnFocusGain) {
                resumeOnFocusGain = false;
                command("play");
            }
        } else if (change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT
                || change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK) {
            resumeOnFocusGain = playing;
            if (playing) {
                pauseForTransientFocusLoss();
            }
        } else if (change == AudioManager.AUDIOFOCUS_LOSS) {
            resumeOnFocusGain = false;
            if (playing) {
                playing = false;
                FreeRadioActivity.sendCommandToNative("pause");
                abandonAudioFocus();
                publishState();
            }
        }
    };

    private final BroadcastReceiver noisyReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (AudioManager.ACTION_AUDIO_BECOMING_NOISY.equals(intent.getAction()) && playing) {
                command("pause");
            }
        }
    };

    @Override
    public void onCreate() {
        super.onCreate();
        audioManager = (AudioManager) getSystemService(AUDIO_SERVICE);
        createNotificationChannel();
        createMediaSession();
        registerReceiver(noisyReceiver,
                new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY));
        noisyReceiverRegistered = true;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent == null) {
            publishState();
            return START_NOT_STICKY;
        }

        String action = intent.getAction();
        if (ACTION_STOP.equals(action)) {
            command("stop");
            stopPlaybackService();
            return START_NOT_STICKY;
        }
        if (ACTION_PLAY.equals(action)) {
            command("play");
        } else if (ACTION_PAUSE.equals(action)) {
            command("pause");
        } else if (ACTION_NEXT.equals(action)) {
            FreeRadioActivity.sendCommandToNative("next");
        } else if (ACTION_PREVIOUS.equals(action)) {
            FreeRadioActivity.sendCommandToNative("previous");
        } else if (ACTION_UPDATE.equals(action)) {
            playing = intent.getBooleanExtra(EXTRA_PLAYING, false);
            station = nonEmpty(intent.getStringExtra(EXTRA_STATION), "Free Radio");
            track = nonEmpty(intent.getStringExtra(EXTRA_TRACK), "");
            if (playing && !requestAudioFocus()) {
                playing = false;
                FreeRadioActivity.sendCommandToNative("pause");
            }
        }

        publishState();
        return START_NOT_STICKY;
    }

    private void createMediaSession() {
        mediaSession = new MediaSession(this, "FreeRadioPlayback");
        mediaSession.setCallback(new MediaSession.Callback() {
            @Override public void onPlay() { command("play"); }
            @Override public void onPause() { command("pause"); }
            @Override public void onStop() {
                command("stop");
                stopPlaybackService();
            }
            @Override public void onSkipToNext() {
                FreeRadioActivity.sendCommandToNative("next");
            }
            @Override public void onSkipToPrevious() {
                FreeRadioActivity.sendCommandToNative("previous");
            }
        });
        mediaSession.setActive(true);
    }

    private void command(String value) {
        if ("play".equals(value)) {
            if (!requestAudioFocus()) {
                return;
            }
            playing = true;
        } else if ("pause".equals(value) || "stop".equals(value)) {
            playing = false;
            abandonAudioFocus();
        }
        FreeRadioActivity.sendCommandToNative(value);
        publishState();
    }

    private void pauseForTransientFocusLoss() {
        playing = false;
        FreeRadioActivity.sendCommandToNative("pause");
        publishState();
    }

    private boolean requestAudioFocus() {
        AudioAttributes attributes = new AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build();
        int result;
        if (Build.VERSION.SDK_INT >= 26) {
            if (audioFocusRequest == null) {
                audioFocusRequest = new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                        .setAudioAttributes(attributes)
                        .setOnAudioFocusChangeListener(focusListener)
                        .setWillPauseWhenDucked(true)
                        .build();
            }
            result = audioManager.requestAudioFocus(audioFocusRequest);
        } else {
            result = audioManager.requestAudioFocus(focusListener,
                    AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN);
        }
        return result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED;
    }

    private void abandonAudioFocus() {
        if (Build.VERSION.SDK_INT >= 26 && audioFocusRequest != null) {
            audioManager.abandonAudioFocusRequest(audioFocusRequest);
        } else {
            audioManager.abandonAudioFocus(focusListener);
        }
    }

    private void publishState() {
        if (mediaSession == null) {
            return;
        }
        long actions = PlaybackState.ACTION_PLAY | PlaybackState.ACTION_PAUSE
                | PlaybackState.ACTION_STOP | PlaybackState.ACTION_SKIP_TO_NEXT
                | PlaybackState.ACTION_SKIP_TO_PREVIOUS | PlaybackState.ACTION_PLAY_PAUSE;
        mediaSession.setPlaybackState(new PlaybackState.Builder()
                .setActions(actions)
                .setState(playing ? PlaybackState.STATE_PLAYING : PlaybackState.STATE_PAUSED,
                        PlaybackState.PLAYBACK_POSITION_UNKNOWN,
                        playing ? 1.0f : 0.0f)
                .build());
        mediaSession.setMetadata(new MediaMetadata.Builder()
                .putString(MediaMetadata.METADATA_KEY_TITLE, station)
                .putString(MediaMetadata.METADATA_KEY_ARTIST, track)
                .build());
        startForeground(NOTIFICATION_ID, buildNotification());
    }

    private Notification buildNotification() {
        PendingIntent content = PendingIntent.getActivity(this, 0,
                new Intent(this, FreeRadioActivity.class)
                        .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        Notification.Builder builder = Build.VERSION.SDK_INT >= 26
                ? new Notification.Builder(this, CHANNEL_ID)
                : new Notification.Builder(this);
        builder.setSmallIcon(R.drawable.ic_notification)
                .setContentTitle(station)
                .setContentText(track.isEmpty() ? "Free Radio" : track)
                .setContentIntent(content)
                .setOnlyAlertOnce(true)
                .setOngoing(playing)
                .setCategory(Notification.CATEGORY_TRANSPORT)
                .setVisibility(Notification.VISIBILITY_PUBLIC)
                .addAction(R.drawable.ic_previous, "Previous", action(ACTION_PREVIOUS, 1))
                .addAction(playing ? R.drawable.ic_pause : R.drawable.ic_play,
                        playing ? "Pause" : "Play",
                        action(playing ? ACTION_PAUSE : ACTION_PLAY, 2))
                .addAction(R.drawable.ic_next, "Next", action(ACTION_NEXT, 3))
                .addAction(R.drawable.ic_stop, "Stop", action(ACTION_STOP, 4))
                .setStyle(new Notification.MediaStyle()
                        .setMediaSession(mediaSession.getSessionToken())
                        .setShowActionsInCompactView(0, 1, 2));
        return builder.build();
    }

    private PendingIntent action(String action, int requestCode) {
        Intent intent = new Intent(this, PlaybackService.class).setAction(action);
        return PendingIntent.getService(this, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationChannel channel = new NotificationChannel(CHANNEL_ID,
                    "Radio playback", NotificationManager.IMPORTANCE_LOW);
            channel.setDescription("Playback controls for Free Radio");
            channel.setShowBadge(false);
            getSystemService(NotificationManager.class).createNotificationChannel(channel);
        }
    }

    private void stopPlaybackService() {
        abandonAudioFocus();
        stopForeground(true);
        stopSelf();
    }

    @Override
    public void onDestroy() {
        abandonAudioFocus();
        if (noisyReceiverRegistered) {
            unregisterReceiver(noisyReceiver);
            noisyReceiverRegistered = false;
        }
        if (mediaSession != null) {
            mediaSession.release();
            mediaSession = null;
        }
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private static String nonEmpty(String value, String fallback) {
        return value == null || value.trim().isEmpty() ? fallback : value;
    }
}
