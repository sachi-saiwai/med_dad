package jp.sachikosaga.medlicense

import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.ParcelFileDescriptor
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "jp.sachikosaga.medlicense/ocr"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "recognize") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                val contentType = call.argument<String>("contentType") ?: ""
                if (path.isNullOrBlank()) {
                    result.error("invalid_path", "読み取り対象のファイルがありません。", null)
                    return@setMethodCallHandler
                }
                if (contentType.contains("pdf", ignoreCase = true) || path.endsWith(".pdf", ignoreCase = true)) {
                    recognizePdf(path, result)
                } else {
                    recognizeImage(path, result)
                }
            }
    }

    private fun recognizer() = TextRecognition.getClient(
        JapaneseTextRecognizerOptions.Builder().build(),
    )

    private fun recognizeImage(path: String, result: MethodChannel.Result) {
        val recognizer = recognizer()
        try {
            val image = InputImage.fromFilePath(this, Uri.fromFile(File(path)))
            recognizer.process(image)
                .addOnSuccessListener { recognized ->
                    recognizer.close()
                    result.success(
                        mapOf(
                            "text" to recognized.text,
                            "engine" to "google-mlkit-japanese",
                            "blockCount" to recognized.textBlocks.size,
                        ),
                    )
                }
                .addOnFailureListener { error ->
                    recognizer.close()
                    result.error("ocr_failed", error.localizedMessage ?: "文字を読み取れませんでした。", null)
                }
        } catch (error: Exception) {
            recognizer.close()
            result.error("ocr_failed", error.localizedMessage ?: "画像を開けませんでした。", null)
        }
    }

    private fun recognizePdf(path: String, result: MethodChannel.Result) {
        val descriptor: ParcelFileDescriptor
        val renderer: PdfRenderer
        try {
            descriptor = ParcelFileDescriptor.open(File(path), ParcelFileDescriptor.MODE_READ_ONLY)
            renderer = PdfRenderer(descriptor)
        } catch (error: Exception) {
            result.error("pdf_open_failed", error.localizedMessage ?: "PDFを開けませんでした。", null)
            return
        }
        val recognizer = recognizer()
        val texts = mutableListOf<String>()
        var blockCount = 0
        val pageLimit = minOf(renderer.pageCount, 5)

        fun finish(error: Exception? = null) {
            recognizer.close()
            renderer.close()
            descriptor.close()
            if (error != null) {
                result.error("ocr_failed", error.localizedMessage ?: "PDFを読み取れませんでした。", null)
            } else {
                result.success(
                    mapOf(
                        "text" to texts.joinToString("\n\n"),
                        "engine" to "google-mlkit-japanese-pdf",
                        "blockCount" to blockCount,
                    ),
                )
            }
        }

        fun processPage(index: Int) {
            if (index >= pageLimit) {
                finish()
                return
            }
            try {
                renderer.openPage(index).use { page ->
                    val scale = minOf(2.0, 2200.0 / page.width.toDouble())
                    val width = maxOf(1, (page.width * scale).toInt())
                    val height = maxOf(1, (page.height * scale).toInt())
                    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                    recognizer.process(InputImage.fromBitmap(bitmap, 0))
                        .addOnSuccessListener { recognized ->
                            texts.add(recognized.text)
                            blockCount += recognized.textBlocks.size
                            bitmap.recycle()
                            processPage(index + 1)
                        }
                        .addOnFailureListener { error ->
                            bitmap.recycle()
                            finish(error)
                        }
                }
            } catch (error: Exception) {
                finish(error)
            }
        }

        if (pageLimit == 0) finish() else processPage(0)
    }
}
