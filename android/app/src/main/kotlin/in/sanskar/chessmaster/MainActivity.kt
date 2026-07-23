package in.sanskar.chessmaster

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ENGINE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "engineEnvironment" -> {
                    result.success(
                        mapOf(
                            "supportedAbis" to Build.SUPPORTED_ABIS.toList(),
                            "verifiedBinaryPath" to null,
                            "verifiedAbi" to null,
                            "sourceVersion" to null,
                            "sha256" to null,
                            "distributionVerified" to false,
                        ),
                    )
                }

                else -> result.notImplemented()
            }
        }
    }

    private companion object {
        const val ENGINE_CHANNEL = "in.sanskar.chessmaster/engine"
    }
}
