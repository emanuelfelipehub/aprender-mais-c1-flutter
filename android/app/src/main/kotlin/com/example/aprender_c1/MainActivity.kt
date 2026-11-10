package com.example.aprender_c1

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "aprender_c1/device"
    private val prefs by lazy { getSharedPreferences("c1_settings", MODE_PRIVATE) }
    private val recordings by lazy { File(filesDir, "recordings").apply { mkdirs() } }
    private var recorder: MediaRecorder? = null
    private var recordingFile: File? = null
    private var player: MediaPlayer? = null
    private var playingPath: String? = null
    private var pendingRecord: MethodChannel.Result? = null
    private var pendingPhoto: MethodChannel.Result? = null
    private var pendingBrightnessPermission: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "firstLaunch" -> {
                        val first = !prefs.getBoolean("launched", false)
                        prefs.edit().putBoolean("launched", true).apply()
                        result.success(first)
                    }
                    "getBool" -> result.success(prefs.getBoolean(call.argument<String>("key") ?: "", false))
                    "setBool" -> {
                        prefs.edit().putBoolean(call.argument<String>("key") ?: "", call.argument<Boolean>("value") ?: false).apply()
                        result.success(null)
                    }
                    "getAvatar" -> result.success(prefs.getString("avatar", null))
                    "recordings" -> result.success(listRecordings())
                    "recordStart" -> startRecording(result)
                    "recordStop" -> result.success(stopRecording())
                    "recordDelete" -> {
                        val file = checkedRecording(call.argument<String>("path"))
                        if (playingPath == file.absolutePath) stopPlayback()
                        result.success(file.exists() && file.delete())
                    }
                    "recordPlay" -> {
                        val file = checkedRecording(call.argument<String>("path"))
                        stopPlayback()
                        playingPath = file.absolutePath
                        val media = MediaPlayer()
                        player = media
                        try {
                            media.setDataSource(file.absolutePath)
                            media.prepare()
                            media.setOnCompletionListener { stopPlayback() }
                            media.start()
                        } catch (e: Exception) {
                            stopPlayback()
                            throw e
                        }
                        result.success(null)
                    }
                    "recordIsPlaying" -> result.success(player?.isPlaying == true)
                    "recordStopPlayback" -> { stopPlayback(); result.success(null) }
                    "chooseAvatar" -> chooseAvatar(call.argument<String>("source") ?: "gallery", result)
                    "getBrightness" -> {
                        val raw = Settings.System.getInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS, 180)
                        result.success((raw / 255.0).coerceIn(0.01, 1.0))
                    }
                    "canWriteBrightness" -> result.success(Settings.System.canWrite(this))
                    "requestBrightnessPermission" -> requestBrightnessPermission(result)
                    "brightness" -> {
                        val value = (call.argument<Double>("value") ?: 0.5).coerceIn(0.01, 1.0)
                        var global = false
                        if (Settings.System.canWrite(this)) {
                            try {
                                Settings.System.putInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS_MODE, Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL)
                                global = Settings.System.putInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS, (value * 255).toInt().coerceIn(1, 255))
                            } catch (_: SecurityException) { global = false }
                        }
                        window.attributes = window.attributes.apply {
                            screenBrightness = if (global) -1f else value.toFloat()
                        }
                        result.success(global)
                    }
                    "toast" -> {
                        Toast.makeText(this, call.argument<String>("text") ?: "", Toast.LENGTH_SHORT).show()
                        result.success(null)
                    }
                    "share" -> {
                        val send = Intent(Intent.ACTION_SEND).setType("text/plain")
                            .putExtra(Intent.EXTRA_TEXT, call.argument<String>("text") ?: "")
                        startActivity(Intent.createChooser(send, "Compartilhar"))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("DEVICE_ERROR", e.localizedMessage ?: "Falha no recurso do aparelho", null)
            }
        }
    }

    private fun listRecordings(): List<Map<String, Any>> = recordings.listFiles()
        ?.filter { it.isFile && it.extension == "m4a" }
        ?.sortedByDescending { it.lastModified() }
        ?.map { mapOf("path" to it.absolutePath, "date" to it.lastModified()) } ?: emptyList()

    private fun checkedRecording(path: String?): File {
        require(!path.isNullOrBlank()) { "Gravação não informada" }
        val file = File(path).canonicalFile
        require(file.parentFile == recordings.canonicalFile && file.extension == "m4a") { "Arquivo inválido" }
        return file
    }

    private fun startRecording(result: MethodChannel.Result) {
        if (recorder != null) { result.error("RECORDING", "Já existe uma gravação", null); return }
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            if (pendingRecord != null) { result.error("PERMISSION", "Permissão pendente", null); return }
            pendingRecord = result
            requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), 701)
            return
        }
        startRecordingNow(result)
    }

    @Suppress("DEPRECATION")
    private fun startRecordingNow(result: MethodChannel.Result) {
        try {
            val file = File(recordings, "resumo_${System.currentTimeMillis()}.m4a")
            val media = if (Build.VERSION.SDK_INT >= 31) MediaRecorder(this) else MediaRecorder()
            recorder = media
            recordingFile = file
            media.setAudioSource(MediaRecorder.AudioSource.MIC)
            media.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            media.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            media.setAudioEncodingBitRate(128000)
            media.setAudioSamplingRate(44100)
            media.setOutputFile(file.absolutePath)
            media.prepare()
            media.start()
            result.success(null)
        } catch (e: Exception) {
            recorder?.release(); recorder = null
            recordingFile?.delete(); recordingFile = null
            result.error("RECORD_ERROR", e.localizedMessage ?: "Não foi possível gravar", null)
        }
    }

    private fun stopRecording(): String? {
        val current = recorder ?: return null
        val file = recordingFile
        try { current.stop() } catch (_: RuntimeException) { file?.delete() }
        current.release()
        recorder = null
        recordingFile = null
        return file?.takeIf { it.exists() && it.length() > 0 }?.absolutePath
    }

    private fun stopPlayback() {
        val current = player
        player = null
        playingPath = null
        try { current?.stop() } catch (_: Exception) {}
        current?.release()
    }

    private fun chooseAvatar(source: String, result: MethodChannel.Result) {
        if (pendingPhoto != null) { result.error("PHOTO", "Seleção em andamento", null); return }
        pendingPhoto = result
        val intent = if (source == "camera") Intent(MediaStore.ACTION_IMAGE_CAPTURE)
                     else Intent(Intent.ACTION_GET_CONTENT).setType("image/*").addCategory(Intent.CATEGORY_OPENABLE)
        try { startActivityForResult(intent, if (source == "camera") 702 else 703) }
        catch (e: Exception) { pendingPhoto = null; result.error("PHOTO", e.localizedMessage, null) }
    }

    private fun requestBrightnessPermission(result: MethodChannel.Result) {
        if (Settings.System.canWrite(this)) { result.success(true); return }
        if (pendingBrightnessPermission != null) { result.error("PERMISSION", "Permissão pendente", null); return }
        pendingBrightnessPermission = result
        try {
            val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS, Uri.parse("package:$packageName"))
            startActivityForResult(intent, 704)
        } catch (e: Exception) {
            pendingBrightnessPermission = null
            result.error("PERMISSION", e.localizedMessage ?: "Não foi possível abrir as configurações", null)
        }
    }

    @Deprecated("Uses Android activity results for compatibility with the exam emulator")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 704) {
            val pending = pendingBrightnessPermission
            pendingBrightnessPermission = null
            pending?.success(Settings.System.canWrite(this))
            return
        }
        if (requestCode != 702 && requestCode != 703) return
        val pending = pendingPhoto ?: return
        pendingPhoto = null
        if (resultCode != Activity.RESULT_OK || data == null) { pending.success(null); return }
        try {
            val file = File(filesDir, "avatar_${System.currentTimeMillis()}.png")
            if (requestCode == 702) {
                @Suppress("DEPRECATION")
                val bitmap = data.extras?.get("data") as? Bitmap ?: throw IllegalStateException("Câmera não retornou imagem")
                FileOutputStream(file).use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
            } else {
                val uri = data.data ?: throw IllegalStateException("Nenhuma imagem selecionada")
                contentResolver.openInputStream(uri)?.use { input -> file.outputStream().use { input.copyTo(it) } }
                    ?: throw IllegalStateException("Não foi possível ler a imagem")
            }
            prefs.edit().putString("avatar", file.absolutePath).apply()
            pending.success(file.absolutePath)
        } catch (e: Exception) { pending.error("PHOTO", e.localizedMessage, null) }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 701) {
            val pending = pendingRecord ?: return
            pendingRecord = null
            if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) startRecordingNow(pending)
            else pending.error("PERMISSION", "Permissão de microfone negada", null)
        }
    }

    override fun onDestroy() {
        try { stopRecording() } catch (_: Exception) {}
        stopPlayback()
        super.onDestroy()
    }
}
