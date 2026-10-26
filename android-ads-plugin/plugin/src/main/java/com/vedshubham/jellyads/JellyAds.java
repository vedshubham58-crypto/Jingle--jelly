package com.vedshubham.jellyads;

import android.app.Activity;

import androidx.annotation.NonNull;
import androidx.collection.ArraySet;

import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.RequestConfiguration;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.Set;

/**
 * Shows kid-safe AdMob interstitials. Every request is tagged child-directed
 * (COPPA) and under the age of consent, with a G content rating, as Google
 * Play's Families policy requires, so ads are never personalised.
 * GDScript calls start(), then showInterstitial(), and hears back through the
 * interstitial_closed signal.
 */
public class JellyAds extends GodotPlugin {
    private volatile InterstitialAd interstitial;
    private String interstitialId = "";
    private boolean loading;

    public JellyAds(Godot godot) {
        super(godot);
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "JellyAds";
    }

    @NonNull
    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new ArraySet<>();
        signals.add(new SignalInfo("interstitial_closed"));
        return signals;
    }

    @UsedByGodot
    public void start(String interstitialUnit) {
        interstitialId = interstitialUnit;
        Activity activity = getActivity();
        if (activity == null) return;
        activity.runOnUiThread(() -> {
            // Must be set before the first ad request.
            MobileAds.setRequestConfiguration(new RequestConfiguration.Builder()
                    .setTagForChildDirectedTreatment(RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_TRUE)
                    .setTagForUnderAgeOfConsent(RequestConfiguration.TAG_FOR_UNDER_AGE_OF_CONSENT_TRUE)
                    .setMaxAdContentRating(RequestConfiguration.MAX_AD_CONTENT_RATING_G)
                    .build());
            MobileAds.initialize(activity, status -> { });
            load();
        });
    }

    @UsedByGodot
    public boolean isInterstitialReady() {
        return interstitial != null;
    }

    /** Returns false (and asks for a new ad) if none is loaded yet. */
    @UsedByGodot
    public boolean showInterstitial() {
        Activity activity = getActivity();
        InterstitialAd ad = interstitial;
        if (activity == null || ad == null) {
            if (activity != null) activity.runOnUiThread(this::load);
            return false;
        }
        interstitial = null;
        activity.runOnUiThread(() -> {
            ad.setFullScreenContentCallback(new FullScreenContentCallback() {
                @Override
                public void onAdDismissedFullScreenContent() {
                    send("interstitial_closed");
                    load();
                }

                @Override
                public void onAdFailedToShowFullScreenContent(@NonNull AdError error) {
                    send("interstitial_closed");
                    load();
                }
            });
            ad.show(activity);
        });
        return true;
    }

    private void send(String signal, Object... args) {
        runOnRenderThread(() -> emitSignal(signal, args));
    }

    private void load() {
        Activity activity = getActivity();
        if (activity == null || interstitialId.isEmpty() || interstitial != null || loading) return;
        loading = true;
        InterstitialAd.load(activity, interstitialId, new AdRequest.Builder().build(), new InterstitialAdLoadCallback() {
            @Override
            public void onAdLoaded(@NonNull InterstitialAd ad) {
                interstitial = ad;
                loading = false;
            }

            @Override
            public void onAdFailedToLoad(@NonNull LoadAdError error) {
                loading = false;
            }
        });
    }
}
