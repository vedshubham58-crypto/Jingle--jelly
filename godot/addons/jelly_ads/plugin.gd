@tool
extends EditorPlugin
## Adds the kid-safe AdMob plugin (built from android-ads-plugin/ by CI) to Android exports.

## Google's test app id. Swap in the real AdMob app id before launch.
const ADMOB_APP_ID := "ca-app-pub-3940256099942544~3347511713"

var _export: EditorExportPlugin


func _enter_tree() -> void:
	_export = JellyAdsExport.new()
	add_export_plugin(_export)


func _exit_tree() -> void:
	remove_export_plugin(_export)
	_export = null


class JellyAdsExport extends EditorExportPlugin:
	func _get_name() -> String:
		return "JellyAds"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray(["jelly_ads/bin/jelly-ads-release.aar"])

	func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray(["com.google.android.gms:play-services-ads:23.6.0"])

	# Kids apps must not use the advertising ID, which the ads library would add.
	func _get_android_manifest_element_contents(platform: EditorExportPlatform, debug: bool) -> String:
		return '<uses-permission android:name="com.google.android.gms.permission.AD_ID" tools:node="remove"/>'

	func _get_android_manifest_application_element_contents(platform: EditorExportPlatform, debug: bool) -> String:
		return '<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="%s"/>' % ADMOB_APP_ID
